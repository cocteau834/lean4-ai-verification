import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  QUEST 02 · THE TACTIC TOOLKIT                  ⏱ 45–60 min │
  └──────────────────────────────────────────────────────────────┘

  A Lean proof is a game.
    • The Infoview shows what you HAVE (hypotheses, above the line)
      and your GOAL (after `⊢`).
    • Each tactic is one move that changes the goal.
    • You win when Lean says "No goals".

  Moves you'll learn here:

    intro h        goal `P → Q`: assume P (call it h), now prove Q
    exact h        "h is exactly the goal"
    apply f        goal Q, f : P → Q  ⇒  new goal P
    constructor    goal `P ∧ Q`: split into two goals
    obtain ⟨a, b⟩ := h    h : P ∧ Q  ⇒  a : P and b : Q
    left / right   goal `P ∨ Q`: choose which side to prove
    rcases h with a | b   h : P ∨ Q  ⇒  two cases
    rw [h]         h : x = y  ⇒  replace x by y in the goal
    use 12         goal `∃ n, ...`: "take n = 12"

  Typing symbols: → \to   ∧ \and   ∨ \or   ¬ \not   ↔ \iff   ⟨ ⟩ \< \>   ∃ \ex
-/

namespace Q02

variable (P Q R : Prop)

/-! ## Part 1 · Logic gym

Worked example. Click through it line by line and watch the goal change. -/

example (hP : P) (hQ : Q) : P ∧ Q := by
  constructor
  · exact hP
  · exact hQ

/-- Move 1 · Modus ponens. -/
theorem t1 (hP : P) (hPQ : P → Q) : Q := by
  sorry

/-- Move 2 · Swap an "and". -/
theorem t2 (h : P ∧ Q) : Q ∧ P := by
  sorry

/-- Move 3 · Pick a side. -/
theorem t3 (hQ : Q) : P ∨ Q := by
  sorry

/-- Move 4 · Swap an "or". You will need to handle two cases. -/
theorem t4 (h : P ∨ Q) : Q ∨ P := by
  sorry

/-- Move 5 · Chain two implications. -/
theorem t5 (hPQ : P → Q) (hQR : Q → R) : P → R := by
  sorry

/-- Move 6 · No statement is both true and false.
(`¬ X` means `X → False`, so start with `intro`.) -/
theorem t6 : ¬ (P ∧ ¬ P) := by
  sorry

/-- Move 7 · Rewriting. -/
theorem t7 (a b c : ℕ) (h1 : a = b + 1) (h2 : b = c * 2) : a = c * 2 + 1 := by
  sorry

/-- Move 8 · Show that something exists by giving it. -/
theorem t8 : ∃ n : ℕ, n * n = 144 := by
  sorry

/- 🧑‍🔬 ON THE JOB · Specs are where the bugs hide
   Below, a word puzzle becomes a formal statement, and the encoding
   `x = true ↔ S` is a design choice. Encode it subtly wrong and Lean will
   cheerfully prove the wrong thing. Verification engineers spend more time
   getting statements right than proving them.
-/

/-! ## Part 2 · 🐉 BOSS: The Island of Knights and Knaves

Every inhabitant of this island is either a KNIGHT (always tells the truth)
or a KNAVE (always lies). We record a person as a `Bool`:

    true  = knight        false = knave

The key trick: if person `x` says statement `S`, then

    x = true ↔ S

(a knight's statement is true, and a knave's statement is false).

Each puzzle has two parts:
  1. ✏️ Change the `answer` definition to what you think is right.
  2. Prove it is the ONLY possibility.

A wrong answer makes the theorem false, and Lean will refuse it. One tactic
can check every case (all of them are finite), but solve it in your head first.
-/

/-- B1 · A says: "I am a knave." Show that nobody on the island can say this. -/
theorem liar : ¬ ∃ a : Bool, (a = true ↔ a = false) := by
  sorry

/-- B2 · A says: "We are both knaves." What are A and B? -/
def answerB2 : Bool × Bool := (true, true)   -- ✏️ (A, B): change me

theorem knightsB2 :
    ∀ a b : Bool, (a = true ↔ (a = false ∧ b = false)) → (a, b) = answerB2 := by
  sorry

/-- B3 · A says: "B is a knave." B says: "A and I are the same kind." -/
def answerB3 : Bool × Bool := (true, true)   -- ✏️ (A, B): change me

theorem knightsB3 :
    ∀ a b : Bool, (a = true ↔ b = false) → (b = true ↔ a = b) → (a, b) = answerB3 := by
  sorry

/-- B4 · Three islanders.
A says: "B is a knave."
B says: "C is a knave."
C says: "A and B are both knaves." -/
def answerB4 : Bool × Bool × Bool := (true, true, true)   -- ✏️ (A, B, C): change me

theorem knightsB4 :
    ∀ a b c : Bool,
      (a = true ↔ b = false) →
      (b = true ↔ c = false) →
      (c = true ↔ (a = false ∧ b = false)) →
      (a, b, c) = answerB4 := by
  sorry

end Q02

/-
  Done? Commit, push, and write a log entry. Which puzzle was most satisfying?

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
