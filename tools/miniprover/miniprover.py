#!/usr/bin/env python3
"""
Mini-Prover: an LLM proposes Lean proofs, and Lean decides.

For every `sorry` in a Lean file, ask a model for a tactic proof, splice it in,
compile with Lean, and feed the error back if it fails, up to --attempts times.
Every attempt is logged to tools/miniprover/runs/results.csv.

  python3 tools/miniprover/miniprover.py FILE.lean                 # report only
  python3 tools/miniprover/miniprover.py FILE.lean --write         # keep proofs that pass
  python3 tools/miniprover/miniprover.py FILE.lean --manual        # no API key: you paste answers
  python3 tools/miniprover/miniprover.py FILE.lean --model claude-haiku-5-5 --repeat 4
      (--repeat N runs N independent conversations per theorem: data for pass@k)

Needs Lean (`lake`) and, unless --manual, the `anthropic` package plus an API key
(ANTHROPIC_API_KEY, or a profile from `ant auth login`).
"""
from __future__ import annotations

import argparse
import csv
import os
import re
import shutil
import subprocess
import sys
import textwrap
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
RESULTS = HERE / "runs" / "results.csv"
TMP = HERE / ".tmp"

DEFAULT_MODEL = "claude-opus-5-5"
# USD per million tokens (input, output). Check current pricing before quoting costs.
PRICES = {
    "claude-fable-5-2": (8.00, 40.00),
    "claude-opus-5-5": (4.00, 20.00),
    "claude-sonnet-5-5": (2.00, 10.00),
    "claude-haiku-5-5": (0.10, 0.50),
}
# Models that support the server-side refusal fallback (a declined request is re-run on a fallback model).
FALLBACK_MODELS = {"claude-fable-5-2", "claude-fable-5-1", "claude-opus-5-5", "claude-opus-5", "claude-sonnet-5-5"}
FORBIDDEN = re.compile(r"\b(sorry|admit|native_decide|axiom|implemented_by|unsafe)\b")
DECL_RE = re.compile(r"^[ \t]*(?:@\[[^\]]*\][ \t]*)?(?:private[ \t]+|protected[ \t]+|noncomputable[ \t]+)*(theorem|lemma|example|def|abbrev|instance)\b[ \t]*([^\s:({\[]*)", re.M)
SORRY_RE = re.compile(r"(?<![\w.'])sorry(?![\w'])")
ERROR_RE = re.compile(r":\d+:\d+: error|^error:", re.M)
SORRY_WARN_RE = re.compile(r"declaration uses .sorry.")
CSV_FIELDS = ["run_id", "timestamp_utc", "file", "theorem", "model", "effort", "repeat", "attempt",
              "success", "llm_seconds", "lean_seconds", "input_tokens", "output_tokens", "cost_usd", "error"]

SYSTEM = """You are an expert in Lean 4 and Mathlib ({toolchain}). You write tactic proofs that compile.

Reply with exactly one ```lean code block containing ONLY the tactic proof that replaces the
`sorry` marked TARGET. Do not restate the theorem, do not write `by`, and do not change anything
else in the file. Never use sorry, admit, native_decide, or new axioms. Mathlib is imported.
Before the code block you may think briefly about which tactics fit the goal."""


# ───────────────────────────── Lean helpers ─────────────────────────────

def strip_comments(text: str) -> str:
    """Blank out Lean comments, keeping offsets."""
    out, i, n, depth = [], 0, len(text), 0
    while i < n:
        if depth == 0:
            if text.startswith("--", i):
                j = text.find("\n", i)
                j = n if j == -1 else j
                out.append(" " * (j - i)); i = j
            elif text.startswith("/-", i):
                depth, i = 1, i + 2; out.append("  ")
            else:
                out.append(text[i]); i += 1
        else:
            if text.startswith("/-", i):
                depth, i = depth + 1, i + 2; out.append("  ")
            elif text.startswith("-/", i):
                depth, i = depth - 1, i + 2; out.append("  ")
            else:
                out.append("\n" if text[i] == "\n" else " "); i += 1
    return "".join(out)


