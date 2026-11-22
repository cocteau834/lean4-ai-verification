import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  MACHINE WHISPERER'S PATH · A1 · BUG BOUNTY       ⏱ ~45 min │
  └──────────────────────────────────────────────────────────────┘

  An AI coding assistant wrote the functions below and swore they were
  correct. Some are. Some aren't. Tests can only show that bugs exist; a
  proof shows that none do, for every input at once.

  Every function has a SPEC (what it should do). For each bounty:
    • spec true?  → prove it for ALL inputs;
    • spec false? → find a counterexample and prove the bug exists, then fix it.

  This is where "verified AI-generated code" is going: the AI writes the code
  AND the proof, and Lean checks the proof, so nobody has to trust the AI.

  Workflow tip: `#eval` first, prove second. Poke at the function until you
  believe something, then make Lean agree.
-/

namespace A1

/-! ## Bounty 1 · maxList -/

/-- AI-written: the largest element of a list (0 for the empty list). -/
def maxList : List ℕ → ℕ
  | [] => 0
  | x :: xs => max x (maxList xs)

#eval maxList [3, 1, 4, 1, 5, 9, 2, 6]

/-- Spec: every element is ≤ the maximum. (Induction on the list!) -/
theorem maxList_spec (l : List ℕ) : ∀ x ∈ l, x ≤ maxList l := by
  sorry

/-! ## Bounty 2 · the distance between two numbers -/

/-- AI-written: "the distance between a and b". -/
def gap (a b : ℕ) : ℕ := a - b

#eval gap 5 3
#eval gap 3 5      -- hmm. Natural-number subtraction stops at 0.

/-- The AI claimed `gap` is symmetric. Prove the AI WRONG. -/
theorem gap_bug : ∃ a b : ℕ, gap a b ≠ gap b a := by
  sorry

/-- ✏️ Fix it! Rewrite this definition so the theorem below becomes true.
(The current body is the buggy one. Hint: `if a ≤ b then ... else ...`.) -/
def gapFixed (a b : ℕ) : ℕ := a - b   -- ✏️ fix me

theorem gapFixed_symm (a b : ℕ) : gapFixed a b = gapFixed b a := by
  sorry

/- 🧑‍🔬 ON THE JOB · Verified code generation
   Research systems now have the AI write code, a spec AND a proof, so
   humans review the spec instead of every line. Notice what that makes the
   human's job: deciding whether the spec is the right one.
-/

/-! ## Bounty 3 · an "optimization"

AIs love rewriting simple code into tail-recursive "fast" code. Is it still right? -/

def sumAcc : List ℕ → ℕ → ℕ
  | [], acc => acc
  | x :: xs, acc => sumAcc xs (acc + x)

/-- AI-written: a faster sum. -/
def fastSum (l : List ℕ) : ℕ := sumAcc l 0

#eval fastSum [1, 2, 3, 4]

/-- The helper. Proving `fastSum` directly by induction gets stuck, because the
accumulator changes. Proving this MORE GENERAL statement works. That's a real
technique called "strengthening the induction hypothesis". -/
theorem sumAcc_eq (l : List ℕ) (acc : ℕ) : sumAcc l acc = acc + l.sum := by
  sorry

/-- Spec: the fast sum is the sum. -/
theorem fastSum_correct (l : List ℕ) : fastSum l = l.sum := by
  sorry

/-! ## Bounty 4 · an off-by-one -/

/-- AI-written: "0 + 1 + 2 + ... + n, using Gauss's formula". -/
def sumTo (n : ℕ) : ℕ := n * (n - 1) / 2

/-- Spec claimed by the AI: `sumTo n = ∑ i ∈ range (n+1), i`. Catch it. -/
theorem sumTo_bug : ∃ n : ℕ, sumTo n ≠ ∑ i ∈ Finset.range (n + 1), i := by
  sorry

/-! ## 🐉 BOSS · Bounty 5 · the average -/

/-- AI-written: the average of a list of rationals. -/
def average (l : List ℚ) : ℚ := l.sum / l.length

/-- Spec: the average of n copies of c is c (as long as n ≥ 1). -/
theorem average_replicate (n : ℕ) (c : ℚ) (hn : 0 < n) :
    average (List.replicate n c) = c := by
  sorry

end A1

/-
  ⚔️ SPARRING ROUND (do this, it's the best part): paste the statement of
  `maxList_spec` into an AI chatbot and ask for a Lean 4 proof. Paste its
  answer here. Did it compile on the first try? Second? What went wrong?
  Write it down in your log under "AI report". That data feeds Quest A3.

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
