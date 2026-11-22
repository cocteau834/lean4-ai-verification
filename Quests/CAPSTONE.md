# 🤝 CAPSTONE · SiblingBench (co-op)

*Unlocked once either of you is deep into a path. Several sessions. This is the portfolio piece.*

You'll build a **small benchmark of theorem statements**, use your mini-prover to test **several AI models** on it, and do a **real statistical analysis** of the results. Each of you brings a different strength, and the project needs both.

The research questions: **how much better is a bigger (and more expensive) model at producing Lean proofs, is it better at math or at code, and are the differences statistically real?**

This is a scaled-down version of what AI labs do with benchmarks such as miniF2F and PutnamBench. Doing it carefully, with honest uncertainty, is exactly the skill employers look for.

## The plan

| Step | What | Who leads |
|---|---|---|
| 1 | Write **20 theorem statements** in `capstone/bench/` (one file each, ending in `:= by sorry`). Mix easy and hard, and **mix math with code**: properties of small programs (sorting, searching, access rules) as well as stats- and math-flavored theorems. A sharp research question falls out for free: *are AI provers better at math or at verifying code?* **Every statement must be true.** Prove each one yourselves first, or have the Game Master verify it. | both |
| 2 | Run `tools/miniprover/miniprover.py` on every problem with **at least 2 models** (e.g. `claude-haiku-5-5`, `claude-sonnet-5-5`, `claude-opus-5-5`) and **n ≥ 4 independent runs** each. Keep every row of `results.csv`. | the prover builder |
| 3 | Analysis in Python or R (`capstone/analysis/`): **pass@k** with the unbiased estimator 1 − C(n−c, k)/C(n, k) (Chen et al., 2021), **bootstrap confidence intervals**, a **paired test** between models (McNemar or a permutation test), **cost per solved problem**, and one model of difficulty (what makes a statement hard?). | the statistician |
| 4 | Write `capstone/REPORT.md`: question, method, results with figures and intervals, limitations (only 20 problems! contamination?), and what you'd do next. | both |
| 5 | Optional flex: prove something about your own method **in Lean**, e.g. that the pass@k estimator gives exactly 1 when c = n, or check a small case by `decide`. | whoever's having fun |

**Done when:** `capstone/REPORT.md` exists and you're both proud of it. The Expedition marks the capstone complete when that file appears.

## How to present it

When it's done, the capstone is worth showing. Make it easy to read:

- `capstone/REPORT.md` opens with a three-sentence summary: question, answer, how sure you are.
- One figure that carries the main result (solve rate by model, with intervals).
- A **Limitations** section you'd be comfortable defending in an interview: sample size, contamination risk, what you didn't control.
- Résumé line: *"Designed a 20-problem formal-math benchmark in Lean 4 and evaluated several LLM provers (pass@k, bootstrap CIs, paired tests); open-source tool and report."*
- Each of you can pin the repo, or a cleaned-up copy of the capstone, on your own GitHub profile.

## Why this matters

- It's a complete, honest, *small* research project: data you generated, a tool you built, uncertainty you quantified.
- The commit history shows how you worked, not just what you got.
- It sits right where AI, verification and statistics meet, which is where a lot of hiring is happening right now.

The Game Master will check in on the capstone during review passes and can scope it up or down.
