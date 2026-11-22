import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  MACHINE WHISPERER'S PATH · A2 · NEURAL NET SAFETY CHECK     │
  │                                                 ⏱ 45–60 min │
  └──────────────────────────────────────────────────────────────┘

  A self-driving car's network sees a stop sign. Someone puts a few stickers
  on it, a tiny change to the input, and the network now says "speed limit".
  That's an ADVERSARIAL EXAMPLE, and it's one of the central problems in AI
  safety.

  Testing can't rule them out, because there are infinitely many nearby inputs.
  A PROOF can: "for EVERY input within ε of this one, the answer doesn't
  change." That is a robustness certificate, and it's what neural-network
  verifiers produce (look up VNN-COMP, α,β-CROWN and Marabou).

  You'll build one by hand for a tiny network. We use rational numbers ℚ so
  you can also RUN the network with `#eval`.
-/

namespace A2

/-- The ReLU activation: the most common nonlinearity in deep learning. -/
def relu (x : ℚ) : ℚ := max x 0

#eval (relu (-3), relu 0, relu (5 / 2))

/-! ## Part 1 · Know your activation function -/

/-- 1 · ReLU never goes negative. -/
theorem relu_nonneg (x : ℚ) : 0 ≤ relu x := by
  sorry

/-- 2 · On nonnegative inputs ReLU does nothing. -/
theorem relu_of_nonneg {x : ℚ} (h : 0 ≤ x) : relu x = x := by
  sorry

/-- 3 · On nonpositive inputs ReLU outputs 0. -/
theorem relu_of_nonpos {x : ℚ} (h : x ≤ 0) : relu x = 0 := by
  sorry

/-- 4 · ReLU is monotone. (This is what makes "interval bound propagation" work:
push an interval [lo, hi] through ReLU and you get [relu lo, relu hi].) -/
theorem relu_mono {x y : ℚ} (h : x ≤ y) : relu x ≤ relu y := by
  sorry

/-- 5 · A cute identity: x = ReLU(x) − ReLU(−x). -/
theorem relu_sub_relu_neg (x : ℚ) : relu x - relu (-x) = x := by
  sorry

/-- 6 · ReLU is 1-Lipschitz: it never amplifies a perturbation. This is the
property robustness proofs lean on. -/
theorem relu_lipschitz (x y : ℚ) : |relu x - relu y| ≤ |x - y| := by
  sorry

/- 🧑‍🔬 ON THE JOB · Know what your guarantee covers
   The certificate below covers ONE box around ONE input. Not stickers in
   general, not lighting, not a different stop sign. Being precise about the
   scope of a guarantee is the core skill in "guaranteed-safe AI" debates.
-/

/-! ## Part 2 · 🐉 BOSS · Certify a classifier

A "trained" network: 2 inputs, 2 hidden ReLU neurons, 1 output score.
score > 0 means CAT 🐱, score ≤ 0 means NOT CAT. -/

def score (x₁ x₂ : ℚ) : ℚ := relu (2 * x₁ + x₂ - 1) - relu (x₁ - 3 * x₂)

#eval score 1 1          -- the clean image: a cat
#eval score 0.95 1.05    -- a slightly perturbed image

/-- 7 · BOSS (robustness certificate): EVERY input within 1/10 of (1, 1) is a cat.
That's infinitely many inputs, handled by one proof. -/
theorem robust_cat (x₁ x₂ : ℚ) (h₁ : |x₁ - 1| ≤ 1 / 10) (h₂ : |x₂ - 1| ≤ 1 / 10) :
    0 < score x₁ x₂ := by
  sorry

/-- 8 · BOSS (the attack): with a budget of 1 instead of 1/10, an attacker CAN
flip the label. Find an adversarial example with `#eval`, then prove it works. -/
theorem attack_exists : ∃ x₁ x₂ : ℚ, |x₁ - 1| ≤ 1 ∧ |x₂ - 1| ≤ 1 ∧ score x₁ x₂ ≤ 0 := by
  sorry

end A2

/-
  Log idea: between 1/10 (certified safe) and 1 (attack found) there's a
  threshold. Can you find the largest ε you can certify? That's exactly the
  number real verifiers report. (Ask the Game Master for the sequel side quest.)

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
