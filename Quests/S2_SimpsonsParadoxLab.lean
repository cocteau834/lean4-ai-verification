import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  STATISTICIAN'S PATH · S2 · SIMPSON'S PARADOX LAB  ⏱ ~45 min │
  └──────────────────────────────────────────────────────────────┘

  Kidney stones, 1986 (Charig et al., BMJ). Two treatments:
    A = open surgery,  B = percutaneous nephrolithotomy.

               small stones        large stones        ALL patients
    A        81/87   = 93%       192/263 = 73%       273/350 = 78%
    B       234/270  = 87%        55/80  = 69%       289/350 = 83%

  A wins for small stones. A wins for large stones. B wins overall.

  This is not a rounding trick. In this lab you will:
    1. make Lean certify the real data,
    2. BUILD your own paradox from scratch,
    3. prove when the paradox is impossible, and
    4. prove the identity that explains why it happens.
-/

namespace S2

/-- A treatment arm: `wins` successes out of `n` patients. -/
structure Arm where
  wins : ℕ
  n : ℕ
deriving Repr

/-- Success rate as a rational number. -/
def Arm.rate (a : Arm) : ℚ := a.wins / a.n

/-- Pool two subgroups into one. -/
def Arm.pool (a b : Arm) : Arm := ⟨a.wins + b.wins, a.n + b.n⟩

/-- Simpson's paradox: A beats B in BOTH subgroups, yet loses after pooling. -/
def Simpson (aSmall aLarge bSmall bLarge : Arm) : Prop :=
  bSmall.rate < aSmall.rate ∧
  bLarge.rate < aLarge.rate ∧
  (aSmall.pool aLarge).rate < (bSmall.pool bLarge).rate

#eval (Arm.rate ⟨81, 87⟩, Arm.rate ⟨234, 270⟩)

/-! ## Lab 1 · Certify the real data -/

theorem kidney_stones : Simpson ⟨81, 87⟩ ⟨192, 263⟩ ⟨234, 270⟩ ⟨55, 80⟩ := by
  sorry

/-! ## Lab 2 · Build your own paradox

✏️ Change these four arms so that `my_paradox` becomes TRUE, then prove it.
Use `#eval` to test candidate numbers fast.

Sibling challenge: who can build a paradox with the FEWEST total patients?
Put your total in your log. -/

def myASmall : Arm := ⟨1, 1⟩   -- ✏️
def myALarge : Arm := ⟨1, 1⟩   -- ✏️
def myBSmall : Arm := ⟨1, 1⟩   -- ✏️
def myBLarge : Arm := ⟨1, 1⟩   -- ✏️

#eval (myASmall.rate, myBSmall.rate, myALarge.rate, myBLarge.rate,
       (myASmall.pool myALarge).rate, (myBSmall.pool myBLarge).rate)

theorem my_paradox : Simpson myASmall myALarge myBSmall myBLarge := by
  sorry

/- 🧑‍🔬 ON THE JOB · Aggregation can lie
   Compare two AI provers on benchmarks with different mixes of easy and
   hard problems, and model A can win every difficulty bucket yet lose
   overall. Good evaluation reports stratified results. Statisticians who
   catch this are worth their weight in GPUs.
-/

/-! ## Lab 3 · When the paradox CAN'T happen

If both treatments get the same number of patients in each subgroup (a
balanced design, which randomization buys you), the paradox disappears.
Here everything is a rational number and `n₁`, `n₂` are the group sizes. -/

theorem balanced_no_paradox (a₁ a₂ b₁ b₂ n₁ n₂ : ℚ) (hn₁ : 0 < n₁) (hn₂ : 0 < n₂)
    (h₁ : b₁ / n₁ < a₁ / n₁) (h₂ : b₂ / n₂ < a₂ / n₂) :
    (b₁ + b₂) / (n₁ + n₂) < (a₁ + a₂) / (n₁ + n₂) := by
  sorry

/-! ## 🐉 BOSS · Why it happens

The pooled rate is a WEIGHTED AVERAGE of the subgroup rates, and the weights
are the group sizes. A treated mostly large (hard) stones, so A's pooled rate
is dragged toward its large-stone rate. Prove the identity. -/

theorem pooled_is_weighted_average (a₁ a₂ n₁ n₂ : ℚ) (hn₁ : 0 < n₁) (hn₂ : 0 < n₂) :
    (a₁ + a₂) / (n₁ + n₂) =
      (n₁ / (n₁ + n₂)) * (a₁ / n₁) + (n₂ / (n₁ + n₂)) * (a₂ / n₂) := by
  sorry

end S2

/-
  Log idea: where have you seen confounding like this in a real dataset or a
  class? How would you explain the paradox to someone in two sentences?

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