def find_targets(text: str) -> list[dict]:
    """Every `sorry` outside comments, with the theorem it belongs to."""
    code = strip_comments(text)
    decls = [(m.start(), m.group(2) or f"{m.group(1)}@{text.count(chr(10), 0, m.start()) + 1}", m.group(1))
             for m in DECL_RE.finditer(code)]
    targets = []
    for m in SORRY_RE.finditer(code):
        owner = [d for d in decls if d[0] < m.start()]
        if not owner:
            continue
        start, name, kind = owner[-1]
        if kind not in ("theorem", "lemma", "example"):
            continue  # a `sorry` inside a definition is a design choice, not a proof to find
        targets.append({"name": name, "decl_start": start, "start": m.start(), "end": m.end()})
    return targets


def splice(text: str, target: dict, proof: str) -> str:
    line_start = text.rfind("\n", 0, target["start"]) + 1
    before = text[line_start:target["start"]]
    if before.strip() == "":
        indent, prefix = before, ""
    else:
        lead = re.match(r"[ \t]*", text[line_start:]).group(0)
        indent, prefix = lead + "  ", "\n" + lead + "  "
    lines = textwrap.dedent(proof.strip("\n")).splitlines() or ["skip"]
    body = ("\n" + indent).join(lines)
    return text[:target["start"]] + prefix + body + text[target["end"]:]


def clean_proof(reply: str) -> str:
    blocks = re.findall(r"```(?:lean4?|)\s*\n(.*?)```", reply, re.S)
    proof = (blocks[-1] if blocks else reply).strip("\n")
    head = proof.lstrip()
    if re.match(r"(theorem|lemma|example)\b", head) and ":= by" in head:
        proof = head.split(":= by", 1)[1]
    elif head.startswith("by\n") or head.startswith("by "):
        proof = head[2:]
    return textwrap.dedent(proof).strip("\n")


def find_lake() -> str | None:
    found = shutil.which("lake")
    if found:
        return found
    cand = Path.home() / ".elan" / "bin" / "lake"
    return str(cand) if cand.exists() else None


def compile_text(lake: str, text: str, timeout: int = 600) -> tuple[list[str], int, str, float]:
    TMP.mkdir(exist_ok=True)
    path = TMP / f"attempt_{uuid.uuid4().hex[:8]}.lean"
    path.write_text(text, encoding="utf-8")
    t0 = time.time()
    try:
        proc = subprocess.run([lake, "env", "lean", str(path)], cwd=ROOT, capture_output=True,
                              text=True, timeout=timeout)
        out = (proc.stdout or "") + (proc.stderr or "")
    except subprocess.TimeoutExpired:
        out = f"{path.name}:1:0: error: Lean timed out after {timeout}s"
    finally:
        path.unlink(missing_ok=True)
    secs = time.time() - t0
    errors = [ln for ln in out.splitlines() if ERROR_RE.search(ln)]
    return errors, len(SORRY_WARN_RE.findall(out)), out.replace(str(TMP) + os.sep, ""), secs


# ───────────────────────────── the model ─────────────────────────────

