import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  QUEST 04 · THE ORACLE LIES                     ⏱ 45–60 min │
  └──────────────────────────────────────────────────────────────┘

  The Oracle is a large language model. It is fluent, fast, and confident.
  It made the nine claims below. Some are true. Some are false, and several
  of those fooled famous mathematicians for a while.

  For each claim:
    • TRUE?  Keep the statement `claimN` and prove it.
    • FALSE? Change the statement to `¬ claimN` and prove THAT.
  Either way, Lean is the judge. You cannot fake it in either direction.

  Disproof pattern for a false "for all" claim:
      unfold claimN          -- see what the claim says
      intro h                -- suppose it were true...
      have h40 := h 40       -- ...then it would hold for 40 in particular
      norm_num at h40        -- ...but it doesn't. Contradiction!

  Library pattern: Mathlib holds about 250,000 theorems. If a claim is a famous
  fact, type `exact?` and Lean will search for it. That is how AI provers work
  too: they search the library constantly.
-/

namespace Q04

/-- Claim 1 · "n² + n + 41 is prime for every natural number n."
(Euler noticed it works for n = 0, 1, 2, ..., a long way. Try some `#eval`s!) -/
def claim1 : Prop := ∀ n : ℕ, Nat.Prime (n ^ 2 + n + 41)

#eval (List.range 12).map (fun n => n ^ 2 + n + 41)

theorem verdict1 : claim1 := by
  sorry

/-- Claim 2 · "Every number of the form 2^(2^n) + 1 is prime."
(Fermat believed this in 1640. They are prime for n = 0, 1, 2, 3, 4...) -/
def claim2 : Prop := ∀ n : ℕ, Nat.Prime (2 ^ (2 ^ n) + 1)

theorem verdict2 : claim2 := by
  sorry

/-- Claim 3 · "1 + 2 + 3 + ... + 100 = 5050." -/
def claim3 : Prop := ∑ i ∈ Finset.range 101, i = 5050

theorem verdict3 : claim3 := by
  sorry

/-- Claim 4 · "2^n ≥ n² for every natural number n." -/
def claim4 : Prop := ∀ n : ℕ, 2 ^ n ≥ n ^ 2

#eval (List.range 8).map (fun n => (n, 2 ^ n, n ^ 2))

theorem verdict4 : claim4 := by
  sorry

/-- Claim 5 · "There is no largest prime: above every number there is a prime." -/
def claim5 : Prop := ∀ n : ℕ, ∃ p, n ≤ p ∧ Nat.Prime p

theorem verdict5 : claim5 := by
  sorry

/-- Claim 6 · "Squaring never makes a real number smaller: x² ≥ x." -/
def claim6 : Prop := ∀ x : ℝ, x ^ 2 ≥ x

theorem verdict6 : claim6 := by
  sorry

/-- Claim 7 · "For all real a and b: a² + b² ≥ 2ab." -/
def claim7 : Prop := ∀ a b : ℝ, a ^ 2 + b ^ 2 ≥ 2 * a * b

theorem verdict7 : claim7 := by
  sorry

/-- Claim 8 · "The average of a (nonempty) list is always one of its elements."
(A statistician should smell this one immediately.) -/
def claim8 : Prop := ∀ l : List ℚ, l ≠ [] → l.sum / l.length ∈ l

theorem verdict8 : claim8 := by
  sorry

/-- Claim 9 · "√2 is irrational." -/
def claim9 : Prop := Irrational (Real.sqrt 2)

theorem verdict9 : claim9 := by
  sorry

/- 🧑‍🔬 ON THE JOB · Claim, check, revise
   You've just scored an AI on nine claims. Evaluation teams do this at
   scale: how often do a model's claims survive checking, and does its
   confidence track its accuracy ("calibration")? Counterexamples are the
   cheapest, most decisive evidence there is.
-/

/-! ## 🐉 BOSS · The Oracle revises its answer

Caught out on Claim 4, the Oracle says: "Fine. 2^n ≥ n² for every n ≥ 4."
Is it right this time? (It is.) This one needs induction that starts at 4:

    induction n, hn using Nat.le_induction with
    | base => ...                 -- the case n = 4
    | succ k hk ih => ...         -- hk : 4 ≤ k,  ih : k^2 ≤ 2^k

`nlinarith` is `linarith` that also multiplies hypotheses together, which
you need for squares. -/

theorem boss (n : ℕ) (hn : 4 ≤ n) : n ^ 2 ≤ 2 ^ n := by
  sorry

end Q04

/-
  Log idea: before proving each claim, write down your gut call (true or false).
  How often was your intuition right? Paste a claim into an AI chatbot and ask
  it. How often was IT right?

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
