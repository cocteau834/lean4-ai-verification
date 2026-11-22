# Proof or It Didn't Happen: notes for Claude

A gamified Lean 4 short course for two university students (a statistics senior and an AI + math sophomore), run by their dad over winter break 2026–27. Students push work; a GitHub Action (`scripts/expedition.py update`) checks proofs, unlocks quests and redraws maps; Claude acts as the **Game Master** to personalize what comes next.

## Which role am I playing?

- **Default: tutor.** If someone working in a `Players/<name>/` folder asks for help, teach. Use hint ladders, explain Lean errors and goal states, point to tactics. Don't write full solutions into their quest files unless they explicitly say "I give up, show me". Never edit their intake, log or quest files on your own initiative. `/hint` encodes this.
- **Game Master:** only when invoked with `/gm` (or asked by Dad to run a GM pass). Then follow `GAME_MASTER.md` exactly.

## Commands

- Check one file: `lake env lean Players/<name>/quests/<file>.lean`
- Player progress (read-only): `python3 scripts/expedition.py status [Name]` (`--all` for everyone; `--no-lean` for a fast, unverified count)
- Player tools: `hint <puzzle>` (logged hint ladder), `detour <QuestID>` (spend a detour token), `guide [interests]` (quests ranked by the seven-region ratings, for the player's intake interests or e.g. `guide safety,code`), `leave <Name> --yes`
- After editing ratings in `expedition/quests.json`: `python3 scripts/expedition.py guide --write` regenerates the table in `docs/QUEST_GUIDE.md` (CI does it too)
- GM data dump: `python3 scripts/expedition.py report` (progress, per-quest signals, stalled quests, hints, recent trail)
- Build all quest templates: `lake build`
- Mathlib cache after a fresh clone: `lake exe cache get`
- Don't run `expedition.py update` locally. GitHub Actions owns it, and running it here causes merge conflicts on README and the MAP files.

## Contracts that must not break

- Quest templates (`Quests/*.lean`, `expedition/custom/<name>/*.lean`): `import Mathlib` first, one `sorry` per declaration (puzzle count = number of sorries), no `#eval` that depends on a `sorry`, theorem names stable once published (the engine flags missing theorem names as tampering).
- Hints live outside the quest files so every reveal is logged: `Quests/hints/<ID>.md` (custom: `expedition/custom/<name>/hints/<ID>.md`), a `## puzzle` heading per puzzle with numbered levels. Idea first, Lean move second, near-solution last.
- Career cards: `Quests/cards/<ID>.md` (custom: `expedition/custom/<name>/cards/<ID>.md`). Quests carry `🧑‍🔬 ON THE JOB` comment boxes that link a puzzle to real work. Career claims must stay factual and match docs/CAREERS.md.
- `expedition/history.jsonl` is append-only and written only by `update` in CI. Never edit it by hand.
- Quest metadata lives in `expedition/quests.json`; per-player routes live in `Players/<name>/route.json` (schema in GAME_MASTER.md).
- Every quest (custom ones too) carries `ratings` (seven regions, 1–3, zeros omitted), `features` (`programs` / `real_ai` / `open_ended`: `"yes"` or `"optional"`) and `difficulty` (1–3). The region list lives in `quests.json` (`rating_criteria`); the narrative for each region is in `docs/QUEST_GUIDE.md` and the intake's field tour. Keep all three consistent.
- The intake's interest lines (`**My interest (0–3):** N` under a `### <emoji> <region>` heading) are parsed by the engine. Keep that shape if you edit the template.
- Toolchain is pinned: `lean-toolchain` = `leanprover/lean4:v4.36.0`, Mathlib tag `v4.36.0` in `lakefile.toml`. Change both together, then rebuild and re-verify every quest.

## Who writes what (so nothing gets overwritten)

- **Each player** writes only inside `Players/<name>/`: `intake.md`, `log.md`, `quests/*.lean`, `hints.json`, `detours.json`.
- **The Game Master** writes only `DISPATCH.md`, `ROUTE.md`, `route.json` in player folders, plus `expedition/custom/`, `expedition/gm_journal.md` and `instructor/`.
- **The Expedition Action** alone writes generated files: `README.md` (scoreboard section), `docs/QUEST_GUIDE.md` (the ratings section between the `RATINGS` markers), `Players/*/MAP.md`, `Players/*/CAREER_CARDS.md`, newly unlocked quest copies, `expedition/state.json`, `expedition/history.jsonl`. It runs one at a time, starts from the latest `main`, rebuilds everything from the files, and commits with a rebase-and-retry push.
- Keep it that way: no one else should hand-edit generated files, and nothing local should run `update`.

## Maintainer notes (Dad + Claude)

- `instructor/` is gitignored and exists only on Dad's machine: verified solutions (`instructor/solutions/`), private review reports (`instructor/reviews/`) and setup notes (`instructor/README.md`). Never commit it, never quote solutions into dispatches.
- This folder is the git repo root, cloned from `cocteau834/lean4-ai-verification` on GitHub. Dad invites both students as collaborators.
- Optional automation: `extras/claude-game-master.yml` (see `extras/README.md`) runs dispatches and @claude tutoring from GitHub. It needs an `ANTHROPIC_API_KEY` secret and the Claude GitHub App.
- `docs/WHY_NOW.md` holds the sourced timeline of Lean + AI news, including the Nov 20–21, 2026 Riemann Hypothesis formalization. Dispatches should cite it rather than invent news.
