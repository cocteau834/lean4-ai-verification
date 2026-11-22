# Cheat sheet

One page of moves. For how to think about them, how to get unstuck and how to search Mathlib, see the [Field Guide](FIELD_GUIDE.md).

## Reading the Infoview

```
h : P ∧ Q          ← things you HAVE (hypotheses)
n : ℕ
⊢ Q ∧ P            ← your GOAL (after ⊢)
```

"No goals" means you won. Click anywhere in a proof to see the state at that point.

## Tactics by goal shape

| Goal or hypothesis looks like | Try |
|---|---|
| `P → Q` or `∀ x, ...` | `intro h` / `intro x` |
| exactly matches a hypothesis `h` | `exact h` (or `assumption`) |
| `Q`, and you have `f : P → Q` | `apply f` |
| `P ∧ Q` | `constructor`, or `exact ⟨hp, hq⟩` |
| hypothesis `h : P ∧ Q` | `obtain ⟨hp, hq⟩ := h` |
| `P ∨ Q` | `left` / `right` |
| hypothesis `h : P ∨ Q` | `rcases h with hp \| hq` |
| `∃ x, P x` | `use 42` |
| hypothesis `h : ∃ x, P x` | `obtain ⟨x, hx⟩ := h` |
| `¬ P` | `intro h` (then prove `False`) |
| `a = b` that's true by computation | `rfl`, `decide`, `norm_num` |
| rewrite with `h : a = b` | `rw [h]`, or `rw [← h]` for right-to-left |
| algebra identity (+, ×, ^) | `ring` |
| linear inequality from hypotheses | `linarith` |
| inequality that needs squares or products | `nlinarith [sq_nonneg (a - b)]` |
| integer/natural arithmetic, no multiplication of variables | `omega` |
| goal with fractions | `field_simp` then `ring` |
| finite check (small numbers, Bools, lists) | `decide` |
| "for all n" about ℕ | `induction n with \| zero => ... \| succ k ih => ...` |
| a famous fact | `exact?` (searches Mathlib); also `apply?`, `rw?` |
| messy but probably easy | `simp`, `simp at h`, `norm_num at h` |
| definition in the way | `unfold foo`, or `simp [foo]` |
| case split on an `if` | `split_ifs` |
| every value of a small type (roles, actions...) | `cases r <;> decide` (or `<;> rfl`) |

Combinators: `t1 <;> t2` runs t2 on every goal t1 produced. `·` focuses on one goal.

## Typing symbols

`\to` → · `\and` ∧ · `\or` ∨ · `\not` ¬ · `\iff` ↔ · `\forall` ∀ · `\ex` ∃ · `\N` ℕ · `\Z` ℤ · `\Q` ℚ · `\R` ℝ · `\le` ≤ · `\ge` ≥ · `\ne` ≠ · `\<` ⟨ · `\>` ⟩ · `\l` ← · `\sum` ∑ · `\sub1` ₁

## Error messages decoded

| Lean says | Usually means |
|---|---|
| `unsolved goals` | The proof stopped early. Look at what's left in the Infoview. |
| `type mismatch` | You gave something of the wrong shape. Compare the expected type with what you gave. |
| `unknown identifier 'foo'` | Typo, or the lemma has a different name. Try `exact?`. |
| `linarith failed` | The fact isn't linear, or a hypothesis is missing. Add hints: `linarith [h1, h2]`. |
| `decide failed ... evaluates to false` | You asked it to check something false. Good news: Lean caught it! |
| `maximum recursion depth` | `decide` ran on something too big. Use `norm_num` or real reasoning. |
| `declaration uses 'sorry'` | Not an error: an unsolved puzzle. |

## Git in five commands

```bash
git pull                    # get the latest (new quests, dispatches)
git status                  # what changed?
git add -A                  # stage everything
git commit -m "message"     # save a snapshot
git push                    # send it to GitHub
```

Push rejected? `git pull --rebase`, then `git push`. Merge conflict in `MAP.md` or `README.md` during that rebase? Those files are regenerated anyway, so keep GitHub's copy: `git checkout --ours <file>` (mid-rebase, "ours" means the GitHub side), then `git add <file>` and `git rebase --continue`.
