import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  QUEST 05 · THE RH AUDIT                        ⏱ 45–60 min │
  └──────────────────────────────────────────────────────────────┘

  November 20, 2026. Levent Alpöge, a mathematician at Anthropic, released
  about 17 million lines of Lean, written with Claude, which claim to prove
  the Riemann Hypothesis. It is the most famous open problem in mathematics,
  open since 1859.

  Nobody can read 17 million lines. Yet within a day, the Lean and Mathlib
  communities put out a joint statement: the proof is correct. How can anyone
  be that confident? They asked three questions:

    1. Does it COMPILE? Lean's kernel, a small and carefully audited program,
       re-checks every step. Independent checkers written in other
       languages checked it again.
    2. Which AXIOMS does it use? A proof can smuggle in assumptions. Lean
       reports them: `#print axioms foo`. The only acceptable ones are
       `propext`, `Classical.choice` and `Quot.sound`.
    3. Is the STATEMENT really RH? A perfect proof of the wrong statement is
       worthless. They checked that the proved theorem is literally the
       `RiemannHypothesis` already written in Mathlib, using two
       independent tools.

  Mathematicians point out that a checked proof is not yet an understood one.
  Still, nobody has to take the author's word, or an AI's word, for whether it
  is correct. That is the whole point.

  In this quest YOU are the auditor.
-/

namespace Q05

/-! ## Part 1 · Five submissions arrive at the auditor's desk

Click on each `#print axioms` line and read the Infoview. -/

namespace Suspects

/-- Submission A · "A proof that 1 = 2." Lean accepts it without complaint... -/
axiom trust_me : (1 : ℕ) = 2
theorem one_eq_two : (1 : ℕ) = 2 := trust_me

#print axioms one_eq_two

/-- Submission B · "The Riemann Hypothesis in one line." -/
theorem rh_easy (h : (0 : ℕ) = 1) : RiemannHypothesis := absurd h (by norm_num)

#print axioms rh_easy

/-- Submission C · "A big computation, checked instantly." -/
theorem big_check : 2 ^ 64 % 7 = 2 := by native_decide

#print axioms big_check

/-- Submission D · "The product of two consecutive numbers is even." -/
theorem consecutive_even (n : ℕ) : Even (n * (n + 1)) := Nat.even_mul_succ_self n

#print axioms consecutive_even

/-- Submission E · "Goldbach's conjecture: every even number is a sum of two primes." -/
theorem goldbach : ∀ n : ℕ, Even n → ∃ p q : ℕ, p + q = n := by
  intro n _
  exact ⟨n, 0, by simp⟩

#print axioms goldbach

end Suspects

/- 🧑‍🔬 ON THE JOB · Reward hacking
   An AI rewarded for "Lean accepts it" will find every gap you just saw:
   smuggled axioms, native_decide, impossible hypotheses, a quietly weakened
   statement. Defending against that (axiom audits, independent checkers,
   statement comparison) is alignment work in miniature.
-/

/-! ## Part 2 · Your verdicts

TRUSTWORTHY means all three of:
  (1) Lean's kernel checked it,
  (2) it uses only `propext`, `Classical.choice` and `Quot.sound`, and
  (3) the statement really says what the title claims.

✏️ Set each verdict (true = trustworthy). The theorem below checks your
answers against a fingerprint, so you can't just read the answer off.
(If you brute-force the fingerprint with `#eval`, you'll have learned
something about why real systems use cryptographic hashes.) -/

def verdicts : List Bool := [true, true, true, true, true]   -- ✏️ A, B, C, D, E

def fingerprint (v : List Bool) : ℕ :=
  v.foldl (fun acc b => 3 * acc + if b then 2 else 1) 0

/-- Audit 1 · Get all five verdicts right, then prove this. -/
theorem audit_passed : fingerprint verdicts = 124 := by
  sorry

/-! ## Part 3 · Do it properly

An auditor doesn't just reject. They show what an honest version looks like. -/

/-- Audit 2 · Submission E dropped the word "prime". Prove an honest
instance of Goldbach: 28 really is a sum of two primes. -/
theorem goldbach_28 : ∃ p q : ℕ, p.Prime ∧ q.Prime ∧ p + q = 28 := by
  sorry

/-- Audit 3 · Redo Submission C so that the kernel itself checks it
(no `native_decide`). Then add `#print axioms big_check_honest` below and compare. -/
theorem big_check_honest : 2 ^ 64 % 7 = 2 := by
  sorry

/-- Audit 4 · Expose Submission B: its hypothesis can never be satisfied.
A theorem with an impossible hypothesis is "vacuously true" and says nothing. -/
theorem b_is_vacuous : ¬ ((0 : ℕ) = 1) := by
  sorry

/- 🧑‍🔬 ON THE JOB · Red-team your own grader (the Break the Expedition bounty)
   The Expedition engine has a deliberate blind spot: it checks that every
   puzzle's theorem still exists and that Lean accepts your file, but it
   never checks that you left each STATEMENT alone. See the exploit? Don't
   use it here (Quest 07 lets you try it legally); describe it in your log. Finding holes in a grader before an AI
   does is called red-teaming, and it's paid work in AI safety. Any other
   hole you find in the Expedition counts too.
-/

/-! ## Part 4 · Meet the zeta function

Look at the real thing: -/

#check RiemannHypothesis
#print RiemannHypothesis
#check riemannZeta

/-
  In words: every zero `s` of ζ, except the "trivial zeros" −2, −4, −6, ...
  (and except s = 1, where ζ isn't really defined), has real part exactly 1/2.
-/

/-- Audit 5 · The Basel problem (Euler, 1734): ζ(2) = 1 + 1/4 + 1/9 + ... = π²/6.
Mathlib already knows it. Find it. -/
theorem basel : riemannZeta 2 = (Real.pi : ℂ) ^ 2 / 6 := by
  sorry

/-- Audit 6 · ζ(−2) = 0. This is the first "trivial zero". -/
theorem zeta_neg_two : riemannZeta (-2) = 0 := by
  sorry

/-- 🐉 BOSS · Why the fine print matters. State RH naively, as "every zero of ζ
has real part 1/2", and you get a FALSE statement. Prove that it's false.
This is exactly why statement-checking (question 3) is part of every audit. -/
theorem naive_rh_is_false : ¬ (∀ s : ℂ, riemannZeta s = 0 → s.re = 1 / 2) := by
  sorry

end Q05

/-
  Log idea: if you had to convince a skeptical friend that a 17-million-line
  AI-written proof is right, what would you say? And what would still bother you?

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
