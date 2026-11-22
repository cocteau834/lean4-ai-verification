import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  QUEST 01 · FIRST CONTACT                       ⏱ 30–45 min │
  └──────────────────────────────────────────────────────────────┘

  Lean is two things at once:
    1. a programming language: you can run code with `#eval`;
    2. a proof checker: it will not accept a theorem until every step
       is justified, no matter how confident whoever wrote it sounds.

  That second part is why AI labs care about it. An AI can *say* anything.
  Lean only lets through what is actually true.

  HOW TO PLAY
  • Click on a line. The Lean Infoview panel (right side) shows what Lean
    sees there. No Infoview? Ctrl+Shift+Enter (Cmd+Shift+Enter on a Mac).
  • Every `sorry` is an unsolved puzzle. Replace it with a proof.
    A yellow squiggle means "uses sorry"; red means "error". No squiggle = proved.
  • Save, commit, push. The Expedition checks your proofs and unlocks quests.

  Stuck? In the terminal: `python3 scripts/expedition.py hint puzzle1` (any
  puzzle name) shows one hint at a time.
-/

namespace Q01

/-! ## Part 1 · Lean is a programming language

Click on each `#eval` line and look at the Infoview. -/

#eval 2 + 2
#eval 2 ^ 100                                -- big numbers are no problem
#eval (List.range 10).map (fun n => n ^ 2)   -- squares of 0..9
#eval Nat.Prime 7                            -- you can even ask questions

/-- A function that doubles a natural number. `ℕ` is typed `\N` then space. -/
def double (n : ℕ) : ℕ := 2 * n

#eval double 21

/- 🧑‍🔬 ON THE JOB · The checker is the product
   AI labs train provers with reinforcement learning: the model proposes a
   proof, Lean compiles it, and the reward is 1 only if it checks. That's a
   "verifiable reward", and it's why math and code are where AI reasoning
   has improved fastest. You're about to use the same judge.
-/

/-! ## Part 2 · Lean is a proof checker

A theorem looks like  `theorem name : statement := by tactics`.
Read these worked examples. Put your cursor right after `by` and watch the
Infoview: the goal appears after the `⊢` symbol. When the proof is complete,
Lean says "No goals". -/

-- `rfl` ("reflexivity"): both sides compute to the same value.
example : double 21 = 42 := by rfl

-- `norm_num`: a calculator that produces proofs.
example : (2 : ℕ) ^ 10 = 1024 := by norm_num

-- `decide`: for small, finite questions, Lean checks every case itself.
example : 7 * 6 = 42 := by decide

/-
  TRY THIS (then delete it): make Lean say no. Uncomment the next line and
  read the error message. Lean refuses to "prove" false things, however you ask.

  example : 2 + 2 = 5 := by decide
-/

/-! ## Part 3 · Your turn -/

/-- Puzzle 1 · Warm-up. -/
theorem puzzle1 : double 50 = 100 := by
  sorry

/-- Puzzle 2 · A chatbot told me that 2027 is a prime number. Is it?
If Lean accepts your proof, the chatbot was right. -/
theorem puzzle2 : Nat.Prime 2027 := by
  sorry

/-- Puzzle 3 · ...and it said 2026 is *not* prime. (`¬` means "not", typed `\not`.) -/
theorem puzzle3 : ¬ Nat.Prime 2026 := by
  sorry

/-- Puzzle 4a · Write your own function: `triple n` should be three times `n`.
Replace `sorry` with a definition. (Look at `double` above.) -/
def triple (n : ℕ) : ℕ := sorry

/-- Puzzle 4b · Prove that your function works.
After you finish 4a, add a line `#eval triple 14` above this one to test it. -/
theorem puzzle4 : triple 14 = 42 := by
  sorry

/-- Puzzle 5 · Someone claims `2 ^ 10 = 1000`. Prove them wrong.
(`≠` is typed `\ne`.) -/
theorem puzzle5 : (2 : ℕ) ^ 10 ≠ 1000 := by
  sorry

/-- 🐉 BOSS · For every natural number below 10, its square is below 100.
That is ten facts at once. One tactic from Part 2 can check them all. -/
theorem boss : ∀ n : ℕ, n < 10 → n ^ 2 < 100 := by
  sorry

end Q01

/-
  When you're done: save, commit and push (see START_HERE.md), then add a
  few lines to your log.md. The Game Master reads it.

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
