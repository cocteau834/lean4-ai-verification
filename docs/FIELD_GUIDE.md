# 🧭 Field Guide

How to think in Lean, how to get unstuck, and where to learn more. Read the first section once. Come back to the rest when you need it.

## How Lean thinks (2 minutes)

- **A theorem is a goal you have to reach.** `theorem name (hypotheses) : statement := by tactics`. Lean shows you the current goal after `⊢`, with everything you're allowed to use listed above it.
- **Tactics are moves.** Each one changes the goal: splits it, rewrites it, or closes it. When there are no goals left, the theorem is proved, and Lean has checked every step.
- **Hypotheses are evidence.** `h : n < 5` is a proof that n < 5. An implication `f : P → Q` is a *function*: give it a proof of P and it hands back a proof of Q. That's why `exact f hp` works.
- **Lean is literal.** It won't guess what you meant, and "obviously" isn't a move. The autopilot tactics (`simp`, `ring`, `linarith`, `omega`, `norm_num`, `decide`) do the obvious parts for you.
- **Errors are information.** A red squiggle tells you exactly which step failed and what Lean expected. Read the message, then look at the goal it shows.

## When you're stuck (the unsticking ladder)

1. **Read the goal.** Click right before the line that fails. What *shape* is the goal: `∀`, `→`, `∧`, `∨`, `∃`, `=`, `<`? The table in [CHEATSHEET.md](CHEATSHEET.md) maps each shape to the move that handles it.
2. **Say it on paper.** How would you prove it in words? Then translate one sentence at a time (the Proof Gym, T0, is all about this).
3. **Let Lean search.** `exact?` finds a library theorem that closes the goal. `apply?` finds one that makes progress. `rw?` suggests rewrites. `simp?` tells you which simp lemmas it used.
4. **Take a hint.** `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time: the idea first, then the Lean move. Hints are logged so the Game Master knows where to help. There's no penalty.
5. **Switch quests.** Prerequisites open at 60%, so you never need every puzzle. If you're really stuck, spend a detour token: `python3 scripts/expedition.py detour <QuestID>` opens any locked quest.
6. **Ask an AI, well.** Paste the *goal state from the Infoview*, not just the theorem, and say what you tried. Then check whether its answer compiles. (It often won't, and that's half the lesson.)
7. **Log it.** "Stuck on X" in `log.md` means the next dispatch will help.

## Searching Mathlib

| Tool | Use it for |
|---|---|
| `exact?` / `apply?` / `rw?` (in your proof) | "Is there a theorem that does this?" Lean searches for you |
| `#check foo` | See exactly what theorem `foo` says |
| [Loogle](https://loogle.lean-lang.org/) | Search by shape, e.g. `_ * _ ≤ _ * _` or `Nat.Prime, Even` |
| [LeanSearch](https://leansearch.net/) | Search in plain English: "square of an even number is even" |
| [Mathlib docs](https://leanprover-community.github.io/mathlib4_docs/) | Browse everything |

Mathlib names follow a pattern you can guess. `mul_le_mul` is "multiplication preserves ≤", `add_comm` is "addition commutes", `_iff` means the theorem is an ↔, `_of_` reads as "from" (`le_of_lt`: ≤ from <), and `Nat.` / `Real.` say which number system it's about.

## Paper proof → Lean

| On paper | In Lean |
|---|---|
| "Let n be arbitrary." | `intro n` |
| "Suppose P." | `intro hP` |
| "Since n is even, write n = k + k." | `obtain ⟨k, hk⟩ := h` |
| "Take m = 5." | `use 5` |
| "Case 1 … Case 2 …" | `rcases h with h1 \| h2` |
| "Suppose not." | `intro h` (when the goal is `¬ …`) or `by_contra h` |
| "By induction on n." | `induction n with \| zero => … \| succ k ih => …` |
| "a = b ≤ c = d" | `calc a = b := … _ ≤ c := … _ = d := …` |
| "Both directions." | `constructor` (on an ↔ goal) |
| "Substituting x = y …" | `rw [h]` |
| "By algebra." | `ring` (identities), `linarith` / `nlinarith` (inequalities) |
| "By arithmetic." | `norm_num`, `omega`, `decide` |
| "By a well-known theorem." | `exact?` |

## What you'll actually use, and where

I went through every quest's solutions. The whole expedition uses about 30 tactics, but the core is small:

**The everyday core** (used in 4 or more quests, and all covered in Q00 Orientation):

| Move | Quests |
|---|---|
| `norm_num` | T0 Q01 Q04 Q05 S1 S2 S3 A2 A3 |
| `rw [h]` (and `← h`, `at h`) | T0 Q02 Q03 Q04 S1 S3 A1 A2 A3 V2 |
| `decide` | Q01 Q02 Q04 Q05 S1 S3 A1 A3 V1 V3 |
| `exact` | T0 Q02 Q04 Q05 S2 A1 A2 A3 V1 V2 V3 |
| `intro` | T0 Q02 Q04 Q05 S3 A1 A3 V1 V2 V3 |
| `have` | T0 Q04 Q05 S2 S3 A1 A3 |
| `simp` | T0 Q03 Q04 Q05 S3 A1 A3 V1 V2 V3 |
| `⟨ ⟩` and `h.1` / `h.2` / `.mp` / `.mpr` | T0 Q02 Q05 S1 S2 S3 A1 A2 A3 V1 V2 V3 |
| `unfold` | Q04 S1 S3 A1 A2 V3 |
| `ring` | T0 Q03 S3 A2 A3 |
| `induction` | T0 Q03 Q04 A1 A3 V2 V3 |
| `linarith` / `nlinarith` | T0 Q03 Q04 S2 S3 A2 A3 |
| `obtain` / `rcases`, the `·` focus dot | T0 Q02 A1 A2 A3 V2 V3 |
| `#eval`, `def` (including pattern matching) | almost everywhere |

**Used in a few quests, taught where they appear:** `omega` (T0 Q03 Q06 A1 A3 V2 V3), `simp only [f]` to unfold your own definitions (Q03 S3 A3 V2 V3), `split_ifs` (A1 A3 V2 V3), `field_simp` (S2 S3 A1), `<;>` (S3 A1 A3 V1), `cases x <;> decide` to check every value of a small type (V1), `constructor`, `use`, `left` / `right` (T0 Q02 V2), `refine`, `exact_mod_cast`, `∑` sums (Q03 and four others).

**Specialist moves, one quest each:** `calc` (T0), `Nat.le_induction` (Q04), `#print axioms` and `native_decide` (Q05, Q07), `axiom`, `local instance` and `implemented_by` (Q07, where you use them to cheat on purpose), `rintro` with patterns (Q06), `split_ifs` and `induction … generalizing` (A1), `cases` on a custom type and `inductive` (S3, V1, V3), `structure` (S2, V1, V3), `deriving DecidableEq` and the record update `{ s with … }` (V1, V3), `List.Nodup` and `List.Perm` (V2), `interval_cases`, `push_cast`, `positivity` and `congr` (A3, the hard benchmark).

## Learning more

- **[Mathematics in Lean](https://leanprover-community.github.io/mathematics_in_lean/)** is the standard next step for math people.
- **[Theorem Proving in Lean 4](https://lean-lang.org/theorem_proving_in_lean4/)** explains how Lean works underneath.
- **[Functional Programming in Lean](https://lean-lang.org/functional_programming_in_lean/)** is Lean as a programming language. Good for the CS-minded.
- **[The Natural Number Game](https://adam.math.hhu.de/#/g/leanprover-community/nng4)** builds arithmetic from scratch, one level at a time. Great for a lazy evening.
- **[Lean Zulip, #new members](https://leanprover.zulipchat.com/)** is where the community answers beginner questions, kindly.
