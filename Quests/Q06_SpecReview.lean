import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  QUEST 06 · SPEC REVIEW: THE MISFORMALIZATION HUNT  ⏱ ~45 min│
  └──────────────────────────────────────────────────────────────┘

  An AI assistant has written eight formal statements: four translated from
  math problems, and four SPECS for code it wrote (an access rule, a sort, a
  max function and a bank check). Before any of them is trusted, someone
  has to review them. Today that's you.

  For each item, compare the ENGLISH with the LEAN and decide:
    FAITHFUL  the Lean says exactly what the English says, or
    BROKEN    it says something different, even if it looks almost right
              and even if it happens to be true.

  You don't need to prove anything to judge. You need to READ like Lean
  reads. The usual suspects:

    • natural-number subtraction stops at 0:       (0 : ℕ) - 1 = 0
    • division by zero is defined as 0 in Lean:    (5 : ℝ) / 0 = 0
    • a spec that's too WEAK: true, but a wrong implementation would pass
      it too ("sorted" without "same elements"; "or" where "and" was meant)
    • ranges: Finset.range n is {0, 1, ..., n - 1}, so it stops BEFORE n
    • a hypothesis that got dropped, or one that can never be true

  Moves you'll use: unfold, intro, `have := h 0` (test a case), omega,
  norm_num, decide, linarith, nlinarith, rintro, ⟨ ⟩, and `#eval`.

  Stuck? `python3 scripts/expedition.py hint review_passed` (or any puzzle).
-/

namespace Q06

/-! ## A worked example of a review

English:  "Every natural number below 10 is at most 9."
Lean:     ∀ n : ℕ, n ≤ 10 → n ≤ 9

BROKEN: "below 10" became `≤ 10`, which lets n = 10 in. Evidence: the Lean
version is false at n = 10, so it can't mean what the true English means. -/

theorem evidence_example : ¬ (∀ n : ℕ, n ≤ 10 → n ≤ 9) := by
  intro h
  have h10 := h 10 (le_refl 10)    -- plug in the suspicious case
  omega                            -- 10 ≤ 9 is absurd

/-! ## The code the AI wrote

Four of the items are specs for these functions. `#eval` them! -/

/-- Access control: may this user delete this file? -/
def allow (admin locked : Bool) : Bool := admin && !locked

