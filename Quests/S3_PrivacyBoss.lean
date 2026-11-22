import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  STATISTICIAN'S PATH · S3 · PRIVACY BOSS          ⏱ ~60 min │
  │              Randomized response & differential privacy      │
  └──────────────────────────────────────────────────────────────┘

  The survey question: "Have you ever cheated on an exam?"
  Nobody answers that honestly unless they have DENIABILITY.

  Randomized response (Warner, 1965). Flip a fair coin, in private.
    • Heads: answer truthfully.
    • Tails: flip again, and say "yes" on heads and "no" on tails,
      whatever the truth is.

  Any single "yes" might just be the coins talking, yet the surveyor can still
  estimate the true rate. This is the simplest example of DIFFERENTIAL
  PRIVACY, the guarantee used by the US Census (2020), Apple, and Google.
  AWS has gone further and proved its privacy code correct IN LEAN: their
  SampCert library is a formally verified sampler for differential privacy.

  You will prove the privacy guarantee yourself, and then prove that the
  surveyor's estimator is unbiased.
-/

namespace S3

inductive Coin | H | T
  deriving DecidableEq, Repr

/-- The four equally likely outcomes of two fair coin flips. -/
def flips : List (Coin × Coin) := [(.H, .H), (.H, .T), (.T, .H), (.T, .T)]

/-- What a respondent says, given the truth and the two flips. -/
def respond (truth : Bool) : Coin × Coin → Bool
  | (.H, _) => truth
  | (.T, .H) => true
  | (.T, .T) => false

/-- In how many of the 4 flip outcomes does a person whose truth is `truth` say `out`? -/
def count (out truth : Bool) : ℕ := (flips.filter (fun c => respond truth c == out)).length

/-- P(say `out` | truth is `truth`). -/
def P (out truth : Bool) : ℚ := count out truth / 4

#eval [(count true true), (count true false), (count false true), (count false false)]

/-! ## Part 1 · The channel -/

/-- 1 · A true "yes" gets reported as "yes" in 3 of 4 outcomes. -/
theorem count_yes_yes : count true true = 3 := by
  sorry

/-- 2 · A true "no" still gets reported as "yes" in 1 of 4. -/
theorem count_yes_no : count true false = 1 := by
  sorry

-- The other two counts, for free:
theorem count_no_yes : count false true = 1 := by decide
theorem count_no_no : count false false = 3 := by decide

/-- 3 · As a probability. -/
theorem P_yes_yes : P true true = 3 / 4 := by
  sorry

/-- 4 · And the other one. -/
theorem P_yes_no : P true false = 1 / 4 := by
  sorry

/- 🧑‍🔬 ON THE JOB · The math and the code
   You're about to prove that the *math* is private. AWS's SampCert proves
   the *code that runs* is too, in Lean. The gap between "the math is right"
   and "the deployed system is right" is where verification careers live.
-/

/-! ## Part 2 · The privacy guarantee

ε-differential privacy says: whatever the output, changing one person's truth
changes its probability by at most a factor of e^ε. Here the factor is 3, so
ε = ln 3 ≈ 1.1. Anyone who sees your answer learns at most "3× more likely". -/

/-- 5 · Prove it for every output and every pair of truths (8 cases). -/
theorem rr_is_private : ∀ out truth truth' : Bool, P out truth ≤ 3 * P out truth' := by
  sorry

/-! ## Part 3 · The surveyor can still do statistics

If a fraction `p` of the population really cheated, the expected fraction of
"yes" answers is: -/

def expectedYes (p : ℚ) : ℚ := p * (3 / 4) + (1 - p) * (1 / 4)

/-- The surveyor sees a "yes" rate `y` and estimates the true rate as 2y − 1/2. -/
def estimate (y : ℚ) : ℚ := 2 * y - 1 / 2

/-- 6 · Unbiased: on average, the estimate recovers the truth exactly. -/
theorem unbiased (p : ℚ) : estimate (expectedYes p) = p := by
  sorry

/-! ## 🐉 BOSS · The privacy–accuracy dial

Generalize: tell the truth with probability `t` (instead of 1/2); otherwise
answer by a fair coin. Then P(yes | yes) = t + (1−t)/2 and P(yes | no) = (1−t)/2.
Their ratio is the privacy factor e^ε. -/

def privacyFactor (t : ℚ) : ℚ := (t + (1 - t) / 2) / ((1 - t) / 2)

/-- 7 · A cleaner formula for it. -/
theorem privacyFactor_eq (t : ℚ) (ht : t < 1) : privacyFactor t = (1 + t) / (1 - t) := by
  sorry

/-- 8 · BOSS · More truth means LESS privacy: the factor strictly increases with t.
(That's the fundamental trade-off of differential privacy, in one line.) -/
theorem more_truth_less_privacy (s t : ℚ) (hs : 0 ≤ s) (hst : s < t) (ht : t < 1) :
    privacyFactor s < privacyFactor t := by
  sorry

end S3

/-
  Log idea: with t = 1/2 we get factor 3. What t gives factor 2? How many more
  survey responses would you need for the same accuracy? (That's a variance
  question. Bonus side quest if you want it: ask the Game Master.)

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
