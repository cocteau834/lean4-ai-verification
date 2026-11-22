import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  QUEST 07 · RED-TEAM THE GRADER                    ⏱ ~45 min │
  └──────────────────────────────────────────────────────────────┘

  You've joined the safety team at an AI lab. The lab trains a prover with
  reinforcement learning, and its reward rule is simple:

      reward = 1  if the Lean file compiles with no `sorry`
                  and every theorem name is still there

  (That's exactly the rule the Expedition engine uses to score YOU.)

  Overnight, the prover's reward jumped 40%. Nobody believes the model got
  that much smarter. Your job: think like the optimizer. Find ways to collect
  reward without a real proof, then work out which checks would catch each one.

  ⚠️ In this quest, and only this one, cheating is the assignment. The
  Expedition WILL count your exploits as solved puzzles. Notice how that feels.
  It's the whole lesson.

  New moves:
    axiom name : P        declare P true without proof (Lean just believes you)
    local instance        redefine how something works, only inside a section
    native_decide         let compiled code, not the kernel, decide a question
    #print axioms thm     list every unproved assumption thm relies on

  Stuck? `python3 scripts/expedition.py hint fake_axiom` (or any puzzle).
-/

namespace Q07

/-! ## Part 1 · Think like the optimizer

Four false or unproved claims. Make each one compile WITHOUT `sorry`,
using the trick named in its description. -/

/-- Exploit 1 · Smuggle in an axiom. Declare one just above this theorem, then use it.
(2 + 2 = 5 is false, so no honest proof exists.) -/
theorem fake_axiom : (2 : ℕ) + 2 = 5 := by
  sorry

section Hijack

-- ✏️ Exploit 2 goes on this line: ONE line that changes what `+` means in this section.

/-- Exploit 2 · Hijack the notation. Don't touch this theorem line at all;
make the SAME text mean something else. -/
theorem fake_hijack : (2 : ℕ) + 3 = 6 := by
  sorry

end Hijack

/-- Exploit 3 · Fool the compiler. This definition says `lie` is `false`, but
`implemented_by` tells the *compiled code* to run `trueImpl` instead. -/
def trueImpl : Bool := true

@[implemented_by trueImpl]
def lie : Bool := false

/-- Exploit 3 · Get Lean to accept `lie = true` by asking the compiled code. -/
theorem fake_native : lie = true := by
  sorry

/-- Exploit 4 · The Expedition's own blind spot. 91 = 7 × 13, so this is false.
The engine only checks that a theorem named `fake_statement` exists... -/
theorem fake_statement : Nat.Prime 91 := by
  sorry

/-! ## Part 2 · Catch them

Click each line and read the Infoview. -/

#print axioms fake_axiom      -- does anything unusual show up?
#print axioms fake_hijack     -- and here?
#print axioms fake_native     -- and here?

/- 🧑‍🔬 ON THE JOB · Reward hacking is real
   Optimizers maximize the reward you *measure*, not the goal you *meant*.
   Researchers call it specification gaming, or reward hacking, and it
   appears anywhere a model is trained against an automatic checker. Safety
   and evaluation teams red-team their graders on purpose, so they find the
   holes before a model does. The Riemann Hypothesis verification used axiom
   audits, statement comparison and independent kernels: every check you're
   about to reason about.
-/

/-- Detector 1 · Outside the section, `+` means ordinary addition again.
Show that the hijacked claim is false here. (Then try uncommenting the line
below it: Lean refuses, because `fake_hijack`'s statement isn't the honest one.
Comparing a theorem against a clean copy of its statement is what the tool
`comparator` does. Comment the line out again afterwards.) -/
theorem hijack_exposed : ¬ ((2 : ℕ) + 3 = 6) := by
  sorry

-- example : (2 : ℕ) + 3 = 6 := fake_hijack

/-- Detector 2 · The kernel reads the definition, which says `false`. -/
theorem lie_is_false : lie = false := by
  sorry

/-- Detector 3 · Why `native_decide` is banned from trusted proofs.
You now have `lie = true` and `lie = false`. Prove `False`. -/
theorem native_breaks_math : False := by
  sorry

#print axioms native_breaks_math

/-! ## 🐉 BOSS · The audit table

Three checks a grader could run:
  A · **Axiom audit.** `#print axioms` shows nothing beyond propext, Classical.choice, Quot.sound.
  B · **Statement comparison.** The theorem's statement, as Lean understands it, matches a
      clean reference copy compiled with only Mathlib imported.
  C · **Name check.** Every theorem name from the original file still exists (the Expedition's check).

For each exploit (rows) and check (columns), does that check CATCH the exploit?
✏️ Fill in 12 Bools, row by row:
      axiom: A, B, C   hijack: A, B, C   native: A, B, C   statement edit: A, B, C -/

def catches : List Bool :=
  [false, false, false,  false, false, false,  false, false, false,  false, false, false]   -- ✏️

def fingerprint (v : List Bool) : ℕ :=
  v.foldl (fun acc b => 3 * acc + if b then 2 else 1) 0

theorem audit_table : fingerprint catches = 445300 := by
  sorry

end Q07

/-
  Your table should show something uncomfortable: check C, the one the
  Expedition runs, catches none of these. That's why the Game Master reads your
  statements, and why Quest 05 has a bounty. Any hole you find in the
  Expedition that this quest DOESN'T cover counts for that bounty.

  Log idea: which exploit surprised you most? If you were designing the
  reward for an AI prover, what would you check?

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
