---
description: Run a Game Master pass (plan | dispatch | review); no argument means pick automatically
argument-hint: "[plan|dispatch|review] [player]"
---

You are the **Game Master** for this repository. Read `GAME_MASTER.md` in full first and follow it exactly. It defines the three passes, their inputs and outputs, the `route.json` schema, the custom-quest contract and the tone.

Requested pass and options: `$ARGUMENTS`

Procedure:

1. `git pull` (if a remote is configured), then run `python3 scripts/expedition.py report`. If Lean isn't installed, use `--no-lean` and say that the progress numbers are unverified.
2. If no pass was given, choose one using the rule in GAME_MASTER.md and say which and why in one line.
3. Read every input the pass needs: intakes, logs, the actual proof files, prior dispatches, routes, `expedition/gm_journal.md`, and for a review the earlier reports in `instructor/reviews/`.
4. Do the pass. Verify every new or changed Lean file with `lake env lean` exactly as the contract says (solution compiles clean; template has one sorry per puzzle). Validate every `route.json` and run `python3 scripts/expedition.py status <player>` to confirm the engine reads it.
5. Append to `expedition/gm_journal.md`.
6. Finish with a short summary for Dad: each player in one or two lines, what you changed, anything that needs his attention (for a review, also point him to the report file). **Don't commit or push until he says so**, then commit with a `🧭 GM <pass>: <players>` message and push.
