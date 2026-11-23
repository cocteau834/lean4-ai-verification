# 🎒 Start here

Setup happens once, on your own laptop, and takes about 30 minutes, mostly waiting for downloads. After that, every session is: open VS Code, play, push.

## What you're installing, and why

| Piece | What it does |
|---|---|
| **VS Code** + the **Lean 4** extension | Where you write proofs. The *Infoview* panel shows Lean's live feedback as you type. |
| **Lean** + **Mathlib** | The proof checker and its huge math library. Mathlib comes prebuilt, so you download it instead of compiling it. |
| **git** | Saves your work to GitHub. Every push gets checked there, and your map and menagerie are redrawn. |
| **Python 3** (3.9 or newer) | Runs the game script: `status`, `hint`, `guide`, the hatching animation. No extra packages needed. |

You need about **12 GB of free disk space** (Lean is 3 GB, Mathlib about 8 GB) and 8 GB of RAM.

## Set up on Windows

1. Install **[Git for Windows](https://git-scm.com/download/win)**. The default options are fine.
2. Install **[VS Code](https://code.visualstudio.com/)**.
3. Check Python: open a terminal (PowerShell) and run `py --version`. If it prints 3.9 or newer, you're set. If not, install Python from [python.org](https://www.python.org/downloads/) and tick **"Add python.exe to PATH"** in the installer.
4. Get the repo. In VS Code press **Ctrl+Shift+P**, run **Git: Clone**, choose **Clone from GitHub**, and sign in to GitHub in the browser when asked. Pick the repo and save it to a short folder such as `C:\code`. Open it when VS Code offers.
5. Install the **Lean 4** extension (Extensions panel on the left, search "Lean 4", publisher *leanprover*). When it offers to install Lean (via *elan*, Lean's installer), accept. Then **close and reopen VS Code** so the terminal can find Lean.
6. Open VS Code's terminal (**Ctrl+`**) and download Mathlib:
   ```bash
   lake exe cache get
   ```
   This takes 5–15 minutes. Grab a snack. 🍪

**On Windows, type `py` wherever these instructions say `python3`.** For example: `py scripts/expedition.py status`.

## Set up on a Mac

1. Open Terminal and run `xcode-select --install`. This installs git and Python 3. If it says they're already installed, you're set.
2. Install **[VS Code](https://code.visualstudio.com/)**.
3. Get the repo. In VS Code press **Cmd+Shift+P**, run **Git: Clone**, choose **Clone from GitHub**, and sign in to GitHub in the browser when asked. Save it anywhere you like and open it when VS Code offers.
4. Install the **Lean 4** extension (Extensions panel, search "Lean 4", publisher *leanprover*). When it offers to install Lean (via *elan*), accept. Then **quit and reopen VS Code**.
5. Open VS Code's terminal (**Ctrl+`**) and download Mathlib:
   ```bash
   lake exe cache get
   ```
   This takes 5–15 minutes. 🍪

## Both: tell git who you are (once)

```bash
git config --global user.name "Your Name"
git config --global user.email "the-email-on-your-GitHub-account"
```

(If you'd rather not use your real email, GitHub gives you a private *noreply* address under Settings → Emails.) The first time you push, a browser window may ask you to approve the sign-in. Say yes.

## Check that it works

Open `Quests/Q00_Orientation.lean` in VS Code. After 10–30 seconds, the Infoview on the right shows goals, and each `sorry` has a yellow squiggle with no red ones. That means Lean and Mathlib are working. 🎉

Now that this little test is done, close `Quests/Q00_Orientation.lean`. Later you will open your own copy of this file (`Players/YourName/quests/Q00_Orientation.lean`, created when you join below).

**If something goes wrong:**
- *`lake` (or `lean`) is not recognized:* close and reopen VS Code (or your terminal). Lean's installer adds itself to your PATH, but already-open windows don't see it.
- *"Filename too long" (Windows):* run `git config --global core.longpaths true`, then clone again into a short folder like `C:\code`.
- *Everything is red after `import Mathlib`:* run `lake exe cache get` again; the download was probably interrupted.
- *Still stuck:* write down the exact error message and ask Dad (or paste it into Claude).

## Other ways in

- **GitHub Codespaces** (a backup if your laptop can't take it). On the repo page: **Code → Codespaces → Create codespace on main**, and it sets itself up in about 15 minutes. Mathlib is too big for the standard Codespace, so the repo asks for GitHub's 8-core machine with 64 GB of disk. That uses the free monthly allowance about four times faster than the standard one (roughly 15 hours a month on a free account; check GitHub's billing page for current numbers). Stop it when you're done.
- **Just curious?** [live.lean-lang.org](https://live.lean-lang.org) runs Lean + Mathlib in your browser (paste any quest in; you still need a real setup to push). [The Natural Number Game](https://adam.math.hhu.de/#/g/leanprover-community/nng4) is the classic gamified intro; tell the Game Master in your log if you played it.

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
