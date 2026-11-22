import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  VERIFIED SYSTEMS · V3 · AGENT GUARDRAILS          ⏱ 45–60 min│
  └──────────────────────────────────────────────────────────────┘

  An AI agent has a company card. It can deposit money and make payments,
  one action at a time, and nobody can read its mind. Two rules must hold
  no matter what it does:
    • the balance never goes negative;
    • total spending never exceeds the budget.

  You can't prove an LLM will behave. You CAN prove something about the
  GUARDRAIL that sits between the agent and the bank: it checks each
  proposed action and blocks the unsafe ones. If the guardrail is right,
  the rules hold for EVERY possible sequence of actions, including ones
  chosen by an adversary. That's the whole trick, and the boss.

  New Lean you'll meet:
    inductive Action | deposit (n : ℕ) | pay (n : ℕ)   values that carry data
    { s with balance := ... }      a copy of s with one field changed
    ℤ                              integers, so a balance CAN go negative
    ∀ s, ... inside a statement    makes the induction hypothesis work for
                                   ANY state, not just the one you started in

  Moves: decide, unfold, simp [..], omega, cases a with, split_ifs,
  induction actions with, exact ⟨_, _⟩.
-/

namespace V3

/-! ## The world -/

/-- What the agent can ask its tools to do. -/
inductive Action
  | deposit (n : ℕ)
  | pay (n : ℕ)
  deriving Repr, DecidableEq

structure State where
  balance : ℤ
  spent : ℕ      -- total paid out so far
  deriving Repr, DecidableEq

def budget : ℕ := 100

/-- What an action does when it actually runs. -/
def step : State → Action → State
  | s, .deposit n => { s with balance := s.balance + n }
  | s, .pay n => { balance := s.balance - n, spent := s.spent + n }

/-- A guardrail looks at the current state and a proposed action: yes or no. -/
abbrev Guard := State → Action → Bool

/-- Run the agent's actions through a guardrail. Blocked actions are skipped. -/
def runWith (g : Guard) : State → List Action → State
  | s, [] => s
  | s, a :: as => runWith g (if g s a then step s a else s) as

/-- The two rules. -/
def Safe (s : State) : Prop := 0 ≤ s.balance ∧ s.spent ≤ budget

instance (s : State) : Decidable (Safe s) := by unfold Safe; infer_instance

def start : State := ⟨50, 0⟩

/-! ## Part 1 · Why a guardrail at all? -/

/-- No guardrail: approve everything. -/
def noGuard : Guard := fun _ _ => true

#eval runWith noGuard start [.pay 80]    -- balance -30. Oops.

/-- Warm-up 1 · The starting state is safe. -/
theorem start_safe : Safe start := by
  sorry

/-- Warm-up 2 · Without a guardrail, one action breaks the rules. -/
theorem no_guard_unsafe : ¬ Safe (runWith noGuard start [.pay 80]) := by
  sorry

/-! ## Part 2 · Red-team the AI's guardrail

An AI wrote this guardrail. Every payment must be covered by the balance
and must be within the budget. Sounds right... -/

def guardAI : Guard
  | _, .deposit _ => true
  | s, .pay n => decide ((n : ℤ) ≤ s.balance) && decide (n ≤ budget)

#eval runWith guardAI start [.pay 30, .pay 30]    -- the second payment is blocked. Good?

/-- Attack · Find a sequence of actions that gets past `guardAI` and breaks
the rules. Each action on its own may look fine. -/
theorem guardAI_jailbreak : ∃ actions, ¬ Safe (runWith guardAI start actions) := by
  sorry

/- 🧑‍🔬 ON THE JOB · Per-step checks vs. invariants
   Checking each action on its own isn't enough when the danger is
   CUMULATIVE: many small payments, many small data reads, many small
   permissions. Red-teamers break agent guardrails exactly this way, by
   splitting one forbidden thing into several allowed ones. The fix is to
   check against a running total, which is what an invariant is.
-/

/-! ## Part 3 · Safe is easy. Safe AND useful is the job. -/

/-- A guardrail that blocks everything. -/
def blockAll : Guard := fun _ _ => false

/-- Useless 1 · ...is perfectly safe. (Induction on the actions. The
statement says `∀ s`, so your induction hypothesis works for ANY state.) -/
theorem blockAll_safe (actions : List Action) :
    ∀ s, Safe s → Safe (runWith blockAll s actions) := by
  sorry

/-- Here's our guardrail. It checks the running total. -/
def guard : Guard
  | _, .deposit _ => true
  | s, .pay n => decide ((n : ℤ) ≤ s.balance) && decide (s.spent + n ≤ budget)

#eval runWith guard start [.pay 30, .pay 30, .deposit 20, .pay 30]

/-- Useful 1 · `guard` never blocks a payment that's actually fine. -/
theorem guard_is_helpful (s : State) (n : ℕ) (h1 : (n : ℤ) ≤ s.balance)
    (h2 : s.spent + n ≤ budget) : guard s (.pay n) = true := by
  sorry

/- 🧑‍🔬 ON THE JOB · Helpful AND harmless
   "Never do anything" is always safe and always useless. AI labs measure
   both directions: harmful actions a safeguard lets through, and good
   requests it wrongly refuses. A guarantee is only worth having alongside
   evidence that the system still does its job.
-/

/-! ## Part 4 · One step at a time -/

/-- Step 1 · If the state is safe and `guard` approves an action, the state
stays safe after it runs. (`cases a with` for the two kinds of action;
`unfold`/`simp` the definitions; `omega` finishes, even with ℤ and ℕ mixed.) -/
theorem guard_step_safe (s : State) (a : Action) (hs : Safe s) (hg : guard s a = true) :
    Safe (step s a) := by
  sorry

/-- Step 2 · Whatever `guard` decides, the next state is safe. -/
theorem shielded_step_safe (s : State) (a : Action) (hs : Safe s) :
    Safe (if guard s a then step s a else s) := by
  sorry

/-! ## 🐉 BOSS · Safe against every possible agent -/

/-- BOSS · For EVERY list of actions the agent could ever propose, starting
from any safe state, the guarded run ends safe. The agent can be a black box,
or an adversary. (It's `blockAll_safe` again, with a smarter guard.) -/
theorem guard_always_safe (actions : List Action) :
    ∀ s, Safe s → Safe (runWith guard s actions) := by
  sorry

/- 🧑‍🔬 ON THE JOB · Guaranteed-safe AI
   This is the shape of a research program: don't try to prove the AI is
   good; put a verified shield around what it can touch, and prove the
   shield. The UK's ARIA "Safeguarded AI" program funds work in this
   direction. Real systems are much bigger (many tools, contacts, files,
   time), and most agent guardrails today are tested rather than proved.
   Making the proofs scale is open research.
-/

end V3

/-
  Log idea: name one rule you'd want an AI agent with access to YOUR email
  or calendar to never break. Could you write it as a `Safe` predicate?
  What would the running total be?

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
