---
description: Get a hint (not the answer) for a puzzle you're stuck on
argument-hint: "<quest file or theorem name>"
---

The player is stuck on: `$ARGUMENTS`

Act as a tutor, not a solver. Find the theorem in their quest file under `Players/`, read the statement and whatever they've tried so far, and run `lake env lean <file>` to see Lean's current error or goal state if that helps.

Then give a **hint ladder**:
1. A one-line nudge: which idea or tactic family to think about.
2. Hidden in a `<details><summary>Stronger hint</summary>...</details>` block: the first concrete move, and what the goal looks like after it.
3. Hidden in another `<details>` block: what to do once that works.

Never write the full proof into their file, and don't paste a complete solution unless they explicitly say "I give up, show me". If they do, show it, explain each line, and suggest a similar puzzle to try on their own.
