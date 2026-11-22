import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  VERIFIED SYSTEMS · V1 · THE POLICY ENGINE         ⏱ ~45 min │
  └──────────────────────────────────────────────────────────────┘

  Every app answers one question thousands of times a second: may THIS
  person do THIS action to THIS thing? The answers come from a POLICY, a
  list of rules. Get one rule wrong and an intern can delete the payroll.

  Today you verify a tiny policy engine modeled on Cedar, the access-rule
  language AWS built and proved things about in Lean. Two kinds of proof:
    • properties of the ENGINE, true for every policy anyone could write;
    • properties of ONE company's policy, checked over every request.

  New Lean you'll meet:
    inductive Role | admin | ...    a type with a fixed list of values
    structure Request where ...     a record with named fields
    ⟨.intern, .read, .logs⟩         build a record (fields in order)
    cases a <;> decide              split into every possible value, then
                                    let Lean check each case

  Moves: rfl, simp [authorize], intro, exact ⟨_, _⟩, cases, decide.
-/

namespace V1

/-! ## The world: who, what, and which thing -/

inductive Role | admin | engineer | intern
  deriving DecidableEq, Repr

inductive Act | read | write | delete
  deriving DecidableEq, Repr

inductive Res | code | payroll | logs
  deriving DecidableEq, Repr

/-- A request: who wants to do what, to which resource. -/
structure Request where
  role : Role
  act : Act
  res : Res
  deriving DecidableEq, Repr

/-! ## The engine -/

inductive Effect | permit | forbid
  deriving DecidableEq, Repr

/-- A rule has an effect, and a test saying which requests it covers. -/
structure Rule where
  effect : Effect
  covers : Request → Bool

/-- The engine, Cedar-style:
  • DEFAULT DENY: you need at least one permit rule that covers you;
  • FORBID WINS: any forbid rule that covers you overrides every permit. -/
def authorize (policy : List Rule) (r : Request) : Bool :=
  policy.any (fun p => p.effect == .permit && p.covers r) &&
  !(policy.any (fun p => p.effect == .forbid && p.covers r))

/-! ## One company's policy -/

def companyPolicy : List Rule :=
  [ ⟨.permit, fun r => r.role == .admin⟩,                           -- admins may do anything
    ⟨.permit, fun r => r.role == .engineer && r.res != .payroll⟩,   -- engineers: all but payroll
    ⟨.permit, fun r => r.act == .read && r.res == .logs⟩,           -- anyone may read the logs
    ⟨.forbid, fun r => r.act == .delete && r.res == .logs⟩ ]        -- NOBODY deletes the audit log

#eval authorize companyPolicy ⟨.intern, .read, .logs⟩       -- true
#eval authorize companyPolicy ⟨.intern, .write, .code⟩      -- false
#eval authorize companyPolicy ⟨.admin, .delete, .logs⟩      -- false, even for admins

/-! ## Part 1 · Properties of the engine (true for EVERY policy) -/

/-- Engine 1 · Default deny: an empty policy allows nothing. -/
theorem default_deny (r : Request) : authorize [] r = false := by
  sorry

/-- Engine 2 · Forbid wins: one forbid rule that covers a request blocks it,
whatever else the policy says. -/
theorem forbid_wins (policy : List Rule) (r : Request) (p : Rule)
    (hp : p ∈ policy) (hf : p.effect = .forbid) (hc : p.covers r = true) :
    authorize policy r = false := by
  sorry

/-- Engine 3 · No access without a reason: if a request is allowed, some
permit rule in the policy covers it. -/
theorem permit_needed (policy : List Rule) (r : Request) (h : authorize policy r = true) :
    ∃ p ∈ policy, p.effect = .permit ∧ p.covers r = true := by
  sorry

/-- Engine 4 · Rule order doesn't matter. (Firewalls are different: there
the first matching rule wins, and reordering rules is a classic outage.) -/
theorem order_irrelevant (p₁ p₂ : List Rule) (r : Request) :
    authorize (p₁ ++ p₂) r = authorize (p₂ ++ p₁) r := by
  sorry

/- 🧑‍🔬 ON THE JOB · Prove the engine once, trust every policy
   Cedar's team modeled the engine in Lean and proved properties like
   "forbid always beats permit" for every possible policy. Customers then
   write their own policies and get those guarantees for free. Proving
   something once, for all inputs, instead of testing it forever: that's
   the trade verification makes.
-/

/-! ## Part 2 · Properties of the company's policy -/

/-- Policy 1 · The audit log can never be deleted, not even by an admin.
(Two good ways: use `forbid_wins`, or check all three roles.) -/
theorem logs_never_deleted (role : Role) :
    authorize companyPolicy ⟨role, .delete, .logs⟩ = false := by
  sorry

/-- Policy 2 · Interns are read-only: anything an intern is allowed to do is
a read. -/
theorem interns_read_only :
    ∀ a s, authorize companyPolicy ⟨.intern, a, s⟩ = true → a = .read := by
  sorry

/-! ## 🐉 BOSS · Review the AI's policy change

The team asked for one change: "interns may now WRITE CODE. Nothing else
changes." An AI assistant opened this pull request: -/

def aiPolicy : List Rule :=
  companyPolicy ++ [⟨.permit, fun r => r.role == .intern && r.res == .code⟩]

#eval authorize aiPolicy ⟨.intern, .write, .code⟩    -- true, as requested. Ship it?

/-- Boss 1 · Catch the leak: a request the AI's policy allows that the old
policy didn't, and that isn't the one the team asked for. -/
theorem change_leaks : ∃ r : Request,
    authorize aiPolicy r = true ∧ authorize companyPolicy r = false ∧
    r ≠ ⟨.intern, .write, .code⟩ := by
  sorry

/-- Boss 2 · ✏️ Write the correct change. Replace `sorry` with a policy
(hint: start from `companyPolicy ++ [ ... ]`). -/
def fixedPolicy : List Rule := sorry

/-- Boss 3 · Prove your change is EXACTLY what was asked: every request gets
the old decision, except intern-writes-code, which is now allowed.
(27 possible requests. Lean can check them all.) -/
theorem fix_is_exact : ∀ r : Request,
    authorize fixedPolicy r = (authorize companyPolicy r || r == ⟨.intern, .write, .code⟩) := by
  sorry

/- 🧑‍🔬 ON THE JOB · Policy diffs
   "Does this change let anyone do something they couldn't before?" is a
   question automated-reasoning teams answer for real: AWS's Zelkova checks
   access policies with an SMT solver, and Cedar ships analysis tools whose
   core is proved correct in Lean. Boss 3 is a policy diff with a proof.
   As AI writes more configuration, checking its changes this way scales
   better than reading every rule by hand.
-/

end V1

/-
  Log idea: which was more convincing to you, the engine proofs (Part 1) or
  checking all 27 requests (Boss 3)? When would you want each?

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
