# 🎒 Start here

Three ways in. **Pick A** unless you love setting up toolchains.

## A · GitHub Codespaces (recommended: nothing to install)

1. On the repo page: **Code → Codespaces → Create codespace on main**.
2. Wait for the first boot. It installs Lean and downloads about 5 GB of prebuilt Mathlib, which takes roughly 5–10 minutes the first time. Later boots are fast. Grab a snack. 🍪
3. When the terminal says `✅ Lean + Mathlib are ready`, you're set.

Free GitHub accounts get a monthly Codespaces allowance that's plenty for this. Students can get more through the GitHub Student Developer Pack. Stop the codespace when you're done (it also stops itself after 30 idle minutes).

## B · On your own laptop

1. Install [VS Code](https://code.visualstudio.com/) and [git](https://git-scm.com/).
2. In VS Code, install the **Lean 4** extension (by leanprover). Its setup guide installs `elan`, Lean's version manager.
3. Clone the repo and download Mathlib's prebuilt files:
   ```bash
   git clone <this repo's URL>
   cd <repo folder>
   lake exe cache get
   ```
4. Open the folder in VS Code. Needs about 6 GB of disk and 8 GB of RAM.

## C · Just curious? Zero setup

- [live.lean-lang.org](https://live.lean-lang.org): Lean + Mathlib in your browser. Paste any quest in to play (you'll still need A or B to push).
- [The Natural Number Game](https://adam.math.hhu.de/#/g/leanprover-community/nng4): the classic gamified intro. Great for a lazy evening; tell the Game Master in your log if you played it.

---

## Join the expedition (once)

In the terminal, at the repo root:

```bash
python3 scripts/expedition.py join YourName
git add -A
git commit -m "YourName joins the expedition"
git push
```

Then:

1. **Basecamp:** open `Players/YourName/intake.md` and answer the questions (15–20 minutes). It starts with a 2-minute "why this game exists" and a tour of the seven regions of the field, each of which you rate by interest. Push it. The Game Master plans **your** route from this.
2. **Quest 00:** open `Players/YourName/quests/Q00_Orientation.lean`, a 20-minute tour of the Lean moves you'll use everywhere. Play it while your route is being planned.

Every quest hides an egg 🥚. Clear the quest and an animal companion hatches into the menagerie on your map (and does a little hatching animation in your terminal the first time `status` sees it).

`join` also remembers your name on this computer, so later commands (`status`, `hint`, `detour`) know who you are.

## Using Lean in VS Code

- The **Infoview** panel shows the goal at your cursor. If it's missing: Ctrl+Shift+Enter (Cmd+Shift+Enter on a Mac).
- Type symbols with backslash shortcuts: `\to` →, `\and` ∧, `\N` ℕ, `\R` ℝ, `\ne` ≠, `\le` ≤. Hover over any symbol to see how to type it.
- Yellow squiggle = `sorry` (unsolved). Red = error. Nothing = proved. ✨
- The first time a file loads, `import Mathlib` takes 10–30 seconds. After that it's quick.

## The session ritual

```bash
git pull                                       # get new quests + dispatches
# play for 30–60 minutes
python3 scripts/expedition.py status           # instant local check
# add a short entry to Players/YourName/log.md
git add -A
git commit -m "what you did"
git push
```

A few minutes after you push, GitHub checks your proofs and commits your updated map (and any quests you unlocked). `git pull` next time to get them.

**Git hiccup?** If `git push` is rejected, run `git pull --rebase` and push again. That just means the Expedition bot committed something while you were working. Cheat sheet for everything else: [docs/CHEATSHEET.md](docs/CHEATSHEET.md).

## Stuck?

1. `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time: the idea first, then the Lean move. Run it with no puzzle name to list your open puzzles. Hints are logged for the Game Master; there's no penalty.
2. `exact?` asks Lean to search Mathlib for a lemma that closes the goal.
3. Switch to another quest. Prerequisites open at 60%, and `python3 scripts/expedition.py detour <QuestID>` spends one of your 2 detour tokens to open any locked quest. Not sure which? `python3 scripts/expedition.py guide` ranks the quests for your interests ([docs/QUEST_GUIDE.md](docs/QUEST_GUIDE.md) explains the ratings).
4. Ask an AI. That's allowed and even encouraged. Paste the goal from the Infoview, and log whether its proof actually compiled.
5. Write "stuck on X" in your log; the next dispatch will help.
6. The [Field Guide](docs/FIELD_GUIDE.md) has the full unsticking routine and how to search Mathlib. If you use Claude Code, `/hint <theorem name>` gives a tutor-style hint ladder.
