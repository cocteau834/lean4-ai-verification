import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  TRAINING · T0 · PROOF GYM: PAPER → LEAN         ⏱ 30–45 min │
  └──────────────────────────────────────────────────────────────┘

  Proofs feel rusty? Start here. Every puzzle shows a proof the way you'd
  write it on paper (📜), then a Lean version (⌨️) with most of the work done.
  You finish the missing step. The boss is a blank page.

  The real skill is translation. Every paper move has a Lean move:

    On paper                              In Lean
    "Let n be arbitrary."                 intro n
    "Suppose P."                          intro hP
    "Write n = 2k for some k."            obtain ⟨k, hk⟩ := h        (unpack an ∃)
    "Take m = 5."                         use 5                      (prove an ∃)
    "Case 1 ... Case 2 ..."               rcases h with h1 | h2
    "Suppose not. Then ..."               intro h  (for a ¬ goal)    or  by_contra h
    "By induction on n."                  induction n with ...
    "a = b ≤ c = d"                       calc
    "Both directions."                    constructor                (for ↔)
    "By algebra."                         ring   /  linarith  /  nlinarith
    "By arithmetic."                      norm_num  /  omega  /  decide
    "By a known theorem."                 exact?                     (search Mathlib)

  Stuck? `python3 scripts/expedition.py hint even_sq` (or any puzzle name)
  gives one hint at a time.
-/

namespace T0

/-! ## 1 · Direct proof

📜 Claim. If n is even, then n² is even.
   Proof. Since n is even, n = k + k for some k. Then
   n² = (k + k)² = 2k² + 2k², which is even. ∎

In Mathlib, `Even n` means `∃ r, n = r + r`. -/

theorem even_sq (n : ℕ) (h : Even n) : Even (n ^ 2) := by
  obtain ⟨k, hk⟩ := h        -- "n = k + k for some k"
  use 2 * k ^ 2              -- "...is 2k² + 2k²": now show n ^ 2 = 2k² + 2k²
  sorry                      -- ✏️ the algebra (two tactics)

/-! ## 2 · Proof by contradiction

📜 Claim. There is no largest natural number.
   Proof. Suppose N were the largest. Then N + 1 ≤ N, which is absurd. ∎ -/

theorem no_largest : ¬ ∃ N : ℕ, ∀ m : ℕ, m ≤ N := by
  intro h                    -- "Suppose there were one..."
  obtain ⟨N, hN⟩ := h        -- "...call it N."
  have h1 := hN (N + 1)      -- "Then N + 1 ≤ N."
  sorry                      -- ✏️ "which is absurd": one arithmetic tactic

/-! ## 3 · Proof by cases

📜 Claim. n(n + 1) is always even.
   Proof. If n is even, then n(n + 1) is even, since an even number times
   anything is even. If n is odd, then n + 1 is even, and again the product
   is even. ∎ -/

theorem consecutive (n : ℕ) : Even (n * (n + 1)) := by
  rcases Nat.even_or_odd n with h | h
  · -- Case 1: n is even, so (even) * (anything) is even.
    exact h.mul_right (n + 1)
  · -- Case 2: n is odd, so n + 1 is even.
    have h' : Even (n + 1) := h.add_one
    sorry                    -- ✏️ mirror case 1; this time the even factor is on the right

/-! ## 4 · Induction

📜 Claim. 0 + 2 + 4 + ... + 2n = n(n + 1).
   Proof by induction on n.
   Base: for n = 0 both sides are 0.
   Step: if the sum up to 2k is k(k + 1), then the sum up to 2(k + 1) is
   k(k + 1) + 2(k + 1) = (k + 1)(k + 2). ∎ -/

open Finset in
theorem sum_evens (n : ℕ) : ∑ i ∈ range (n + 1), 2 * i = n * (n + 1) := by
  induction n with
  | zero => simp                       -- base case
  | succ k ih =>
    rw [sum_range_succ, ih]            -- "k(k + 1) + 2(k + 1)"
    sorry                              -- ✏️ "= (k + 1)(k + 2)": pure algebra

/-! ## 5 · "For every ..., there exists ..."

📜 Claim. Above every natural number there is an even number.
   Proof. Let n be given. Take m = 2n + 2. Then n < m, and
   m = (n + 1) + (n + 1) is even. ∎ -/

theorem even_above : ∀ n : ℕ, ∃ m, n < m ∧ Even m := by
  intro n                    -- "Let n be given."
  use 2 * n + 2              -- "Take m = 2n + 2."
  constructor
  · omega                    -- "n < m"
  · sorry                    -- ✏️ "m = (n + 1) + (n + 1)": Even needs a witness r with m = r + r

/-! ## 6 · A chain of (in)equalities: `calc`

📜 Claim. If 0 ≤ a ≤ b, then a² ≤ b².
   Proof. a² = a·a ≤ b·b = b². (Multiplying a ≤ b by itself is fine
   because everything is nonnegative.) ∎ -/

theorem square_mono (a b : ℝ) (ha : 0 ≤ a) (hab : a ≤ b) : a ^ 2 ≤ b ^ 2 := by
  calc a ^ 2 = a * a := by ring
    _ ≤ b * b := by sorry              -- ✏️ the one real step
    _ = b ^ 2 := by ring

/-! ## 7 · "If and only if"

📜 Claim. For a real number x, x² = 0 exactly when x = 0.
   Proof. (→) A nonzero number has a nonzero square, so x² = 0 forces x = 0.
          (←) If x = 0, then x² = 0² = 0. ∎ -/

theorem sq_zero_iff (x : ℝ) : x ^ 2 = 0 ↔ x = 0 := by
  constructor
  · intro h                  -- (→)
    sorry                    -- ✏️ one tactic or one library fact
  · intro h                  -- (←)
    rw [h]
    norm_num

/- 🧑‍🔬 ON THE JOB · Autoformalization
   What you're doing here, paper to Lean, is called formalization. Doing it
   with AI ("autoformalization") is one of the hottest research areas, and
   companies building AI provers hire people to write Lean and to CHECK the
   translations their AI systems produce.
-/

/-! ## 🐉 BOSS · A blank page

📜 Claim. If a divides b and b divides c, then a divides c.
   Proof. Write b = a·k and c = b·m. Then c = (a·k)·m = a·(k·m). ∎

No scaffolding: translate the paper proof line by line.
In Lean, `a ∣ b` means `∃ k, b = a * k`. (Type ∣ as `\|`; it is not the keyboard `|`.) -/

theorem dvd_chain (a b c : ℕ) (h₁ : a ∣ b) (h₂ : b ∣ c) : a ∣ c := by
  sorry

end T0

/-
  Log idea: which translation felt most natural, and which felt weirdest?
  (Most people find `obtain` and `use` strange for about a day, then can't
  live without them.)

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
