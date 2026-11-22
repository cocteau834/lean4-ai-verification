import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  VERIFIED SYSTEMS · V2 · VERICODING                ⏱ 45–60 min│
  └──────────────────────────────────────────────────────────────┘

  In VERIFIED CODE GENERATION ("vericoding") an AI writes three things:
    the CODE, a SPEC (what the code must do), and a PROOF that the code
    meets the spec.
  Lean checks the proof, so nobody has to trust it. What's left for a
  human? Exactly one question: IS THE SPEC RIGHT?

  A spec can fail in two directions:
    • too WEAK:   wrong code passes it too;
    • too STRONG: the code you actually want can't pass it.
  So you test a spec like you'd test code: it must ACCEPT the right
  implementation and REJECT the wrong ones. Today you do both.

  New Lean you'll meet:
    l.Nodup          "the list l has no repeated elements"
    x ∈ l            "x is in the list l"
    split_ifs        split a proof at an `if ... then ... else`
    fun _ => []      a function that ignores its input and returns []

  Moves: intro, exact, simp, induction l with, split_ifs, constructor,
  rintro, and `exact?` to find library facts about lists.
-/

namespace V2

/-! ## Worked example · a full triple, and a test of the spec

Code: clamp x into the range [lo, hi]. -/

def clamp (lo hi x : ℕ) : ℕ := max lo (min hi x)

/-- Spec: the answer is in range, and an x that's already in range is kept. -/
def ClampSpec (f : ℕ → ℕ → ℕ → ℕ) : Prop :=
  ∀ lo hi x, lo ≤ hi → lo ≤ f lo hi x ∧ f lo hi x ≤ hi ∧ (lo ≤ x → x ≤ hi → f lo hi x = x)

/-- Proof: the code meets the spec. -/
theorem clamp_meets_spec : ClampSpec clamp := by
  intro lo hi x h
  simp only [clamp]
  omega                    -- omega understands max and min

/-- And a test OF the spec: a lazy function that always answers `lo` is
in range, but the spec still rejects it, because of the third part. -/
theorem lazy_fails_spec : ¬ ClampSpec (fun lo _ _ => lo) := by
  intro h
  have := (h 0 2 1 (by norm_num)).2.2 (by norm_num) (by norm_num)
  simp at this             -- it would need 0 = 1

/-! ## The pull request

An AI agent was asked for "a function that removes duplicates from a list".
It submitted this code, this spec, and a proof that Lean accepted. -/

def dedupAI : List ℕ → List ℕ
  | [] => []
  | x :: xs => if x ∈ xs then dedupAI xs else x :: dedupAI xs

#eval dedupAI [3, 1, 3, 2, 1]    -- [3, 2, 1]

/-- The AI's spec: "the output has no duplicates". -/
def SpecAI (f : List ℕ → List ℕ) : Prop := ∀ l, (f l).Nodup

/-! ## Part 1 · Break the AI's spec -/

/-- Loophole 1 · ✏️ Write a WRONG "dedup" that still satisfies `SpecAI`.
Replace `sorry` with a function. The lazier, the better. -/
def wrongDedup : List ℕ → List ℕ := sorry

/-- Loophole 2 · Prove your wrong function passes the AI's spec. -/
theorem wrong_passes : SpecAI wrongDedup := by
  sorry

/- 🧑‍🔬 ON THE JOB · The human's job moves to the spec
   As AI gets better at writing proofs, the spec becomes the weak point: a
   proof of a weak spec is a perfect certificate for the wrong program.
   People building vericoding benchmarks (in Dafny, Verus and Lean) spend
   real effort checking that their specs are strong enough, and reviewing
   specs is a skill verification teams hire for.
-/

/-! ## Part 2 · Write the spec that should have been written

The rule: say WHAT, not HOW. Your spec must not mention `dedupAI` or
`wrongDedup`. (A spec that says "f equals the AI's code" accepts the code
and proves nothing. It's just the code again.) -/

/-- Spec 1 · ✏️ What should every dedup guarantee? Replace `sorry` with a
property of `f`. (Think: no repeats, and... what about the elements?) -/
def GoodSpec (f : List ℕ → List ℕ) : Prop := sorry

/-- Spec 2 · Your spec must REJECT your wrong function. -/
theorem good_rejects_wrong : ¬ GoodSpec wrongDedup := by
  sorry

/-! ## Part 3 · ...and ACCEPT the right one

Prove the AI's code meets YOUR spec. Two lemmas first, then assemble.
Big verified programs are built exactly like this. -/

/-- Lemma 1 · dedup keeps exactly the right elements. (Induction on l; at
the `if`, use `split_ifs with h`.) -/
theorem mem_dedupAI (x : ℕ) (l : List ℕ) : x ∈ dedupAI l ↔ x ∈ l := by
  sorry

/-- Lemma 2 · No repeats. (Induction again. `List.nodup_cons` says what it
takes for `x :: xs` to have no repeats. Lemma 1 helps.) -/
theorem nodup_dedupAI (l : List ℕ) : (dedupAI l).Nodup := by
  sorry

/-- Spec 3 · The AI's code meets your spec. -/
theorem good_accepts_AI : GoodSpec dedupAI := by
  sorry

/-! ## 🐉 BOSS · Does your spec pin the answer down?

Here's another correct dedup, from Lean's own library. It keeps FIRST
copies; the AI's keeps last copies. -/

#eval (dedupAI [3, 1, 3, 2, 1], [3, 1, 3, 2, 1].eraseDups)    -- ([3, 2, 1], [3, 1, 2])

/- Different answers, and both are fine, because nobody asked for an order.
A good spec pins down what you care about and leaves the rest free. Prove
that yours pins down at least this much: any two functions that meet it
return lists of the same length. -/

/-- BOSS · (Useful library facts: `List.perm_ext_iff_of_nodup` and
`List.Perm.length_eq`. `l₁.Perm l₂` means "same elements, maybe reordered".) -/
theorem spec_pins_length (f g : List ℕ → List ℕ) (hf : GoodSpec f) (hg : GoodSpec g)
    (l : List ℕ) : (f l).length = (g l).length := by
  sorry

end V2

/-
  Log idea: write down one spec you'd want an AI to prove about code you've
  written for a class. Is it too weak? Too strong? How would you test it?

  ⚔️ SPARRING ROUND: ask an AI chatbot for "a Lean 4 spec for a function
  that removes duplicates". Is its spec as strong as yours? Weaker? Log it.

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