class Asker:
    def __init__(self, model: str, effort: str, manual: bool, toolchain: str):
        self.model, self.effort, self.manual = model, effort, manual
        self.system = SYSTEM.format(toolchain=toolchain)
        self.client = None
        if not manual:
            try:
                import anthropic  # noqa: F401
            except ImportError:
                sys.exit("The `anthropic` package isn't installed: pip install -r tools/miniprover/requirements.txt\n"
                         "(or use --manual to paste answers from any chatbot)")
            import anthropic
            self.anthropic = anthropic
            self.client = anthropic.Anthropic()

    def ask(self, messages: list) -> tuple[str | None, object, int, int, str]:
        """Returns (reply text, assistant content to append, input tokens, output tokens, note)."""
        if self.manual:
            return self._ask_manual(messages)
        a = self.anthropic
        kwargs = dict(model=self.model, max_tokens=16000, system=self.system, messages=messages,
                      output_config={"effort": self.effort})
        try:
            if self.model in FALLBACK_MODELS:
                resp = self.client.beta.messages.create(betas=["server-side-fallback-2026-07-01"],
                                                        fallbacks="default", **kwargs)
            else:
                resp = self.client.messages.create(**kwargs)
        except a.AuthenticationError:
            sys.exit("No valid Anthropic credentials. Set ANTHROPIC_API_KEY (ask the Game Master) or use --manual.")
        except a.NotFoundError:
            sys.exit(f"Unknown model {self.model!r}.")
        except a.RateLimitError:
            time.sleep(20)
            return None, None, 0, 0, "rate limited"
        except a.APIStatusError as e:
            return None, None, 0, 0, f"API error {e.status_code}"
        except a.APIConnectionError:
            return None, None, 0, 0, "network error"
        u = resp.usage
        if resp.stop_reason == "refusal":
            return None, None, u.input_tokens, u.output_tokens, "model declined"
        text = "".join(b.text for b in resp.content if b.type == "text")
        return text, resp.content, u.input_tokens, u.output_tokens, ""

    def _ask_manual(self, messages: list):
        last = messages[-1]["content"]
        print("\n" + "─" * 72)
        if len(messages) == 1:
            print("Paste this into any AI chatbot (Claude, ChatGPT, ...):\n")
            print(self.system + "\n\n" + last)
        else:
            print("Tell the chatbot (same conversation):\n")
            print(last)
        print("─" * 72)
        print("Paste its reply, then a line containing only END (or type SKIP):")
        lines = []
        for line in sys.stdin:
            if line.strip() == "END":
                break
            if line.strip() == "SKIP":
                return None, None, 0, 0, "skipped"
            lines.append(line)
        text = "".join(lines)
        return text, text, 0, 0, ""


def cost(model: str, tin: int, tout: int) -> float:
    pin, pout = PRICES.get(model, (0.0, 0.0))
    return round(tin / 1e6 * pin + tout / 1e6 * pout, 5)


# ───────────────────────────── main loop ─────────────────────────────