/-- Sorting (the AI used the library's merge sort). -/
def sortAI (l : List ℕ) : List ℕ := l.mergeSort

/-- The largest element of a list (0 for the empty list). -/
def maxAI (l : List ℕ) : ℕ := l.foldr max 0

/-- A bank's withdrawal check. -/
def approve (balance amount : ℕ) : Bool := decide (amount ≤ balance)

#eval (allow true false, allow false false, sortAI [3, 1, 2], maxAI [4, 9, 2], approve 50 80)

/-! ## The eight items -/

/-- A · English: "For every natural number n, n² ≥ n." -/
def itemA : Prop := ∀ n : ℕ, n ^ 2 ≥ n

/-- The AI's spec for access control, stated for any policy function `f`. -/
def AllowSpecAI (f : Bool → Bool → Bool) : Prop :=
  ∀ admin locked : Bool, f admin locked = true → admin = true ∨ locked = false

/-- B · English: "`allow` permits a deletion only if the user is an admin AND
the file is not locked." -/
def itemB : Prop := AllowSpecAI allow

/-- C · English: "If n is a natural number with n ≥ 1, then n − 1 < n." -/
def itemC : Prop := ∀ n : ℕ, n - 1 < n

/-- D · English: "`sortAI` returns the list in increasing order, with exactly
the same elements." (`Pairwise (· ≤ ·)` means "each element is ≤ every later one".) -/
def itemD : Prop := ∀ l : List ℕ, (sortAI l).Pairwise (· ≤ ·)

/-- E · English: "For a nonempty list, `maxAI` returns an element of the list
that is at least as big as every element." -/
def itemE : Prop := ∀ l : List ℕ, l ≠ [] → maxAI l ∈ l ∧ ∀ x ∈ l, x ≤ maxAI l

/-- F · English: "The sum of the first n odd numbers, 1 + 3 + ... + (2n − 1), is n²." -/
def itemF : Prop := ∀ n : ℕ, ∑ i ∈ Finset.range n, (2 * i + 1) = n ^ 2

/-- G · English: "For every positive real number x, x / x = 1." -/
def itemG : Prop := ∀ x : ℝ, x / x = 1

/-- H · English: "`approve` only approves a withdrawal when the amount is at
most the balance." -/
def itemH : Prop := ∀ balance amount : ℕ, approve balance amount = true → amount ≤ balance

#eval ((0 : ℕ) - 1, (7 : ℕ) - 9, (1 : ℚ) / 0)

/-! ## Part 1 · Your verdicts

✏️ One Bool per item, in order A to H (true = FAITHFUL). As in the RH Audit,
a fingerprint checks your answers without giving them away. -/

def verdicts : List Bool := [true, true, true, true, true, true, true, true]   -- ✏️ A … H

def fingerprint (v : List Bool) : ℕ :=
  v.foldl (fun acc b => 3 * acc + if b then 2 else 1) 0

/-- Review 1 · Get all eight verdicts right, then prove this. -/
theorem review_passed : fingerprint verdicts = 5504 := by
  sorry

/- 🧑‍🔬 ON THE JOB · Statement review is the job
   Companies that train AI provers pay people to read AI-generated formal
   statements and reject the ones that drift from the source. And as AI
   writes more code, the same review moves to SPECS: if an AI writes the
   code, the spec and the proof, the only thing left for a human to check is
   whether the spec says what was meant. A too-weak spec lets wrong code
   pass with a perfect proof.
-/

/-! ## Part 2 · Show the evidence

Exactly four items are BROKEN. For each one, prove a theorem that SHOWS the
problem. Pick whichever fits:
  • a counterexample: the Lean statement is false somewhere the English is true;
  • a loophole: a WRONG implementation that still satisfies the spec.

✏️ Replace `True` with your evidence statement, then prove it. Keep the
theorem names and say which item it's about in a comment. (Yes, you *could*
leave `True` and write `trivial`. The engine wouldn't notice, but the Game
Master reads statements. That gap is the whole point of Quest 07.) -/

/-- Evidence 1 -/
theorem evidence1 : True := by
  sorry

/-- Evidence 2 -/
theorem evidence2 : True := by
  sorry

/-- Evidence 3 -/
theorem evidence3 : True := by
  sorry

/-- Evidence 4 -/
theorem evidence4 : True := by
  sorry

/-! ## 🐉 BOSS · The proof that proves nothing

A ninth translation came back with a proof attached, and Lean accepts it.

English:  "If 2 < x < 3, then x² < 9."
Lean:     ∀ x : ℝ, 3 < x ∧ x < 2 → x ^ 2 < 9

Prove all three facts below. Together they show why "Lean accepted it"
and "it means what we wanted" are different claims. -/

/-- Boss 1 · The AI's version really is provable... -/
theorem ai_version_holds : ∀ x : ℝ, 3 < x ∧ x < 2 → x ^ 2 < 9 := by
  sorry

/-- Boss 2 · ...because its hypothesis can never be satisfied (it's vacuous). -/
theorem ai_hypothesis_impossible : ¬ ∃ x : ℝ, 3 < x ∧ x < 2 := by
  sorry

/-- Boss 3 · The faithful version, which actually says something. -/
theorem faithful_version : ∀ x : ℝ, 2 < x ∧ x < 3 → x ^ 2 < 9 := by
  sorry

end Q06

/-
  Log idea: which broken item fooled you longest, and what will you check
  first next time? (Real reviewers keep a personal checklist like that.)
  Bonus: write the FAITHFUL spec for item B or D in your log.

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
