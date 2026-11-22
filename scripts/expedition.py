#!/usr/bin/env python3
"""
The Expedition engine: turns pushes into progress.

For players
  python3 scripts/expedition.py join <Name>        create your player folder (once)
  python3 scripts/expedition.py status             check your proofs right now (changes nothing on GitHub)
  python3 scripts/expedition.py hint <puzzle>      reveal the next hint for a puzzle (e.g. `hint t4`)
  python3 scripts/expedition.py hint               list your open puzzles
  python3 scripts/expedition.py detour <QuestID>   spend a detour token: open a locked quest now
  python3 scripts/expedition.py guide [interests]  what each quest focuses on, ranked for you
                                                   (e.g. `guide safety,code`; no argument uses your intake)
  python3 scripts/expedition.py leave <Name> --yes remove a player (e.g. a test player)

For the Game Master and GitHub Actions
  python3 scripts/expedition.py report             JSON: progress, signals and recent trail for every player
  python3 scripts/expedition.py update             check proofs, unlock quests, log the trail, redraw maps
                                                   (GitHub Actions runs this after every push)
Options
  --as <Name>   act as this player (default: the name saved by `join` in .player)
  --all         `status` for every player
  --no-lean     count `sorry`s in the text instead of compiling (fast but NOT verified)
  --force       allow `update` to run outside GitHub Actions
  --write       `guide`: regenerate docs/QUEST_GUIDE.md from expedition/quests.json

How progress is measured: every `sorry` in a quest template is one puzzle. Lean
compiles your copy; each "declaration uses sorry" warning is an unsolved puzzle,
and any error means the file needs fixing. Routes (which quests you see, in what
order, what opens early, custom quests) come from Players/<you>/route.json,
which the Game Master writes.
"""
from __future__ import annotations

import argparse
import hashlib
import html
import json
import os
import re
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
QUESTS_DIR = ROOT / "Quests"
PLAYERS_DIR = ROOT / "Players"
TEMPLATE_DIR = PLAYERS_DIR / "_template"
CUSTOM_DIR = ROOT / "expedition" / "custom"
COMPANION_DIR = ROOT / "assets" / "companions"
META_FILE = ROOT / "expedition" / "quests.json"
STATE_FILE = ROOT / "expedition" / "state.json"
HISTORY_FILE = ROOT / "expedition" / "history.jsonl"
PLAYER_FILE = ROOT / ".player"
SEEN_CARDS_FILE = ROOT / ".seen_cards"
README = ROOT / "README.md"
QUEST_GUIDE = ROOT / "docs" / "QUEST_GUIDE.md"
MARK_START, MARK_END = "<!-- EXPEDITION:START -->", "<!-- EXPEDITION:END -->"
GUIDE_START, GUIDE_END = "<!-- RATINGS:START -->", "<!-- RATINGS:END -->"
ENGINE_VERSION = 2
BOT_NAME = "expedition-bot"
PLACEHOLDER = "_answer here_"
DEFAULT_UNLOCK_AT = 0.6
CLEAR_BONUS = 0.2
STALL_HOURS = 48
NAME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9_-]{0,23}$")

# ───────────────────────────── Lean text helpers ─────────────────────────────


def strip_comments(text: str) -> str:
    """Blank out Lean comments (`-- ...` and nested `/- ... -/`), keeping offsets and newlines."""
    out: list[str] = []
    i, n, depth = 0, len(text), 0
    while i < n:
        if depth == 0:
            if text.startswith("--", i):
                j = text.find("\n", i)
                j = n if j == -1 else j
                out.append(" " * (j - i))
                i = j
            elif text.startswith("/-", i):
                depth, i = 1, i + 2
                out.append("  ")
            elif text[i] == '"':
                j = i + 1
                while j < n and text[j] != '"':
                    j += 2 if text[j] == "\\" else 1
                j = min(j + 1, n)
                out.append(text[i:j])
                i = j
            else:
                out.append(text[i])
                i += 1
        else:
            if text.startswith("/-", i):
                depth, i = depth + 1, i + 2
                out.append("  ")
            elif text.startswith("-/", i):
                depth, i = depth - 1, i + 2
                out.append("  ")
            else:
                out.append("\n" if text[i] == "\n" else " ")
                i += 1
    return "".join(out)


SORRY_RE = re.compile(r"(?<![\w.'])sorry(?![\w'])")
THEOREM_RE = re.compile(r"^\s*(?:@\[[^\]]*\]\s*)?(?:private\s+|protected\s+)?(?:theorem|lemma)\s+([^\s:({\[]+)", re.M)
DECL_RE = re.compile(r"^[ \t]*(?:@\[[^\]]*\][ \t]*)?(?:private[ \t]+|protected[ \t]+|noncomputable[ \t]+)*"
                     r"(?:theorem|lemma|def|abbrev|instance|example)\b[ \t]*([^\s:({\[]*)", re.M)
ERROR_RE = re.compile(r":\d+:\d+: error|^error:", re.M)
SORRY_WARN_RE = re.compile(r":(\d+):\d+: warning: declaration uses .sorry.")
HINT_NAME_RE = re.compile(r"^\s*(?:##\s+|@)([^\s]+)\s*$")
HINT_LEVEL_RE = re.compile(r"^\s*(\d+)\.\s+(.*)$")


def count_sorries(text: str) -> int:
    return len(SORRY_RE.findall(strip_comments(text)))


def theorem_names(text: str) -> list[str]:
    return THEOREM_RE.findall(strip_comments(text))


def decl_starts(text: str) -> list[tuple[int, str]]:
    """(1-based line, name) of every declaration, in order."""
    code = strip_comments(text)
    return [(code.count("\n", 0, m.start()) + 1, m.group(1) or "example") for m in DECL_RE.finditer(code)]


def owner_names(text: str, lines: list[int]) -> list[str]:
    """Map line numbers to the declaration that contains them."""
    starts = decl_starts(text)
    out = []
    for ln in lines:
        owners = [name for start, name in starts if start <= ln]
        if owners and owners[-1] not in out:
            out.append(owners[-1])
    return out


def sorry_lines_in_text(text: str) -> list[int]:
    code = strip_comments(text)
    return [code.count("\n", 0, m.start()) + 1 for m in SORRY_RE.finditer(code)]


def parse_hints(text: str) -> dict[str, list[str]]:
    """A hint file (Quests/hints/<ID>.md): `## puzzle` headings, each with numbered levels `1. ...`."""
    hints: dict[str, list[str]] = {}
    current: str | None = None
    for line in text.splitlines():
        m = HINT_NAME_RE.match(line)
        if m:
            current = m.group(1)
            hints[current] = []
            continue
        if current is None or not line.strip() or line.lstrip().startswith("#"):
            continue
        m = HINT_LEVEL_RE.match(line)
        if m:
            hints[current].append(m.group(2).strip())
        elif hints[current]:
            hints[current][-1] += "\n" + line.rstrip()
    return {k: v for k, v in hints.items() if v}