def prove(args) -> int:
    lake = find_lake()
    if not lake:
        sys.exit("Lean isn't installed here (no `lake`). Use a Codespace or see START_HERE.md.")
    path = Path(args.file).resolve()
    text = path.read_text(encoding="utf-8")
    toolchain = (ROOT / "lean-toolchain").read_text().strip()
    rel = path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path.name

    print(f"🔎 Baseline check of {rel} ...")
    errors, base_sorries, out, _ = compile_text(lake, text)
    if errors:
        print("The file has errors before we start. Fix these first:\n" + "\n".join(errors[:5]))
        return 1
    targets = [t for t in find_targets(text) if not args.only or t["name"] in args.only]
    if not targets:
        print("No `sorry` found. Nothing to prove. 🎉")
        return 0
    print(f"Found {len(targets)} target(s): {', '.join(t['name'] for t in targets)}")

    asker = Asker(args.model, args.effort, args.manual, toolchain)
    model_label = "manual" if args.manual else args.model
    run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:4]
    RESULTS.parent.mkdir(parents=True, exist_ok=True)
    new_csv = not RESULTS.exists()
    solved, total_cost = [], 0.0

    with RESULTS.open("a", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=CSV_FIELDS)
        if new_csv:
            writer.writeheader()
        for name in [t["name"] for t in targets]:
            won = False
            for rep in range(1, args.repeat + 1):
                current = next((t for t in find_targets(text) if t["name"] == name), None)
                if current is None:
                    break
                marked = text[:current["start"]] + "sorry /- ⟵ TARGET -/" + text[current["end"]:]
                messages = [{"role": "user", "content":
                             f"Replace the `sorry` marked TARGET in `{name}`.\n\n```lean\n{marked}\n```"}]
                print(f"\n▶ {name}" + (f"  (run {rep}/{args.repeat})" if args.repeat > 1 else ""))
                for attempt in range(1, args.attempts + 1):
                    t0 = time.time()
                    reply, content, tin, tout, note = asker.ask(messages)
                    llm_secs = time.time() - t0
                    c = cost(args.model, tin, tout) if not args.manual else 0.0
                    total_cost += c
                    row = {"run_id": run_id, "timestamp_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                           "file": rel, "theorem": name, "model": model_label, "effort": args.effort,
                           "repeat": rep, "attempt": attempt, "success": 0, "llm_seconds": round(llm_secs, 1),
                           "lean_seconds": 0, "input_tokens": tin, "output_tokens": tout, "cost_usd": c, "error": ""}
                    if reply is None:
                        row["error"] = note
                        writer.writerow(row); fh.flush()
                        print(f"   attempt {attempt}: no answer ({note})")
                        if note in ("skipped", "model declined"):
                            break
                        continue
                    proof = clean_proof(reply)
                    if FORBIDDEN.search(proof):
                        feedback = "That proof uses a forbidden keyword (sorry/admit/native_decide/axiom). Try again."
                        row["error"] = "forbidden keyword"
                    else:
                        candidate = splice(text, current, proof)
                        errs, sorries, raw, lean_secs = compile_text(lake, candidate)
                        row["lean_seconds"] = round(lean_secs, 1)
                        if not errs and sorries == base_sorries - 1:
                            row["success"] = 1
                            writer.writerow(row); fh.flush()
                            print(f"   attempt {attempt}: ✅ Lean accepts it")
                            print(textwrap.indent(proof, "      "))
                            won = True
                            if args.write and not solved.count(name):
                                text = candidate
                                base_sorries -= 1
                                path.write_text(text, encoding="utf-8")
                            solved.append(name)
                            break
                        row["error"] = (errs[0] if errs else "proof left a sorry")[:200]
                        detail = "\n".join(errs[:8]) if errs else "The declaration still uses sorry."
                        feedback = (f"Lean rejected that proof:\n```\n{raw.strip()[:3000] if errs else detail}\n```\n"
                                    "Read the goal state in the error carefully and try a different approach. "
                                    "Reply with one ```lean block containing only the tactic proof.")
                    writer.writerow(row); fh.flush()
                    print(f"   attempt {attempt}: ❌ {row['error']}")
                    messages += [{"role": "assistant", "content": content}, {"role": "user", "content": feedback}]
                if won and args.write and args.repeat == 1:
                    break

    unique = sorted(set(solved))
    print(f"\n🏁 Solved {len(unique)}/{len(targets)}: {', '.join(unique) or 'none'}")
    if not args.manual:
        print(f"   Estimated cost: ${total_cost:.4f} (check current pricing)")
    print(f"   Log: {RESULTS.relative_to(ROOT)}  (run_id {run_id})")
    if not args.write and unique:
        print("   Run again with --write to keep the proofs in the file.")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="LLM proposes, Lean disposes.")
    ap.add_argument("file", help="a .lean file containing sorries")
    ap.add_argument("--model", default=DEFAULT_MODEL, help=f"Claude model id (default {DEFAULT_MODEL})")
    ap.add_argument("--effort", default="medium", choices=["low", "medium", "high", "xhigh", "max"])
    ap.add_argument("--attempts", type=int, default=4, help="tries per theorem, with Lean's error fed back")
    ap.add_argument("--repeat", type=int, default=1, help="independent runs per theorem (for pass@k stats)")
    ap.add_argument("--only", nargs="*", help="only these theorem names")
    ap.add_argument("--write", action="store_true", help="write accepted proofs back into the file")
    ap.add_argument("--manual", action="store_true", help="no API: print prompts, paste replies")
    return prove(ap.parse_args())


if __name__ == "__main__":
    sys.exit(main())
