import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  MACHINE WHISPERER'S PATH · A3 · BUILD A MINI-PROVER         │
  │                                     ⏱ 60–90 min (a project) │
  └──────────────────────────────────────────────────────────────┘

  AlphaProof (DeepMind), Aristotle (Harmonic), AxiomProver, Gauss (Math, Inc.)
  and the work behind the Riemann Hypothesis formalization all share one loop:

        ┌─────────────┐  proof attempt   ┌───────────┐
        │  LLM        │ ───────────────▶ │  Lean     │
        │  (guesses)  │ ◀─────────────── │  (judge)  │
        └─────────────┘   error message  └───────────┘

  The LLM is allowed to be wrong as often as it likes, because Lean catches
  every mistake and its error messages are excellent feedback. You'll run
  that loop yourself on the eight problems below.

  THE TOOL:  tools/miniprover/miniprover.py   (read tools/miniprover/README.md)

    # with an Anthropic API key (ask the Game Master):
    python3 tools/miniprover/miniprover.py Players/<you>/quests/A3_MiniProver.lean --write

    # no key? be the LLM's hands: it prints prompts, you paste them into any chatbot
    python3 tools/miniprover/miniprover.py Players/<you>/quests/A3_MiniProver.lean --manual --write

  Every attempt is logged to tools/miniprover/runs/results.csv: which model,
  which problem, pass/fail, tokens, seconds, and Lean's error. That CSV is the
  raw material for the co-op CAPSTONE, so commit it.

  YOUR MISSION
    1. Run the prover on this file. Which problems fell? Which resisted?
    2. Finish any survivors BY HAND. (Humans and AIs make a good team.)
    3. Upgrade the prover. Ideas: give it a "think step by step about which
       tactic" prompt, feed back more of Lean's error, try several models,
       try `exact?` first, give it the Lean cheat-sheet. Measure whether each
       change actually helps.
    4. Write a short report in your log: what worked, what didn't, and one
       surprising failure. Compare the math problems with the code problems.
-/

/- 🧑‍🔬 ON THE JOB · This is the job
   Research engineers on AI-for-math teams build this loop at scale:
   searching over many attempts, learning from Lean's feedback, retrieving
   relevant lemmas, budgeting compute. Then they spend much of their week
   reading failures and measuring honestly, which is your mission step 4.
-/

namespace A3

/-! Four problems are about math and four are about code. Real benchmarks come
in both flavors: miniF2F and PutnamBench are math, while verified-code
benchmarks test whether an AI can prove properties of programs. Is your
prover better at one kind than the other? -/

/-- A tiny program: count down from n. -/
def countdown : ℕ → List ℕ
  | 0 => []
  | n + 1 => (n + 1) :: countdown n

/-- Insert x into a sorted list, keeping it sorted (the heart of insertion sort). -/
def insertSorted (x : ℕ) : List ℕ → List ℕ
  | [] => [x]
  | y :: ys => if x ≤ y then x :: y :: ys else y :: insertSorted x ys

#eval (countdown 4, insertSorted 3 [1, 2, 4, 5])

/-- mp1 · code, warm-up: reversing twice gives the list back -/
theorem mp1 (l : List ℕ) : l.reverse.reverse = l := by
  sorry

/-- mp2 · math: a perfect square in disguise -/
theorem mp2 (x : ℝ) : 0 ≤ x ^ 2 - 2 * x + 1 := by
  sorry

/-- mp3 · code: `countdown n` has exactly n elements -/
theorem mp3 (n : ℕ) : (countdown n).length = n := by
  sorry

/-- mp4 · math: divisibility for all n -/
theorem mp4 (n : ℕ) : 3 ∣ n ^ 3 + 2 * n := by
  sorry

/-- mp5 · code: inserting adds exactly one element -/
theorem mp5 (x : ℕ) (l : List ℕ) : (insertSorted x l).length = l.length + 1 := by
  sorry

/-- mp6 · math: a classic inequality -/
theorem mp6 (a b c : ℝ) : a * b + b * c + c * a ≤ a ^ 2 + b ^ 2 + c ^ 2 := by
  sorry

/-- mp7 · code: the inserted element really is in the result -/
theorem mp7 (x : ℕ) (l : List ℕ) : x ∈ insertSorted x l := by
  sorry

/-- mp8 · math, the hard one: no rational number squares to 2 -/
theorem mp8 (x : ℚ) : x ^ 2 ≠ 2 := by
  sorry

end A3

/-
  Log idea: which problems did the model solve on its first attempt, and which
  needed Lean's error message fed back? Was there a pattern?

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
