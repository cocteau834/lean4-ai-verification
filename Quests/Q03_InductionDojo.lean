import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  QUEST 03 · INDUCTION DOJO                      ⏱ 30–45 min │
  └──────────────────────────────────────────────────────────────┘

  "For EVERY n" needs induction:
    • base case: prove it for the smallest case;
    • step: if it holds for k, prove it for the next one.

  Induction works on numbers (0, 1, 2, ...) and just as well on LISTS:
  prove it for the empty list `[]`, then show that if it holds for `xs` it
  holds for `x :: xs` (x stuck on the front). That second kind is how
  programs get verified, because most code is recursion over data.

      induction n with                     induction xs with
      | zero => ...                        | nil => ...
      | succ k ih => ...                   | cons x xs ih => ...

  Useful moves:
    simp only [f]               unfold the definition of your function f
    rw [Finset.sum_range_succ]  peel the last term off a sum
    ring                        any algebra identity
    omega                       whole-number arithmetic
    linarith                    linear inequalities from your hypotheses
-/

open Finset

namespace Q03

/-! ## Worked example · Gauss's trick (induction on numbers)

Legend says young Gauss added 1 + 2 + ... + 100 in seconds. We prove the
general formula, doubled so there's no division. Click through every line. -/

theorem gauss (n : ℕ) : 2 * (∑ i ∈ range (n + 1), i) = n * (n + 1) := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [sum_range_succ, mul_add, ih]
    ring

#eval ∑ i ∈ range 101, i    -- Gauss's answer

/-! ## Induction on lists: verifying small programs

Here are four tiny programs, written from scratch so that nothing is hidden
in the library. Run them, then prove things about them. -/

/-- The length of a list. -/
def len : List ℕ → ℕ
  | [] => 0
  | _ :: xs => len xs + 1

/-- Glue two lists together. -/
def app : List ℕ → List ℕ → List ℕ
  | [], ys => ys
  | x :: xs, ys => x :: app xs ys

/-- Reverse a list. -/
def rev : List ℕ → List ℕ
  | [] => []
  | x :: xs => app (rev xs) [x]

/-- Double every element, and add up a list. -/
def doubleAll : List ℕ → List ℕ
  | [] => []
  | x :: xs => 2 * x :: doubleAll xs

def total : List ℕ → ℕ
  | [] => 0
  | x :: xs => x + total xs

#eval (app [1, 2] [3, 4], rev [1, 2, 3], doubleAll [1, 2, 3], total [1, 2, 3])

/-- Worked example: the empty case of the first kata, so you can see the moves. -/
example (ys : List ℕ) : len (app [] ys) = len [] + len ys := by
  simp only [app, len]    -- unfold both definitions on []
  omega                   -- len ys = 0 + len ys

/-! ## Your turn -/

/-- Kata 1 · Gluing lists adds their lengths. (Induction on xs.) -/
theorem len_app (xs ys : List ℕ) : len (app xs ys) = len xs + len ys := by
  sorry

/-- Kata 2 · Doubling every element doubles the total. -/
theorem total_doubleAll (xs : List ℕ) : total (doubleAll xs) = 2 * total xs := by
  sorry

/-- Kata 3 · Reversing keeps the length. (Kata 1 is a useful lemma here.
Using earlier theorems is exactly how big verified programs are built.) -/
theorem len_rev (xs : List ℕ) : len (rev xs) = len xs := by
  sorry

/-- Kata 4 · Back to numbers: powers of two grow fast. -/
theorem two_pow_ge (n : ℕ) : n + 1 ≤ 2 ^ n := by
  sorry

/- 🧑‍🔬 ON THE JOB · This is how software gets verified
   A recursive function plus an induction proof about it: that pattern is
   how people verify compilers, protocols and authorization engines (AWS's
   Cedar is verified in Lean). It's also the pattern AI provers most often
   get *almost* right.
-/

/-! ## 🐉 BOSS · The Tower of Hanoi

To move `n + 1` discs: move `n` discs out of the way, move the big disc,
then move the `n` discs back on top. So the move count satisfies: -/

def hanoi : ℕ → ℕ
  | 0 => 0
  | n + 1 => 2 * hanoi n + 1

#eval hanoi 10
#eval (List.range 11).map hanoi    -- spot the pattern?

/-- BOSS · Prove the closed form you spotted. (The legend: monks moving 64
golden discs end the world when they finish. Try `#eval hanoi 64`.) -/
theorem hanoi_formula (n : ℕ) : hanoi n + 1 = 2 ^ n := by
  sorry

end Q03

/-
  Log idea: which kata felt most like the proof you'd write on paper, and
  which felt most like arguing with a computer?

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