def sha(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


def read(p: Path) -> str:
    return p.read_text(encoding="utf-8") if p.exists() else ""


def read_json(p: Path, default):
    try:
        return json.loads(read(p)) if p.exists() else default
    except json.JSONDecodeError as e:
        print(f"⚠️  {p.relative_to(ROOT)} is not valid JSON ({e}); ignoring it.", file=sys.stderr)
        return default


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def parse_time(t: str | None) -> datetime | None:
    if not t:
        return None
    try:
        dt = datetime.fromisoformat(t.replace("Z", "+00:00"))
        return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
    except ValueError:
        return None


# ───────────────────────────── compiling ─────────────────────────────


def find_lake() -> str | None:
    found = shutil.which("lake")
    if found:
        return found
    candidate = Path.home() / ".elan" / "bin" / "lake"
    return str(candidate) if candidate.exists() else None


def toolchain() -> str:
    return read(ROOT / "lean-toolchain").strip()


def compile_lean(path: Path, lake: str | None, text_only: bool, timeout: int = 900) -> dict:
    text = read(path)
    if text_only or lake is None:
        lines = sorry_lines_in_text(text)
        return {"errors": 0, "sorries": len(lines), "sorry_lines": lines, "messages": [], "verified": False}
    try:
        proc = subprocess.run([lake, "env", "lean", str(path)], cwd=ROOT, capture_output=True,
                              text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return {"errors": 1, "sorries": 0, "sorry_lines": [], "messages": ["Lean timed out on this file."],
                "verified": True}
    output = (proc.stdout or "") + (proc.stderr or "")
    output = output.replace(str(ROOT) + os.sep, "")
    error_lines = [ln for ln in output.splitlines() if ERROR_RE.search(ln)]
    if proc.returncode != 0 and not error_lines:
        error_lines = ["Lean exited with an error: " + output.strip()[:300]]
    sorry_lines = [int(m.group(1)) for m in SORRY_WARN_RE.finditer(output)]
    return {
        "errors": len(error_lines),
        "sorries": len(sorry_lines),
        "sorry_lines": sorry_lines,
        "messages": [ln.strip()[:240] for ln in error_lines[:6]],
        "verified": True,
    }


# ───────────────────────────── data model ─────────────────────────────


@dataclass
class Quest:
    id: str
    title: str
    kind: str              # lean | intake | project
    track: str
    xp: int
    minutes: str
    blurb: str
    requires: list[str]
    requires_any: list[str]
    unlock_at: float
    template: Path
    dest: Path
    done_when: str | None = None
    custom: bool = False
    hidden: bool = False
    hints: Path | None = None
    card: Path | None = None
    ratings: dict[str, int] = field(default_factory=dict)     # criterion id -> 0..3
    features: dict[str, str] = field(default_factory=dict)    # feature id -> "yes" | "optional"
    difficulty: int | None = None                             # 1..3
    companion: dict = field(default_factory=dict)             # name, animal, emoji, says
    art: Path | None = None                                   # the companion's animated SVG


@dataclass
class Result:
    status: str            # locked | open | new | progress | cleared | broken | tampered
    solved: int = 0
    total: int = 0
    xp: int = 0
    messages: list[str] = field(default_factory=list)
    missing: list[str] = field(default_factory=list)
    open: list[str] = field(default_factory=list)   # names of unsolved puzzles
    unlocked_now: bool = False

    @property
    def fraction(self) -> float:
        if self.status == "cleared":
            return 1.0
        return (self.solved / self.total) if self.total else 0.0


STATUS_EMOJI = {"locked": "🔒", "open": "🆕", "new": "🆕", "progress": "🛠️", "cleared": "✅",
                "broken": "💥", "tampered": "⚠️"}
EVENT_EMOJI = {"joined": "🐣", "unlocked": "🔓", "detour": "🎟️", "update": "🛠️", "cleared": "✅",
               "broke": "💥", "fixed": "🔧", "hint": "💡", "left": "👋", "interests": "🎯"}


def load_meta() -> dict:
    return json.loads(read(META_FILE))


def load_route(player: str) -> dict:
    return read_json(PLAYERS_DIR / player / "route.json", {})


def load_hints_used(player: str) -> dict:
    return read_json(PLAYERS_DIR / player / "hints.json", {})


def load_detours(player: str) -> list[dict]:
    return read_json(PLAYERS_DIR / player / "detours.json", {}).get("used", [])


def detour_allowance(meta: dict, route: dict) -> int:
    return int(meta.get("detour_tokens", 2)) + int(route.get("extra_detours", 0))


def discover_players() -> list[str]:
    if not PLAYERS_DIR.exists():
        return []
    return sorted(d.name for d in PLAYERS_DIR.iterdir()
                  if d.is_dir() and not d.name.startswith(("_", ".")) and (d / "intake.md").exists())


def quests_for(player: str, meta: dict, route: dict) -> list[Quest]:
    pdir = PLAYERS_DIR / player
    hidden = set(route.get("hide", []))
    overrides = route.get("requires", {})
    out: list[Quest] = []
    entries = [(e, False) for e in meta["quests"]] + [(e, True) for e in route.get("custom", [])]
    for e, custom in entries:
        kind = e.get("kind", "lean")
        art = COMPANION_DIR / f"{e['id']}.svg"
        if kind == "intake":
            template, dest, hints, card = TEMPLATE_DIR / e["file"], pdir / e["file"], None, None
        elif custom:
            template, dest = CUSTOM_DIR / player / e["file"], pdir / "quests" / e["file"]
            hints = CUSTOM_DIR / player / "hints" / f"{e['id']}.md"
            card = CUSTOM_DIR / player / "cards" / f"{e['id']}.md"
            art = CUSTOM_DIR / player / "companions" / f"{e['id']}.svg"
        else:
            template, dest = QUESTS_DIR / e["file"], pdir / "quests" / e["file"]
            hints = QUESTS_DIR / "hints" / f"{e['id']}.md"
            card = QUESTS_DIR / "cards" / f"{e['id']}.md"
        out.append(Quest(
            id=e["id"], title=e["title"], kind=kind, track="custom" if custom else e.get("track", "core"),
            xp=int(e.get("xp", 50)), minutes=str(e.get("minutes", "")), blurb=e.get("blurb", ""),
            requires=list(overrides.get(e["id"], e.get("requires", []))),
            requires_any=list(e.get("requires_any", [])),
            unlock_at=float(e.get("unlock_at", 1.0 if kind == "intake" else DEFAULT_UNLOCK_AT)),
            template=template, dest=dest, done_when=e.get("done_when"), custom=custom,
            hidden=e["id"] in hidden, hints=hints, card=card,
            ratings={k: int(v) for k, v in e.get("ratings", {}).items() if int(v) > 0},
            features={k: str(v) for k, v in e.get("features", {}).items() if v},
            difficulty=e.get("difficulty"),
            companion=dict(e.get("companion", {})), art=art if art.exists() else None,
        ))
    return out


# ───────────────────────────── ratings and interests ─────────────────────────────

DOTS = {0: "·", 1: "●○○", 2: "●●○", 3: "●●●"}
STARS = {1: "★☆☆", 2: "★★☆", 3: "★★★"}
INTEREST_RE = re.compile(r"\*\*My interest[^*]*\*\*(.*)")


def criteria(meta: dict) -> list[dict]:
    return meta.get("rating_criteria", [])


def _plain(s: str) -> str:
    return s.replace("\ufe0f", "").strip().lower()


def chips(q: Quest, meta: dict, limit: int = 3, with_features: bool = True, min_level: int = 2) -> str:
    """Compact focus labels such as `💻●●● 🤖●●○ ⌨️`: the quest's biggest regions, then its features."""
    order = [c["id"] for c in criteria(meta)]
    emoji = {c["id"]: c["emoji"] for c in criteria(meta)}
    ranked = sorted((k for k in q.ratings if k in emoji), key=lambda k: (-q.ratings[k], order.index(k)))
    strong = [k for k in ranked if q.ratings[k] >= min_level] or ranked[:1]
    parts = [emoji[k] + DOTS[min(3, q.ratings[k])] for k in strong[:limit]]
    if with_features:
        feats = {f["id"]: f["emoji"] for f in meta.get("rating_features", [])}
        parts += [feats[k] + ("?" if v == "optional" else "") for k, v in q.features.items() if k in feats]
    return " ".join(parts)


def parse_interests(text: str, meta: dict) -> dict[str, int]:
    """Interest ratings (0-3) from the intake's field tour: a `### <emoji> <region>` heading, then a
    `**My interest (0–3):** N` line."""
    out: dict[str, int] = {}
    current = None
    for line in text.splitlines():
        if line.startswith("### "):
            head = _plain(line)
            current = next((c["id"] for c in criteria(meta)
                            if _plain(c["emoji"]) in head or c["name"].lower() in head), None)
            continue
        m = INTEREST_RE.search(line)
        if m and current:
            d = re.search(r"[0-3]", m.group(1).replace(PLACEHOLDER, ""))
            if d:
                out[current] = int(d.group())
    return out


def ratings_mix(quests: list[Quest], results: dict) -> dict[str, float]:
    """What the player's solved puzzles practiced: each quest's ratings, weighted by how much of it is solved."""
    tot: dict[str, float] = {}
    for q in quests:
        f = results[q.id].fraction
        for k, v in q.ratings.items():
            tot[k] = tot.get(k, 0.0) + f * v
    s = sum(tot.values())
    return {k: round(v / s, 3) for k, v in tot.items() if v > 0} if s else {}


def interest_score(q: Quest, interests: dict[str, int]) -> float:
    """How well a quest's focus lines up with the player's interests (cosine-style, so a focused quest that
    matches your top interests beats a broad quest that touches everything)."""
    dot = sum(interests.get(k, 0) * v for k, v in q.ratings.items())
    norm = sum(v * v for v in q.ratings.values()) ** 0.5
    return dot / norm if norm else 0.0


def format_interests(interests: dict[str, int], meta: dict) -> str:
    return " · ".join(f"{c['emoji']} {interests[c['id']]}" for c in criteria(meta) if c["id"] in interests)


ALIASES = {"statistics": "stats", "probability": "stats", "software": "code", "policy": "code", "policies": "code",
           "specs": "checking_ai", "ai": "checking_ai", "review": "checking_ai", "agents": "safety",
           "security": "safety", "privacy": "safety", "robustness": "safety", "evaluation": "eval",
           "benchmarks": "eval", "audit": "trust", "auditing": "trust"}


def match_criterion(word: str, meta: dict) -> str | None:
    w = _plain(word)
    for c in criteria(meta):
        if w in (c["id"], _plain(c["emoji"])) or c["name"].lower().startswith(w):
            return c["id"]
    return ALIASES.get(w)


def render_quest_guide(meta: dict) -> str:
    """The generated part of docs/QUEST_GUIDE.md: the ratings table and pick-by-interest lists."""
    crit, feats, tracks = criteria(meta), meta.get("rating_features", []), meta.get("tracks", {})
    quests = [e for e in meta["quests"] if e.get("kind", "lean") != "intake"]
    lines = ["## Every quest, rated", "",
             "_Generated from `expedition/quests.json`. Ratings are approximate: · none, ●○○ a touch, ●●○ a big part, "
             "●●● the main focus. ✓ = yes, ◐ = optional. Difficulty ★☆☆ gentle, ★★☆ steady, ★★★ stretch._", "",
             "| Quest | ⏱ min | " + " | ".join(c["emoji"] for c in crit) + " | "
             + " | ".join(f["emoji"] for f in feats) + " | Difficulty | Opens after |",
             "|---|---|" + ":---:|" * (len(crit) + len(feats) + 1) + "---|"]
    for e in quests:
        r, f = e.get("ratings", {}), e.get("features", {})
        cells = [DOTS[min(3, int(r.get(c["id"], 0)))] for c in crit]
        cells += ["✓" if f.get(x["id"]) == "yes" else "◐" if f.get(x["id"]) == "optional" else "" for x in feats]
        req, any_ = e.get("requires", []), e.get("requires_any", [])
        opens = ", ".join(req)
        if any_:
            opens += (" + " if req else "") + "one of " + ", ".join(any_)
        lines.append(f"| **{e['id']}** · {e['title']}<br/><sub>{tracks.get(e.get('track', 'core'), '')}</sub> | "
                     f"{e.get('minutes', '')} | " + " | ".join(cells) +
                     f" | {STARS.get(e.get('difficulty'), '')} | {opens or 'start'} |")
    lines += ["", "<sub>" + " · ".join(f"{c['emoji']} {c['name']}" for c in crit) + " · "
              + " · ".join(f"{x['emoji']} {x['name']}" for x in feats) + "</sub>", "", "## Pick by interest", ""]
    for c in crit:
        main = [e["id"] for e in quests if e.get("ratings", {}).get(c["id"], 0) >= 3]
        big = [e["id"] for e in quests if e.get("ratings", {}).get(c["id"], 0) == 2]
        touch = [e["id"] for e in quests if e.get("ratings", {}).get(c["id"], 0) == 1]
        bits = [f"main focus: {', '.join(main)}" if main else "",
                f"a big part: {', '.join(big)}" if big else "",
                f"a touch: {', '.join(touch)}" if touch else ""]
        lines.append(f"- **{c['emoji']} {c['name']}.** " + "; ".join(b for b in bits if b) + ".")
    lines += ["", "## Pick by how you like to work", ""]
    for x in feats:
        yes = [e["id"] for e in quests if e.get("features", {}).get(x["id"]) == "yes"]
        opt = [e["id"] for e in quests if e.get("features", {}).get(x["id"]) == "optional"]
        lines.append(f"- **{x['emoji']} {x['name']}:** {', '.join(yes) or 'none yet'}"
                     + (f" (optional in {', '.join(opt)})" if opt else "") + ".")
    lines += ["", "In the terminal, `python3 scripts/expedition.py guide` ranks these for your interests, and "
              "`python3 scripts/expedition.py guide safety,code` ranks them for any mix you name."]
    return "\n".join(lines)


def format_mix(mix: dict[str, float], meta: dict) -> str:
    rows = sorted(((c, mix[c["id"]]) for c in criteria(meta) if mix.get(c["id"])), key=lambda x: -x[1])
    return " · ".join(f"{c['emoji']} {round(100 * v)}%" for c, v in rows)


# ───────────────────────────── companions (the menagerie) ─────────────────────────────

ANIMAL_WORDS = {"otter": "🦦", "penguin": "🐧", "fox": "🦊", "cat": "🐱", "dog": "🐶", "owl": "🦉", "panda": "🐼",
                "koala": "🐨", "bunny": "🐰", "rabbit": "🐰", "frog": "🐸", "octopus": "🐙", "sloth": "🦥",
                "hedgehog": "🦔", "turtle": "🐢", "whale": "🐳", "dolphin": "🐬", "tiger": "🐯", "lion": "🦁",
                "bear": "🐻", "unicorn": "🦄", "dragon": "🐉", "monkey": "🐵", "elephant": "🐘", "giraffe": "🦒",
                "horse": "🐴", "pig": "🐷", "cow": "🐮", "goat": "🐐", "sheep": "🐑", "duck": "🦆", "bee": "🐝",
                "butterfly": "🦋", "shark": "🦈", "seal": "🦭", "raccoon": "🦝", "hamster": "🐹", "mouse": "🐭",
                "wolf": "🐺", "parrot": "🦜", "flamingo": "🦩", "llama": "🦙", "alpaca": "🦙", "crab": "🦀"}


def companion_label(q: Quest) -> str:
    c = q.companion
    return f"{c.get('name', 'A mystery creature')} the {c.get('animal', 'creature')}" if c else ""


def companion_stage(q: Quest, r: Result) -> str:
    """egg (not started) → cracked (puzzles started) → hatched (quest cleared)."""
    if r.status == "cleared":
        return "hatched"
    if r.solved > 0 or r.status in ("progress", "broken", "tampered"):
        return "cracked"
    return "egg"


def companion_img(q: Quest, r: Result, width: int = 64, base: str = "../../") -> str:
    stage = companion_stage(q, r)
    c = q.companion
    if stage == "hatched":
        alt, tip = companion_label(q), f"{companion_label(q)} · {q.id} {q.title}: {c.get('says', '')}"
        if not q.art:
            return f'<span title="{html.escape(tip)}">{c.get("emoji", "🐣")}</span>'
        src = base + q.art.relative_to(ROOT).as_posix()
    elif stage == "cracked":
        alt, tip, src = "A hatching egg", f"Hatching… keep going on {q.id} · {q.title}", base + "assets/companions/_egg_cracked.svg"
    else:
        alt, tip, src = "A mystery egg", f"A mystery egg. Clear {q.id} · {q.title} to hatch it.", base + "assets/companions/_egg.svg"
    return (f'<img src="{src}" width="{width}" height="{width}" alt="{html.escape(alt)}" '
            f'title="{html.escape(tip)}">')


def parse_avatar(text: str) -> str:
    """The player's expedition animal: the first answer line after 'Pick your expedition animal' in the intake.
    An emoji is used as is; a common animal word (e.g. "otter") is turned into its emoji."""
    lines = text.splitlines()
    for i, line in enumerate(lines):
        if "expedition animal" not in line.lower():
            continue
        for nxt in lines[i + 1:i + 4]:
            s = nxt.strip()
            if not s:
                continue
            if s == PLACEHOLDER:
                return ""
            word = s.split()[0]
            if any(ord(ch) > 0x2000 for ch in word):
                return word[:12]
            w = word.lower().strip(".,!")
            return ANIMAL_WORDS.get(w) or ANIMAL_WORDS.get(w.rstrip("s"), "")
        return ""
    return ""


def hatched_quests(rep: "PlayerReport", history: list[dict] | None = None) -> list[Quest]:
    """Cleared quests with a companion, in the order they were cleared."""
    got = [q for q in rep.quests if q.companion and rep.results[q.id].status == "cleared"]
    when = {}
    for e in history or []:
        if e.get("player") == rep.name and e.get("event") == "cleared":
            when.setdefault(e.get("quest"), e.get("t", ""))
    order = {q.id: i for i, q in enumerate(rep.quests)}
    return sorted(got, key=lambda q: (when.get(q.id, "9999"), order[q.id]))


def render_menagerie(rep: "PlayerReport", history: list[dict]) -> list[str]:
    qs = [q for q in rep.quests if q.companion and (not q.hidden or q.dest.exists())]
    hatched = hatched_quests(rep, history)
    lines = [f"## 🐾 Your menagerie · {len(hatched)} of {len(qs)} hatched", ""]
    if hatched:
        q = hatched[-1]
        lines += [f"> 🎉 **Newest friend:** {q.companion.get('emoji', '')} **{companion_label(q)}** "
                  f"({q.id} · {q.title}): *{q.companion.get('says', '')}*", ""]
    lines.append("<p>" + " ".join(companion_img(q, rep.results[q.id]) for q in qs) + "</p>")
    lines += ["", "<sub>Every quest hides an egg. 🥚 waiting · 🐣 hatching (you've started that quest) · "
              "clear the quest to hatch its companion. Hover over one to meet it.</sub>", ""]
    return lines


def hatch_celebration(q: Quest) -> None:
    """A two-second hatching animation in the terminal (plain text when output isn't a terminal)."""
    c = q.companion
    emoji = c.get("emoji", "🐣")
    if sys.stdout.isatty():
        for frame in ["🥚    ", " 🥚   ", "🥚    ", "  🥚  ", "🥚    ", "🥚💥  ", "🐣    ", f"{emoji} ✨  "]:
            print("\r    " + frame, end="", flush=True)
            time.sleep(0.25)
        print("\r" + " " * 24 + "\r", end="")
    print(f"\n  {emoji}  {companion_label(q)} hatched!  “{c.get('says', '')}”")


# ───────────────────────────── git + journal signals ─────────────────────────────


def git_activity(player: str) -> dict:
    try:
        # Only files the player writes, so Game Master and bot commits don't count as their activity.
        paths = [f"Players/{player}/{x}" for x in ("quests", "log.md", "intake.md", "hints.json", "detours.json")]
        out = subprocess.run(["git", "log", "--format=%an|%aI", "--", *paths], cwd=ROOT,
                             capture_output=True, text=True, timeout=60).stdout
    except (OSError, subprocess.TimeoutExpired):
        out = ""
    rows = [ln.split("|", 1) for ln in out.splitlines() if "|" in ln]
    stamps = [t for a, t in rows if a != BOT_NAME]
    hours = [int(t[11:13]) for t in stamps if len(t) >= 13 and t[11:13].isdigit()]
    last = max(stamps, key=lambda t: parse_time(t) or datetime.min.replace(tzinfo=timezone.utc)) if stamps else None
    return {
        "commits": len(stamps),
        "days": len({t[:10] for t in stamps}),
        "night_owl": any(0 <= h < 5 for h in hours),
        "last_push": last,
    }


def log_entries(player: str) -> list[str]:
    text = re.sub(r"<!--.*?-->", "", read(PLAYERS_DIR / player / "log.md"), flags=re.S)
    parts = re.split(r"(?m)^## ", text)
    return ["## " + p.strip() for p in parts[1:] if p.strip()]


def load_history() -> list[dict]:
    events = []
    for line in read(HISTORY_FILE).splitlines():
        line = line.strip()
        if line:
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                pass
    return events


# ───────────────────────────── evaluation ─────────────────────────────


@dataclass
class PlayerReport:
    name: str
    route: dict
    quests: list[Quest]
    results: dict[str, Result]
    activity: dict
    logs: list[str]
    hints_used: dict
    detours: list[dict]
    detours_left: int
    xp: int = 0
    rank: str = ""
    next_rank: tuple[int, str] | None = None
    badges: list[tuple[str, str, str]] = field(default_factory=list)
    interests: dict[str, int] = field(default_factory=dict)
    mix: dict[str, float] = field(default_factory=dict)
    avatar: str = ""


def evaluate(players: list[str], meta: dict, lake: str | None, text_only: bool,
             cache: dict, allow_unlock: bool) -> tuple[list[PlayerReport], set[str]]:
    # 1. Collect every touched Lean file that needs compiling.
    plans: dict[str, tuple[dict, list[Quest]]] = {}
    jobs: dict[Path, str] = {}
    for p in players:
        route = load_route(p)
        qs = quests_for(p, meta, route)
        plans[p] = (route, qs)
        for q in qs:
            if q.kind == "lean" and q.dest.exists() and read(q.dest) != read(q.template):
                jobs[q.dest] = sha(read(q.dest)) + ":" + toolchain() + (":text" if text_only or not lake else "")
    todo = [path for path, key in jobs.items() if key not in cache]
    if todo:
        mode = "counting sorries (unverified)" if (text_only or not lake) else "compiling with Lean"
        print(f"… {mode}: {len(todo)} file(s)", file=sys.stderr)
        workers = max(1, min(len(todo), (os.cpu_count() or 2) // 2 or 1, 4))
        with ThreadPoolExecutor(max_workers=workers) as pool:
            for path, res in zip(todo, pool.map(lambda f: compile_lean(f, lake, text_only), todo)):
                cache[jobs[path]] = res

    reports: list[PlayerReport] = []
    for p in players:
        route, qs = plans[p]
        results: dict[str, Result] = {q.id: score_quest(q, cache.get(jobs.get(q.dest, ""))) for q in qs}
        detours = load_detours(p)
        allowance = detour_allowance(meta, route)
        opened = set(route.get("open", [])) | {d["quest"] for d in detours[:allowance]}
        by_id = {x.id: x for x in qs}
        changed = True
        while changed:   # repeat so an intake or project can't block a chain
            changed = False
            for q in qs:
                if results[q.id].status != "locked" or (q.hidden and q.id not in opened):
                    continue
                if not q.template.exists():
                    continue
                if q.id in opened or prerequisites_met(q, results, by_id):
                    if allow_unlock and q.kind != "intake":
                        q.dest.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copyfile(q.template, q.dest)
                        results[q.id] = score_quest(q, None)
                        results[q.id].unlocked_now = True
                    else:
                        results[q.id] = Result(status="open", total=puzzle_total(q),
                                               open=template_puzzles(q))
                    changed = True
        rep = PlayerReport(p, route, qs, results, git_activity(p), log_entries(p), load_hints_used(p),
                           detours, max(0, allowance - len(detours)))
        rep.xp = sum(r.xp for r in results.values())
        ranks = meta.get("ranks", [[0, "Verifier"]])
        rep.rank = [name for need, name in ranks if rep.xp >= need][-1]
        rep.next_rank = next(((need, name) for need, name in ranks if need > rep.xp), None)
        rep.badges = compute_badges(rep)
        rep.interests = parse_interests(read(PLAYERS_DIR / p / "intake.md"), meta)
        rep.avatar = parse_avatar(read(PLAYERS_DIR / p / "intake.md"))
        rep.mix = ratings_mix(qs, results)
        reports.append(rep)
    return reports, set(jobs.values())


def puzzle_total(q: Quest) -> int:
    if q.kind == "lean":
        return max(1, count_sorries(read(q.template)))
    if q.kind == "intake":
        return max(1, read(q.template).count(PLACEHOLDER))
    return 1


def template_puzzles(q: Quest) -> list[str]:
    if q.kind != "lean":
        return []
    text = read(q.template)
    return owner_names(text, sorry_lines_in_text(text))


def score_quest(q: Quest, compiled: dict | None) -> Result:
    total = puzzle_total(q)
    if q.kind == "intake":
        if not q.dest.exists():
            return Result("locked", 0, total)
        left = read(q.dest).count(PLACEHOLDER)
        done = total - min(left, total)
        if left == 0:
            return Result("cleared", total, total, q.xp)
        return Result("progress" if done else "new", done, total, 0)
    if q.kind == "project":
        if q.done_when and (ROOT / q.done_when).exists():
            return Result("cleared", 1, 1, q.xp)
        return Result("new" if q.dest.exists() else "locked", 0, 1, 0)
    if not q.dest.exists():
        return Result("locked", 0, total)
    text = read(q.dest)
    if text == read(q.template) or compiled is None:
        return Result("new", 0, total, 0, open=template_puzzles(q))
    missing = [n for n in theorem_names(read(q.template)) if n not in set(theorem_names(text))]
    solved = max(0, total - compiled["sorries"] - compiled["errors"] - len(missing))
    if compiled["errors"]:
        status = "broken"
    elif missing:
        status = "tampered"
    elif solved >= total:
        status = "cleared"
    else:
        status = "progress"
    xp = round(q.xp * solved / total) + (round(q.xp * CLEAR_BONUS) if status == "cleared" else 0)
    open_names = owner_names(text, compiled.get("sorry_lines", []))
    return Result(status, min(solved, total), total, xp, compiled.get("messages", []), missing, open_names)


def prerequisites_met(q: Quest, results: dict[str, Result], by_id: dict[str, Quest]) -> bool:
    def met(qid: str) -> bool:
        r, req = results.get(qid), by_id.get(qid)
        return r is not None and req is not None and r.fraction >= req.unlock_at - 1e-9
    if not all(met(x) for x in q.requires):
        return False
    return not q.requires_any or any(met(x) for x in q.requires_any)


BADGES = [
    ("🐣", "Hatched", "joined the expedition"),
    ("🏕️", "Basecamp", "finished the intake"),
    ("✍️", "First Proof", "solved a first puzzle"),
    ("🏋️", "Proof Gym", "cleared the Proof Gym"),
    ("🛡️", "Knight Vision", "cleared The Tactic Toolkit"),
    ("🔮", "Oracle Breaker", "cleared The Oracle Lies"),
    ("🕵️", "Kernel Auditor", "cleared The RH Audit"),
    ("🔍", "Spec Reviewer", "cleared Spec Review"),
    ("🧨", "Red Teamer", "cleared Red-Team the Grader"),
    ("🎲", "Statistician", "cleared the whole Statistician's Path"),
    ("🤖", "Machine Whisperer", "cleared the whole Machine Whisperer's Path"),
    ("🏛️", "Systems Verifier", "cleared the whole Verified Systems Path"),
    ("🗡️", "Made For You", "cleared a custom quest"),
    ("🐾", "Zookeeper", "hatched 10 companions"),
    ("🦄", "Full Menagerie", "hatched every companion on your route"),
    ("🦉", "Night Owl", "pushed work between midnight and 5am"),
    ("📅", "Three Days", "worked on three different days"),
    ("📓", "Field Scientist", "wrote 3+ log entries"),
    ("💯", "Fifty Proofs", "solved 50 puzzles"),
    ("🤝", "Co-op", "finished the capstone"),
]


def compute_badges(rep: PlayerReport) -> list[tuple[str, str, str]]:
    R = rep.results
    cleared = {qid for qid, r in R.items() if r.status == "cleared"}
    lean_solved = sum(R[q.id].solved for q in rep.quests if q.kind == "lean")
    zoo = [q for q in rep.quests if q.companion and not q.hidden]

    def track_done(track: str) -> bool:
        ids = [q.id for q in rep.quests if q.track == track and not q.hidden]
        return bool(ids) and all(i in cleared for i in ids)

    earned = {
        "Hatched": True,
        "Basecamp": "B00" in cleared,
        "First Proof": lean_solved >= 1,
        "Proof Gym": "T0" in cleared,
        "Knight Vision": "Q02" in cleared,
        "Oracle Breaker": "Q04" in cleared,
        "Kernel Auditor": "Q05" in cleared,
        "Spec Reviewer": "Q06" in cleared,
        "Red Teamer": "Q07" in cleared,
        "Statistician": track_done("stats"),
        "Machine Whisperer": track_done("ai"),
        "Systems Verifier": track_done("verified"),
        "Made For You": any(q.custom and q.id in cleared for q in rep.quests),
        "Zookeeper": sum(1 for q in rep.quests if q.companion and q.id in cleared) >= 10,
        "Full Menagerie": bool(zoo) and all(q.id in cleared for q in zoo),
        "Night Owl": rep.activity["night_owl"],
        "Three Days": rep.activity["days"] >= 3,
        "Field Scientist": len(rep.logs) >= 3,
        "Fifty Proofs": lean_solved >= 50,
        "Co-op": "CAPSTONE" in cleared,
    }
    return [b for b in BADGES if earned.get(b[1])]


def next_up(rep: PlayerReport, limit: int = 3) -> list[Quest]:
    order = {qid: i for i, qid in enumerate(rep.route.get("path", []))}
    playable = [q for q in rep.quests
                if rep.results[q.id].status in ("new", "open", "progress", "broken", "tampered")
                and (not q.hidden or q.dest.exists())]
    rank = {"broken": 0, "tampered": 0, "progress": 1, "new": 2, "open": 2}
    playable.sort(key=lambda q: (-1 if q.kind == "intake" else order.get(q.id, 999), rank[rep.results[q.id].status]))
    return playable[:limit]


def interest_matches(rep: PlayerReport, limit: int | None = 3) -> list[Quest]:
    """Unfinished quests on this route that best match the player's stated interests."""
    if not rep.interests:
        return []
    cands = [q for q in rep.quests if q.kind != "intake" and rep.results[q.id].status != "cleared"
             and (not q.hidden or q.dest.exists()) and interest_score(q, rep.interests) > 0]
    cands.sort(key=lambda q: -interest_score(q, rep.interests))
    return cands[:limit]


# ───────────────────────────── trail (history) and signals ─────────────────────────────


def player_snapshot(rep: PlayerReport) -> dict:
    """What the trail logger compares between runs."""
    quests = {}
    for q in rep.quests:
        r = rep.results[q.id]
        quests[q.id] = {"status": r.status, "solved": r.solved, "total": r.total,
                        "hash": sha(read(q.dest)) if q.dest.exists() else None}
    return {"quests": quests,
            "hints": {k: v.get("level", 0) for k, v in rep.hints_used.items()},
            "detours": [d["quest"] for d in rep.detours],
            "interests": dict(rep.interests)}


def trail_events(reports: list[PlayerReport], previous: dict) -> list[dict]:
    """Compare this run with the last one and describe what happened."""
    events: list[dict] = []
    ci_time = now_iso()
    current = {rep.name for rep in reports}
    for rep in reports:
        prev = previous.get(rep.name)
        pushed = parse_time(rep.activity.get("last_push"))
        work_time = pushed.astimezone(timezone.utc).isoformat(timespec="seconds") if pushed else ci_time
        titles = {q.id: q.title for q in rep.quests}
        snap = player_snapshot(rep)

        def ev(kind: str, t: str, **extra):
            events.append({"t": t, "player": rep.name, "event": kind, **extra})

        if prev is None:
            ev("joined", work_time)
            prev = {"quests": {}, "hints": {}, "detours": []}
        for qid in snap["detours"]:
            if qid not in prev.get("detours", []):
                ev("detour", work_time, quest=qid, title=titles.get(qid, qid))
        for qid, cur in snap["quests"].items():
            old = prev.get("quests", {}).get(qid, {"status": "locked", "hash": None, "solved": 0})
            base = {"quest": qid, "title": titles.get(qid, qid)}
            if (old["status"] in ("locked", "open") and cur["status"] not in ("locked", "open")
                    and qid != "B00"):
                ev("unlocked", ci_time, **base)
            if cur["hash"] and cur["hash"] != old.get("hash") and cur["status"] not in ("new", "locked", "open"):
                ev("update", work_time, status=cur["status"], solved=cur["solved"], total=cur["total"], **base)
            if cur["status"] == "cleared" and old["status"] != "cleared":
                ev("cleared", work_time, solved=cur["solved"], total=cur["total"], **base)
            if cur["status"] == "broken" and old["status"] != "broken":
                ev("broke", work_time, **base)
            if old["status"] == "broken" and cur["status"] not in ("broken", "locked"):
                ev("fixed", work_time, **base)
        if snap["interests"] and snap["interests"] != prev.get("interests", {}):
            ev("interests", work_time, interests=snap["interests"])
        for key, level in snap["hints"].items():
            if level > prev.get("hints", {}).get(key, 0):
                qid, _, puzzle = key.partition("/")
                ev("hint", work_time, quest=qid, title=titles.get(qid, qid), puzzle=puzzle, level=level)
    for name in previous:
        if name not in current:
            events.append({"t": ci_time, "player": name, "event": "left"})
    return events


def quest_signals(rep: PlayerReport, history: list[dict]) -> dict[str, dict]:
    """Per-quest performance signals for the Game Master."""
    mine = [e for e in history if e.get("player") == rep.name]
    now = datetime.now(timezone.utc)
    out: dict[str, dict] = {}
    for q in rep.quests:
        r = rep.results[q.id]
        evs = [e for e in mine if e.get("quest") == q.id]
        updates = [e for e in evs if e["event"] == "update"]
        first = lambda kind: next((e["t"] for e in evs if e["event"] == kind), None)  # noqa: E731
        started = updates[0]["t"] if updates else None
        cleared = first("cleared")
        last = updates[-1]["t"] if updates else None
        hours = None
        if started and cleared and parse_time(started) and parse_time(cleared):
            hours = round((parse_time(cleared) - parse_time(started)).total_seconds() / 3600, 1)
        last_dt = parse_time(last)
        hints = {k.split("/", 1)[1]: v.get("level", 0) for k, v in rep.hints_used.items() if k.startswith(q.id + "/")}
        if not (evs or hints or r.status not in ("locked",)):
            continue
        out[q.id] = {
            "unlocked": first("unlocked"), "started": started, "cleared": cleared, "last_update": last,
            "hours_start_to_clear": hours, "pushes": len(updates),
            "pushes_with_errors": sum(1 for e in updates if e.get("status") == "broken"),
            "hints_revealed": hints, "open_puzzles": r.open,
            "stalled": bool(r.status in ("progress", "broken", "tampered") and last_dt
                            and (now - last_dt).total_seconds() > STALL_HOURS * 3600),
        }
    return out


# ───────────────────────────── career cards ─────────────────────────────


def card_quests(rep: PlayerReport) -> list[Quest]:
    return [q for q in rep.quests if q.card and q.card.exists() and (not q.hidden or q.dest.exists())]


def collected_cards(rep: PlayerReport, history: list[dict]) -> list[Quest]:
    """Cards for cleared quests, in the order the quests were cleared."""
    cleared_at = {}
    for e in history:
        if e.get("player") == rep.name and e.get("event") == "cleared" and e.get("quest") not in cleared_at:
            cleared_at[e["quest"]] = e["t"]
    got = [q for q in card_quests(rep) if rep.results[q.id].status == "cleared"]
    order = {q.id: i for i, q in enumerate(rep.quests)}
    return sorted(got, key=lambda q: (cleared_at.get(q.id, "9999"), order[q.id]))


def render_cards(rep: PlayerReport, history: list[dict]) -> str:
    got, total = collected_cards(rep, history), len(card_quests(rep))
    lines = [f"# 🎓 {rep.name}'s career cards", "",
             "_One card for every quest you clear: what you practiced, where it shows up in real jobs, a stretch "
             "goal, and an honest résumé line. Rewritten automatically after every push. The big picture is in "
             "[docs/CAREERS.md](../../docs/CAREERS.md)._", "", f"**Collected: {len(got)} of {total}**", ""]
    if not got:
        lines.append("_Clear your first quest to collect a card._")
    for q in got:
        art = companion_img(q, rep.results[q.id], width=88) if q.companion else ""
        art = art.replace("<img ", '<img align="right" ', 1) if art.startswith("<img") else art
        lines += ["---", "", art, "", read(q.card).strip(), ""]
    return "\n".join(lines).rstrip() + "\n"


# ───────────────────────────── rendering ─────────────────────────────


def cell(r: Result, q: Quest) -> str:
    e = STATUS_EMOJI[r.status]
    if r.status in ("progress", "broken", "tampered") and q.kind != "project":
        return f"{e} {r.solved}/{r.total}"
    return e


def xp_bar(rep: PlayerReport, width: int = 12) -> str:
    if not rep.next_rank:
        return "▰" * width + " max rank!"
    floor = max([n for n, _ in load_meta()["ranks"] if n <= rep.xp] or [0])
    need, name = rep.next_rank
    filled = int(width * (rep.xp - floor) / max(1, need - floor))
    return "▰" * filled + "▱" * (width - filled) + f" next: **{name}** at {need} XP"


def mermaid(rep: PlayerReport) -> str:
    def nid(s: str) -> str:
        return re.sub(r"[^A-Za-z0-9]", "", s) or "x"
    visible = [q for q in rep.quests if not q.hidden or q.dest.exists()]
    ids = {q.id for q in visible}
    lines = ["flowchart TD"]
    for q in visible:
        r = rep.results[q.id]
        title = q.title.replace('"', "'")
        label = f"{q.id} · {title}<br/>{cell(r, q)}" if r.status != "locked" else f"🔒 {title}"
        lines.append(f'  {nid(q.id)}["{label}"]')
    for q in visible:
        for req in q.requires:
            if req in ids:
                lines.append(f"  {nid(req)} --> {nid(q.id)}")
        for req in q.requires_any:
            if req in ids:
                lines.append(f"  {nid(req)} -.-> {nid(q.id)}")
    css = {"cleared": "fill:#d9f2e3,stroke:#1f8a4c,color:#0d3b21",
           "progress": "fill:#fff1cc,stroke:#b7791f,color:#4a3206",
           "broken": "fill:#fde2e1,stroke:#c53030,color:#5c1111",
           "tampered": "fill:#fde2e1,stroke:#c53030,color:#5c1111",
           "new": "fill:#e3ecff,stroke:#3b5bdb,color:#14245c",
           "open": "fill:#e3ecff,stroke:#3b5bdb,color:#14245c",
           "locked": "fill:#f1f3f5,stroke:#adb5bd,color:#6c757d,stroke-dasharray: 4 3"}
    for status, style in css.items():
        members = [nid(q.id) for q in visible if rep.results[q.id].status == status]
        if members:
            lines.append(f"  classDef {status} {style}")
            lines.append(f"  class {','.join(members)} {status}")
    return "\n".join(lines)


def describe_event(e: dict) -> str:
    what = f"**{e.get('quest')} · {e.get('title')}**" if e.get("quest") else ""
    kind = e["event"]
    if kind == "joined":
        return "Joined the expedition"
    if kind == "unlocked":
        return f"Unlocked {what}"
    if kind == "detour":
        return f"Spent a detour token on {what}"
    if kind == "update":
        return f"Worked on {what}: {e.get('solved')}/{e.get('total')}"
    if kind == "cleared":
        return f"Cleared {what}"
    if kind == "broke":
        return f"{what} stopped compiling"
    if kind == "fixed":
        return f"Fixed {what}"
    if kind == "hint":
        return f"Hint {e.get('level')} for `{e.get('puzzle')}` in {what}"
    if kind == "interests":
        return "Set interests: " + format_interests(e.get("interests", {}), load_meta())
    return kind


def render_map(rep: PlayerReport, meta: dict, history: list[dict]) -> str:
    tracks = meta.get("tracks", {})
    badges = " · ".join(f"{e} {n}" for e, n, _ in rep.badges) or "none yet"
    intake = rep.results.get("B00")
    route_note = rep.route.get("summary")
    hints_total = sum(v.get("level", 0) for v in rep.hints_used.values())
    lines = [
        f"# {rep.avatar or '🗺️'} {rep.name}'s map",
        "",
        "_Rewritten automatically after every push. Don't edit it; edit your quest files and log.md._",
        "",
        f"**Rank:** {rep.rank} · **XP:** {rep.xp}  ",
        f"{xp_bar(rep)}",
        "",
        f"**Badges:** {badges}  ",
        f"🎟️ **Detour tokens:** {rep.detours_left} left · 💡 **Hints revealed:** {hints_total} · "
        f"🎓 **Career cards:** {sum(1 for q in card_quests(rep) if rep.results[q.id].status == 'cleared')} of "
        f"{len(card_quests(rep))} → [CAREER_CARDS.md](CAREER_CARDS.md)",
        "",
    ]
    if intake and intake.status != "cleared":
        lines += ["> 🏕️ **Start at Basecamp:** fill in [intake.md](intake.md) (10 minutes). The Game Master plans "
                  "your route from it. Start Quest 00 (Orientation) while you wait.", ""]
    elif route_note:
        lines += [f"> 🧭 **Your route:** {route_note} (details in [ROUTE.md](ROUTE.md))", ""]
    else:
        lines += ["> 🧭 Your intake is in. The Game Master will plan your personal route soon. "
                  "Keep playing; nothing is wasted.", ""]
    lines += render_menagerie(rep, history)
    lines += ["## Next up", ""]
    nxt = next_up(rep)
    if not nxt:
        lines.append("Everything visible is cleared. Ask the Game Master for more (write it in log.md). 🎉")
    for i, q in enumerate(nxt, 1):
        r = rep.results[q.id]
        where = q.dest.relative_to(PLAYERS_DIR / rep.name).as_posix()
        open_note = f" Open puzzles: {', '.join(f'`{n}`' for n in r.open[:8])}." if r.open and q.kind == "lean" else ""
        focus = chips(q, meta)
        focus = f" {focus}" if focus else ""
        lines.append(f"{i}. **{q.id} · {q.title}** ({cell(r, q)}, ⏱ {q.minutes} min){focus}: {q.blurb}{open_note} "
                     f"→ [`{where}`]({where})")
    lines += ["", "## 🧭 Your field map", ""]
    if rep.interests:
        lines.append(f"**Your interests** (from [intake.md](intake.md); change them any time): "
                     f"{format_interests(rep.interests, meta)}  ")
    else:
        lines.append("**Your interests:** rate the seven regions in [intake.md](intake.md) (section 1), and this "
                     "map will suggest quests that match.  ")
    if rep.mix:
        lines.append(f"**What your puzzles have practiced so far:** {format_mix(rep.mix, meta)}  ")
    matches = interest_matches(rep, limit=None)
    shown = {q.id for q in nxt}
    now = [q for q in matches if rep.results[q.id].status != "locked" and q.id not in shown][:2]
    later = [q for q in matches if rep.results[q.id].status == "locked"][:3]
    if now:
        lines.append("🎯 **Also open, and a good match for you:** " + "; ".join(
            f"{q.id} · {q.title} ({chips(q, meta, with_features=False)})" for q in now) + "  ")
    if later:
        def opens(q: Quest) -> str:
            req = ", ".join(q.requires)
            if q.requires_any:
                req += (" + " if req else "") + "one of " + ", ".join(q.requires_any)
            return f"opens after {req}" if req else "opens soon"
        lines.append("🔭 **On the horizon for your interests:** " + "; ".join(
            f"{q.id} · {q.title} ({chips(q, meta, with_features=False)}, {opens(q)})" for q in later) + "  ")
    lines.append("What the symbols mean, and every quest rated: [docs/QUEST_GUIDE.md](../../docs/QUEST_GUIDE.md) "
                 "· in the terminal: `python3 scripts/expedition.py guide`")
    lines += ["",
              "> **Stuck?** Any of these is fine:",
              "> 1. `python3 scripts/expedition.py hint <puzzle>` shows one hint at a time (math idea first, then the Lean move).",
              "> 2. Switch to another quest in *Next up*; prerequisites open at 60%, so you never need every puzzle.",
              f"> 3. Spend a detour token ({rep.detours_left} left): `python3 scripts/expedition.py detour <QuestID>` "
              "opens any locked quest on your next push.",
              "> 4. Write \"stuck on ...\" in log.md, and the Game Master's next dispatch will help.",
              "", "📬 Latest notes from the Game Master: [DISPATCH.md](DISPATCH.md) · Field Guide: "
              "[docs/FIELD_GUIDE.md](../../docs/FIELD_GUIDE.md)", "", "## Map", "",
              "```mermaid", mermaid(rep), "```", "", "## All quests", "",
              "| | Quest | Path | Focus | Progress | XP |", "|---|---|---|---|---|---:|"]
    for q in rep.quests:
        if q.hidden and not q.dest.exists():
            continue
        r = rep.results[q.id]
        name = q.title if r.status == "locked" else f"[{q.title}]({q.dest.relative_to(PLAYERS_DIR / rep.name).as_posix()})"
        prog = f"{r.solved}/{r.total}" if q.kind == "lean" and r.status != "locked" else ""
        lines.append(f"| {STATUS_EMOJI[r.status]} | {q.id} · {name} | {tracks.get(q.track, q.track)} | "
                     f"{chips(q, meta, limit=2, with_features=False)} | {prog} | {r.xp} |")
    problems = [(q, rep.results[q.id]) for q in rep.quests if rep.results[q.id].status in ("broken", "tampered")]
    if problems:
        lines += ["", "## 🔧 Lean found problems", ""]
        for q, r in problems:
            for m in r.messages[:3]:
                lines.append(f"- **{q.id}**: `{m}`")
            if r.missing:
                lines.append(f"- **{q.id}**: these theorems are missing from your copy: {', '.join(r.missing)}. "
                             f"(Put them back; deleting a puzzle doesn't solve it. 😉)")
    mine = [e for e in history if e.get("player") == rep.name]
    lines += ["", "## Your trail", "", "<sub>Newest first · times in UTC</sub>", ""]
    if not mine:
        lines.append("_Your trail starts with your first push._")
    by_id = {q.id: q for q in rep.quests}
    for e in reversed(mine[-12:]):
        stamp = (e.get("t") or "")[:16].replace("T", " ")
        extra = ""
        q = by_id.get(e.get("quest"))
        if e["event"] == "cleared" and q and q.companion:
            extra = f" and hatched {q.companion.get('emoji', '')} {companion_label(q)}"
        lines.append(f"- `{stamp}` {EVENT_EMOJI.get(e['event'], '•')} {describe_event(e)}{extra}")
    if len(mine) > 12:
        lines.append(f"- … and {len(mine) - 12} earlier events in `expedition/history.jsonl`")
    legend = " · ".join(f"{c['emoji']} {c['name']}" for c in criteria(meta))
    lines += ["", "<sub>Legend: 🆕 ready · 🛠️ in progress · ✅ cleared · 💥 doesn't compile · ⚠️ puzzle missing · 🔒 locked"
              f"<br/>Focus: {legend} · ●●● main focus, ●●○ a big part, ●○○ a touch · ⌨️ you write programs · "
              "🧠 a real AI in the loop (? = optional) · 🎨 open-ended</sub>", ""]
    return "\n".join(lines)


def render_readme_section(reports: list[PlayerReport], meta: dict) -> str:
    lines = ["### 🏔️ Live scoreboard", ""]
    if not reports:
        lines += ["No verifiers yet. Run `python3 scripts/expedition.py join YourName`, then commit and push.", ""]
        return "\n".join(lines)
    lines += ["| Verifier | Rank | XP | Cleared | Puzzles solved | Basecamp | Route | Menagerie | Badges |",
              "|---|---|---:|---:|---:|:---:|:---:|---|---|"]
    for rep in reports:
        cleared = sum(1 for r in rep.results.values() if r.status == "cleared")
        solved = sum(rep.results[q.id].solved for q in rep.quests if q.kind == "lean")
        basecamp = "✅" if rep.results.get("B00") and rep.results["B00"].status == "cleared" else "⏳"
        route = "🧭" if rep.route else "—"
        badges = " ".join(e for e, _, _ in rep.badges)
        zoo = "".join(q.companion.get("emoji", "") for q in hatched_quests(rep, load_history())) or "🥚"
        who = f"{rep.avatar} " if rep.avatar else ""
        lines.append(f"| {who}[{rep.name}](Players/{rep.name}/MAP.md) | {rep.rank} | {rep.xp} | {cleared} | {solved} | "
                     f"{basecamp} | {route} | {zoo} | {badges} |")
    lines += ["", "#### Quest board", "", "| Quest | " + " | ".join(r.name for r in reports) + " |",
              "|---|" + ":---:|" * len(reports)]
    for e in meta["quests"]:
        row = [f"{e['id']} · {e['title']}"]
        for rep in reports:
            q = next(q for q in rep.quests if q.id == e["id"])
            r = rep.results[q.id]
            row.append("·" if q.hidden and not q.dest.exists() else cell(r, q))
        lines.append("| " + " | ".join(row) + " |")
    customs = [(rep, q) for rep in reports for q in rep.quests if q.custom]
    if customs:
        lines += ["", "**Custom quests:** " + ", ".join(
            f"{rep.name}: {q.title} {cell(rep.results[q.id], q)}" for rep, q in customs)]
    lines += ["", "<sub>🆕 ready · 🛠️ in progress · ✅ cleared · 💥 doesn't compile · 🔒 locked · · not on this route · "
              "🧭 personal route planned</sub>", ""]
    return "\n".join(lines)


def replace_section(text: str, body: str, start: str = MARK_START, end: str = MARK_END) -> str:
    block = f"{start}\n{body}\n{end}"
    if start in text and end in text:
        pre = text.split(start)[0]
        post = text.split(end, 1)[1]
        return pre + block + post
    return text.rstrip() + "\n\n" + block + "\n"


def report_json(reports: list[PlayerReport], history: list[dict], with_signals: bool = True) -> dict:
    out = {"generated": now_iso(), "players": {}}
    for rep in reports:
        signals = quest_signals(rep, history) if with_signals else {}
        mine = [e for e in history if e.get("player") == rep.name]
        out["players"][rep.name] = {
            "rank": rep.rank, "xp": rep.xp,
            "badges": [n for _, n, _ in rep.badges],
            "route_planned": bool(rep.route),
            "route_summary": rep.route.get("summary"),
            "activity": rep.activity,
            "log_entries": len(rep.logs),
            "latest_log": rep.logs[-1] if rep.logs else None,
            "next_up": [q.id for q in next_up(rep)],
            "detours_used": [d["quest"] for d in rep.detours],
            "detours_left": rep.detours_left,
            "hints_revealed_total": sum(v.get("level", 0) for v in rep.hints_used.values()),
            "stalled_quests": [qid for qid, s in signals.items() if s.get("stalled")],
            "career_cards": [q.id for q in collected_cards(rep, history)],
            "interests": rep.interests,
            "avatar": rep.avatar,
            "companions_hatched": [q.id for q in hatched_quests(rep, history)],
            "mix_so_far": rep.mix,
            "interest_matches": [q.id for q in interest_matches(rep)],
            "recent_trail": mine[-15:],
            "quests": {q.id: {"title": q.title, "track": q.track, "status": rep.results[q.id].status,
                              "solved": rep.results[q.id].solved, "total": rep.results[q.id].total,
                              "hidden": q.hidden, "custom": q.custom,
                              "file": q.dest.relative_to(ROOT).as_posix(),
                              "problems": rep.results[q.id].messages[:3] + (
                                  [f"missing: {', '.join(rep.results[q.id].missing)}"]
                                  if rep.results[q.id].missing else []),
                              "signals": signals.get(q.id)}
                       for q in rep.quests},
        }
    return out


# ───────────────────────────── commands ─────────────────────────────


def load_state() -> dict:
    state = read_json(STATE_FILE, {})
    if not isinstance(state, dict) or state.get("engine") not in (1, ENGINE_VERSION):
        state = {}
    state["engine"] = ENGINE_VERSION
    state.setdefault("cache", {})
    return state


def run(players: list[str], text_only: bool, allow_unlock: bool) -> tuple[list[PlayerReport], dict, dict]:
    meta = load_meta()
    state = load_state()
    lake = None if text_only else find_lake()
    if not text_only and lake is None:
        print("⚠️  Lean (lake) not found, so progress is estimated by counting sorries (unverified).\n"
              "    Install Lean (START_HERE.md) or work in a Codespace for real checking.", file=sys.stderr)
    reports, used = evaluate(players, meta, lake, text_only, state["cache"], allow_unlock)
    state["used"] = used
    return reports, meta, state


def resolve_player(explicit: str | None, required: bool = True) -> str | None:
    players = discover_players()
    name = explicit or (read(PLAYER_FILE).strip() if PLAYER_FILE.exists() else None)
    if not name and len(players) == 1:
        name = players[0]
    if name and name in players:
        return name
    if required:
        if name:
            sys.exit(f"No player named {name}. Players: {', '.join(players) or 'none yet'}.")
        sys.exit("Which player? Add --as YourName (or run `join` first, which remembers your name).")
    return None


def cmd_join(name: str) -> int:
    if not NAME_RE.match(name):
        print("Pick a name with letters, digits, - or _ (start with a letter, max 24 chars).")
        return 1
    dest = PLAYERS_DIR / name
    PLAYER_FILE.write_text(name + "\n", encoding="utf-8")
    if dest.exists():
        print(f"Players/{name} already exists. Welcome back! (This computer now remembers you as {name}.)")
        return 0
    shutil.copytree(TEMPLATE_DIR, dest)
    for f in dest.rglob("*.md"):
        f.write_text(read(f).replace("{{NAME}}", name), encoding="utf-8")
    (dest / "quests").mkdir(exist_ok=True)
    reports, meta, _ = run([name], text_only=True, allow_unlock=True)
    (dest / "MAP.md").write_text(render_map(reports[0], meta, []), encoding="utf-8")
    (dest / "CAREER_CARDS.md").write_text(render_cards(reports[0], []), encoding="utf-8")
    print(f"""
🎒 Welcome to the expedition, {name}!

  Your folder:   Players/{name}/
  First stop:    Players/{name}/intake.md   (10 min; the Game Master plans your route from it)
  First quest:   Players/{name}/quests/Q00_Orientation.lean   (a 20-minute tour of Lean)
  Stuck later?   python3 scripts/expedition.py hint <puzzle>
  Every quest hides an egg 🥚. Clear the quest and an animal companion hatches.

Now save your progress to GitHub:
  git add -A
  git commit -m "{name} joins the expedition"
  git push
""")
    return 0


def cmd_leave(name: str | None, yes: bool) -> int:
    if not name or not (PLAYERS_DIR / name).is_dir() or name.startswith("_"):
        print("Usage: python3 scripts/expedition.py leave <Name> --yes   (Name must be an existing player)")
        return 1
    targets = [PLAYERS_DIR / name] + ([CUSTOM_DIR / name] if (CUSTOM_DIR / name).exists() else [])
    if not yes:
        print("This deletes:\n" + "\n".join(f"  {t.relative_to(ROOT)}/" for t in targets) +
              f"\nRun again with --yes to confirm:  python3 scripts/expedition.py leave {name} --yes")
        return 1
    for t in targets:
        shutil.rmtree(t)
    if PLAYER_FILE.exists() and read(PLAYER_FILE).strip() == name:
        PLAYER_FILE.unlink()
    print(f"👋 Removed {name}. To make it official on GitHub:\n"
          f"  git add -A && git commit -m \"Remove player {name}\" && git push\n"
          f"The next Expedition run drops {name} from the scoreboard and logs it in the trail.")
    return 0


def cmd_detour(quest_id: str | None, who: str | None) -> int:
    name = resolve_player(who)
    meta = load_meta()
    route = load_route(name)
    qs = {q.id: q for q in quests_for(name, meta, route)}
    used = load_detours(name)
    left = detour_allowance(meta, route) - len(used)
    if not quest_id:
        print(f"🎟️ {name} has {max(0, left)} detour token(s). Use one with: "
              f"python3 scripts/expedition.py detour <QuestID>")
        return 0
    quest_id = quest_id.upper()
    if quest_id not in qs:
        print(f"No quest {quest_id}. Quest IDs: {', '.join(qs)}")
        return 1
    q = qs[quest_id]
    if q.dest.exists() or quest_id in {d['quest'] for d in used}:
        print(f"{quest_id} is already open for you. No token needed.")
        return 0
    if left <= 0:
        print("No detour tokens left. Ask the Game Master in your log; it can grant more.")
        return 1
    used.append({"quest": quest_id, "t": now_iso()})
    (PLAYERS_DIR / name / "detours.json").write_text(json.dumps({"used": used}, indent=2) + "\n", encoding="utf-8")
    print(f"🎟️ Detour booked: {quest_id} · {q.title}. It opens after your next push "
          f"({left - 1} token(s) left).\n  git add -A && git commit -m \"Detour to {quest_id}\" && git push")
    return 0


def cmd_hint(puzzle: str | None, who: str | None, again: bool) -> int:
    name = resolve_player(who)
    meta = load_meta()
    route = load_route(name)
    qs = [q for q in quests_for(name, meta, route) if q.kind == "lean" and q.dest.exists()]
    used = load_hints_used(name)
    if not puzzle:
        print(f"Open puzzles for {name} (use: python3 scripts/expedition.py hint <puzzle>):")
        for q in qs:
            text = read(q.dest)
            names = owner_names(text, sorry_lines_in_text(text))
            if names:
                print(f"  {q.id} · {q.title}: {', '.join(names)}")
        return 0
    matches = [(q, parse_hints(read(q.hints)) if q.hints else {}) for q in qs]
    matches = [(q, h) for q, h in matches if puzzle in h]
    if not matches:
        known = sorted({k for q, h in [(q, parse_hints(read(q.hints)) if q.hints else {}) for q in qs] for k in h})
        close = [k for k in known if puzzle.lower() in k.lower()]
        print(f"No hints found for `{puzzle}` in your open quests." +
              (f" Did you mean: {', '.join(close)}?" if close else "") +
              "\nRun `python3 scripts/expedition.py hint` to list your open puzzles.")
        return 1
    q, hints = matches[0]
    levels = hints[puzzle]
    key = f"{q.id}/{puzzle}"
    seen = used.get(key, {}).get("level", 0)
    show = seen if again and seen else min(seen + 1, len(levels))
    print(f"\n💡 {q.id} · {q.title} · `{puzzle}`  (hint {show} of {len(levels)})\n")
    for i in range(show):
        marker = "→" if i == show - 1 else " "
        body = levels[i].replace("\n", "\n     ")
        print(f"  {marker} {i + 1}. {body}\n")
    if show >= len(levels):
        print("  That's the last hint. Still stuck? Write it in your log, ask a sibling, or ask an AI\n"
              "  (paste the goal from the Infoview). Getting unstuck is part of the game.")
    else:
        print(f"  Need more? Run the same command again for hint {show + 1}.")
    if show > seen:
        stamp = now_iso()
        used[key] = {"level": show, "of": len(levels), "first": used.get(key, {}).get("first", stamp), "last": stamp}
        (PLAYERS_DIR / name / "hints.json").write_text(json.dumps(used, indent=2, ensure_ascii=False) + "\n",
                                                        encoding="utf-8")
    return 0


def cmd_guide(arg: str | None, who: str | None, write: bool) -> int:
    meta = load_meta()
    if write:
        text = read(QUEST_GUIDE)
        new = replace_section(text, render_quest_guide(meta), GUIDE_START, GUIDE_END)
        if new != text:
            QUEST_GUIDE.write_text(new, encoding="utf-8")
        print("docs/QUEST_GUIDE.md is up to date.")
        return 0
    name = resolve_player(who, required=False)
    rep = run([name], text_only=True, allow_unlock=False)[0][0] if name else None
    pool = rep.quests if rep else quests_for("_", meta, {})
    quests = [q for q in pool if q.kind != "intake" and (not q.hidden or q.dest.exists())]
    interests: dict[str, int] = {}
    source = ""
    if arg:
        for word in (w for w in arg.split(",") if w.strip()):
            cid = match_criterion(word, meta)
            if not cid:
                print(f"Unknown interest `{word}`. Use any of: " + ", ".join(c["id"] for c in criteria(meta)))
                return 1
            interests[cid] = 3
        source = "ranked for: " + " ".join(next(c["emoji"] for c in criteria(meta) if c["id"] == k) for k in interests)
    elif rep and rep.interests:
        interests, source = rep.interests, "ranked for your intake interests: " + format_interests(rep.interests, meta)
    if interests:
        quests.sort(key=lambda q: -interest_score(q, interests))
        quests = [q for q in quests if interest_score(q, interests) > 0]
    print(f"\n🧭 Quest guide{' · ' + source if source else ''}\n")
    for q in quests:
        status = (STATUS_EMOJI[rep.results[q.id].status] + " ") if rep else ""
        focus = chips(q, meta, limit=7, min_level=1)
        print(f"  {status}{q.id:<9}{q.title:<28}{focus}   {STARS.get(q.difficulty, '')}  ⏱ {q.minutes}")
    print("\n  ●●● main focus · ●●○ a big part · ●○○ a touch · ⌨️ programs · 🧠 real AI (? optional) · 🎨 open-ended")
    print("  " + " · ".join(f"{c['emoji']} {c['id']}" for c in criteria(meta)))
    print("  Full table and what each region means: docs/QUEST_GUIDE.md")
    if not arg and not (rep and rep.interests):
        print("  Tip: rate the seven regions in your intake.md, or try `guide safety,code`.")
    return 0


def cmd_status(player: str | None, everyone: bool, text_only: bool) -> int:
    players = discover_players()
    if not players:
        print("No players yet. Run: python3 scripts/expedition.py join YourName")
        return 0
    chosen = players if everyone else [resolve_player(player, required=False) or ""]
    chosen = [p for p in chosen if p] or players
    reports, _, _ = run(chosen, text_only, allow_unlock=False)
    for rep in reports:
        print(f"\n{rep.name}: {rep.rank}, {rep.xp} XP, badges: {' '.join(e for e, _, _ in rep.badges)}"
              f"   🎟️ {rep.detours_left} detour(s)")
        for q in rep.quests:
            r = rep.results[q.id]
            if r.status == "locked" or (q.hidden and not q.dest.exists()):
                continue
            extra = f"  ← {r.messages[0]}" if r.messages else ""
            if r.status == "open":
                extra = "  (unlocks on GitHub after you push)"
            elif r.open and r.status in ("progress", "new") and q.kind == "lean":
                extra = f"  open: {', '.join(r.open[:6])}" + (" …" if len(r.open) > 6 else "")
            print(f"  {STATUS_EMOJI[r.status]} {q.id:<9} {q.title:<28} {r.solved}/{r.total}{extra}")
    show_new_cards(reports)
    return 0


def show_new_cards(reports: list[PlayerReport]) -> None:
    """Print a career card the first time this computer sees its quest cleared."""
    seen = read_json(SEEN_CARDS_FILE, {})
    changed = False
    for rep in reports:
        mine = set(seen.get(rep.name, []))
        cards = {q.id for q in card_quests(rep)}
        for q in rep.quests:
            if rep.results[q.id].status != "cleared" or q.id in mine or not (q.companion or q.id in cards):
                continue
            if q.companion:
                hatch_celebration(q)
            if q.id in cards:
                print("\n" + "═" * 72 + f"\n🎓 NEW CAREER CARD for {rep.name}\n\n" + read(q.card).strip() +
                      "\n\n(Push to add it to your CAREER_CARDS.md.)\n" + "═" * 72)
            mine.add(q.id)
            changed = True
        seen[rep.name] = sorted(mine)
    if changed:
        try:
            SEEN_CARDS_FILE.write_text(json.dumps(seen, indent=1) + "\n", encoding="utf-8")
        except OSError:
            pass


def cmd_report(text_only: bool) -> int:
    reports, _, _ = run(discover_players(), text_only, allow_unlock=False)
    print(json.dumps(report_json(reports, load_history()), indent=2, ensure_ascii=False))
    return 0


def cmd_update(text_only: bool, force: bool) -> int:
    if os.environ.get("GITHUB_ACTIONS") != "true" and not force:
        print("`update` rewrites README.md and every MAP.md, so GitHub Actions runs it after each push.\n"
              "Running it locally causes merge conflicts. Use `status` instead (or add --force).")
        return 1
    state = load_state()
    previous = state.get("snapshots", {})
    reports, meta, state = run(discover_players(), text_only, allow_unlock=True)
    events = trail_events(reports, previous)
    if events:
        with HISTORY_FILE.open("a", encoding="utf-8") as fh:
            for e in events:
                fh.write(json.dumps(e, ensure_ascii=False) + "\n")
    history = load_history()
    for rep in reports:
        path = PLAYERS_DIR / rep.name / "MAP.md"
        new = render_map(rep, meta, history)
        if read(path) != new:
            path.write_text(new, encoding="utf-8")
        cards_path = PLAYERS_DIR / rep.name / "CAREER_CARDS.md"
        cards = render_cards(rep, history)
        if read(cards_path) != cards:
            cards_path.write_text(cards, encoding="utf-8")
        opened = [q.id for q in rep.quests if rep.results[q.id].unlocked_now]
        if opened:
            print(f"🔓 {rep.name}: unlocked {', '.join(opened)}")
    guide = read(QUEST_GUIDE)
    if guide:
        new_guide = replace_section(guide, render_quest_guide(meta), GUIDE_START, GUIDE_END)
        if new_guide != guide:
            QUEST_GUIDE.write_text(new_guide, encoding="utf-8")
    body = render_readme_section(reports, meta)
    readme = read(README)
    if MARK_START not in readme or body not in readme:
        README.write_text(replace_section(readme, body), encoding="utf-8")
    live = {k: v for k, v in state["cache"].items() if k in state["used"]}
    new_state = {"engine": ENGINE_VERSION, "toolchain": toolchain(),
                 "players": report_json(reports, history, with_signals=False)["players"],
                 "snapshots": {rep.name: player_snapshot(rep) for rep in reports}, "cache": live}
    for p in new_state["players"].values():
        p.pop("recent_trail", None)
    old = read_json(STATE_FILE, {})
    keys = ("players", "snapshots", "cache", "toolchain")
    if {k: old.get(k) for k in keys} != {k: new_state[k] for k in keys}:
        new_state["updated"] = now_iso()
        STATE_FILE.write_text(json.dumps(new_state, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"🗺️  Expedition updated ({len(events)} new trail event(s)).")
    return 0


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description="The Expedition engine.")
    ap.add_argument("command", choices=["join", "status", "hint", "detour", "guide", "leave", "report", "update"])
    ap.add_argument("arg", nargs="?", help="a name, a puzzle, or a quest ID depending on the command")
    ap.add_argument("--as", dest="who", help="act as this player")
    ap.add_argument("--all", action="store_true", help="status for every player")
    ap.add_argument("--again", action="store_true", help="hint: reprint the hints you've already seen")
    ap.add_argument("--yes", action="store_true", help="leave: confirm")
    ap.add_argument("--no-lean", action="store_true", help="count sorries instead of compiling (unverified)")
    ap.add_argument("--force", action="store_true", help="allow `update` outside GitHub Actions")
    ap.add_argument("--write", action="store_true", help="guide: regenerate docs/QUEST_GUIDE.md")
    a = ap.parse_args(argv)
    if a.command == "join":
        if not a.arg:
            ap.error("join needs a name: python3 scripts/expedition.py join YourName")
        return cmd_join(a.arg)
    if a.command == "leave":
        return cmd_leave(a.arg, a.yes)
    if a.command == "hint":
        return cmd_hint(a.arg, a.who, a.again)
    if a.command == "detour":
        return cmd_detour(a.arg, a.who)
    if a.command == "guide":
        return cmd_guide(a.arg, a.who, a.write)
    if a.command == "status":
        return cmd_status(a.arg or a.who, a.all, a.no_lean)
    if a.command == "report":
        return cmd_report(a.no_lean)
    return cmd_update(a.no_lean, a.force)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
