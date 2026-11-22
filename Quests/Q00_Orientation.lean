import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  QUEST 00 · ORIENTATION: LEAN IN 20 MINUTES     ⏱ 20–30 min │
  └──────────────────────────────────────────────────────────────┘

  A quick tour of the moves you'll use in almost every quest. Each station
  has a worked example (already done; click through it) and one tiny puzzle.
  Nothing here is hard. The goal is to get your hands used to Lean.

  THE SCREEN
  • Click on any line. The Infoview panel (right side) shows the proof state
    there. No Infoview? Ctrl+Shift+Enter (Cmd+Shift+Enter on a Mac).
  • Above the line: what you HAVE (hypotheses).  After `⊢`: your GOAL.
  • Each tactic changes the goal. "No goals" means proved.
  • `sorry` = an unsolved puzzle (yellow squiggle). Red = an error.
  • Type symbols with backslash: \to →  \and ∧  \or ∨  \N ℕ  \R ℝ  \le ≤  \ne ≠  \< ⟨  \> ⟩
    Hover over any symbol to see how to type it.

  THE SHAPE OF A THEOREM
      theorem  name  (inputs and hypotheses)  :  statement  :=  by  tactics

  STUCK? In the terminal:  python3 scripts/expedition.py hint <puzzle>
  e.g. `hint compute`. Hints come one at a time, first the idea, then the
  move. Try it once now so you know how it works.
-/

namespace Q00

/-! ## Station 1 · Let Lean calculate: `#eval`, `rfl`, `norm_num`, `decide`

`#eval` runs code. For facts about concrete numbers, Lean can calculate:
  `rfl` (both sides compute to the same thing), `norm_num` (a calculator
  that produces proofs), `decide` (checks every case of a finite question). -/

#eval 2 ^ 10

example : 2 ^ 10 = 1024 := by norm_num

theorem compute : 12 * 12 = 144 := by
  sorry

/-! ## Station 2 · Use what you have: `exact`, and hypotheses as functions

`h : P` means "h is a proof of P". A hypothesis `key : P → Q` is a function:
feed it a proof of P and you get a proof of Q. `exact` says "this is
exactly the goal". -/

example (n : ℕ) (h : n = 3) : n = 3 := by
  exact h

theorem use_it (n : ℕ) (h : 5 < n) (key : 5 < n → n ≠ 0) : n ≠ 0 := by
  sorry

/-! ## Station 3 · Take apart, build up: `obtain`, `⟨ ⟩`, `constructor`, `·`

`obtain ⟨h1, h2⟩ := h` splits `h : A ∧ B` into its two halves.
`⟨x, y⟩` builds an "and" (or an "exists") from its pieces.
`constructor` splits an ∧ goal into two goals; `·` focuses on one of them. -/

example (a b : ℕ) (h : a < b ∧ 0 < a) : 0 < a := by
  obtain ⟨h1, h2⟩ := h
  exact h2

example (a b : ℕ) (h1 : a < b) (h2 : 0 < a) : 0 < a ∧ a < b := by
  constructor
  · exact h2
  · exact h1

theorem swap_and (a b c : ℕ) (h : a < b ∧ b < c) : b < c ∧ a < b := by
  sorry

/-! ## Station 4 · Proof by cases: `rcases`

`rcases h with h0 | h1` splits `h : A ∨ B` into two cases, one per side.
You prove the goal in each case. -/

theorem two_cases (n : ℕ) (h : n = 0 ∨ n = 1) : n < 2 := by
  rcases h with h0 | h1
  · rw [h0]            -- case n = 0: replace n by 0...
    norm_num           -- ...and calculate
  · sorry              -- ✏️ case n = 1: same idea

/-! ## Station 5 · Rewrite and simplify: `rw`, `simp`, `unfold`

`rw [h]` uses `h : x = y` to replace x by y in the goal (`rw [← h]` goes
right-to-left; `rw [h] at h2` rewrites a hypothesis instead). `simp` tidies
up routine stuff. `unfold f` expands a definition. -/

def double (n : ℕ) : ℕ := 2 * n

example : double 5 = 10 := by
  unfold double
  norm_num

theorem substitute (a b : ℕ) (h : a = b + 2) : a + a = 2 * b + 4 := by
  rw [h]
  sorry                -- ✏️ what's left is pure algebra (see Station 7)

/-! ## Station 6 · Prove that something exists: `use`

To prove `∃ n, P n`, name the n with `use`, then prove P for it. -/

example : ∃ n : ℕ, n * 2 = 8 := by
  use 4

theorem witness : ∃ n : ℕ, n + 3 = 10 := by
  sorry

/-! ## Station 7 · The autopilots: `ring`, `linarith`, `nlinarith`, `omega`

These do the boring parts:
  `ring`       any identity of +, −, ×, ^        (a + b)² = a² + 2ab + b²
  `linarith`   inequalities that follow linearly from your hypotheses
  `nlinarith`  the same, but allowed to multiply hypotheses (squares!)
  `omega`      whole-number arithmetic (ℕ and ℤ, no multiplying variables)  -/

example (a : ℝ) : (a - 1) * (a + 1) = a ^ 2 - 1 := by ring

example (n m : ℕ) (h : n < m) : n + 1 ≤ m := by omega

theorem expand (a b : ℝ) : (a + b) ^ 2 = a ^ 2 + 2 * a * b + b ^ 2 := by
  sorry

theorem squeeze (x y : ℝ) (h1 : x < y) (h2 : 0 < x) : x < 2 * y := by
  sorry

/-! ## Station 8 · Induction (just look; you'll do it properly in Quest 03)

To prove something for every n: prove it for 0, then show that if it holds
for k it holds for k + 1. `ih` is the "it holds for k" hypothesis. -/

theorem pow_pos_demo (n : ℕ) : 0 < 2 ^ n := by
  induction n with
  | zero => norm_num                 -- 0 < 2^0
  | succ k ih =>                     -- ih : 0 < 2^k,  goal : 0 < 2^(k+1)
    rw [pow_succ]                    -- 2^(k+1) = 2^k * 2
    linarith

/-! ## Station 9 · Let Lean search: `exact?`

Mathlib holds about 250,000 theorems. If your goal is a known fact, `exact?`
searches for one that closes it and tells you its name (a blue "Try this"
appears in the Infoview; click it). `#check` shows what a theorem says. -/

#check Nat.Prime.two_le

theorem find_it (p : ℕ) (hp : p.Prime) : 2 ≤ p := by
  sorry

/- 🧑‍🔬 ON THE JOB · Search is half the work
   Professional Lean users run `exact?`, Loogle and LeanSearch all day. AI
   provers do the same thing at scale: choosing the few useful lemmas out of
   Mathlib's 250,000 is a research problem of its own ("premise selection").
-/

/-! ## 🐉 BOSS · Put it together

Prove there is a c with a = c + 1 and 0 < c. You'll need a witness, an ∧,
and some arithmetic. -/

theorem boss (a b : ℕ) (h : a = b + 2) : ∃ c, a = c + 1 ∧ 0 < c := by
  sorry

end Q00

/-
  That's the toolkit. Every later quest adds a few moves of its own and lists
  them in its header, and docs/CHEATSHEET.md has them all on one page.

  Done? Commit, push, and add a first entry to your log.md: what felt natural,
  what felt weird?

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
