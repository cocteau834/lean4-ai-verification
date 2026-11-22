# 🤖 Mini-Prover

**LLM proposes, Lean disposes.** This is a 300-line version of the loop behind AlphaProof, Aristotle and friends:

1. Find every `sorry` in a Lean file.
2. Ask a model for a tactic proof of that one theorem (it sees the whole file as context).
3. Splice it in and compile with Lean.
4. If Lean rejects it, send the error message back and let the model try again (`--attempts`, default 4).
5. Log every attempt to `runs/results.csv`.

## Setup

```bash
pip install -r tools/miniprover/requirements.txt
export ANTHROPIC_API_KEY=...        # ask the Game Master; or `ant auth login`
```

No key? Use `--manual`: the tool prints each prompt, you paste it into any chatbot, and you paste the reply back. Same loop, with you as the network cable.

## Use

```bash
# Try every sorry in a file, report only
python3 tools/miniprover/miniprover.py Players/You/quests/A3_MiniProver.lean

# Keep the proofs Lean accepts
python3 tools/miniprover/miniprover.py Players/You/quests/A3_MiniProver.lean --write

# Compare models: 4 independent runs per theorem, a cheaper model, lower effort
python3 tools/miniprover/miniprover.py capstone/bench/p01.lean --model claude-haiku-5-5 --effort low --repeat 4

# Just one theorem
python3 tools/miniprover/miniprover.py FILE.lean --only mp4 mp8
```

Defaults: `claude-opus-5-5` at `medium` effort. On models that support it, the tool turns on Anthropic's server-side refusal fallback, so a declined request is retried on another model. Other ids worth comparing: `claude-sonnet-5-5`, `claude-haiku-5-5`. The cost column uses list prices hard-coded in `PRICES`; double-check current pricing before quoting numbers.

## What's in the CSV

`run_id, timestamp_utc, file, theorem, model, effort, repeat, attempt, success, llm_seconds, lean_seconds, input_tokens, output_tokens, cost_usd, error`

One row per attempt. A theorem counts as solved in a run if any attempt in that run has `success = 1`. With `--repeat n`, each run is an independent conversation, so you can estimate **pass@k** with the unbiased estimator 1 − C(n−c, k) / C(n, k).

## Ideas for making it better (measure each one!)

- A better system prompt: a tactic cheat sheet, or "try `exact?`/`simp`/`omega`/`nlinarith` first".
- Ask for 3 candidate proofs per call and try them all.
- Send the *goal state* rather than the whole error (look up Lean's `extract_goal`).
- A cheap model first, then escalate to a bigger one only when it fails.
- Proof repair: when a proof almost works, ask for the smallest edit.
- A lemma library: keep successful proofs and show similar ones as examples (retrieval).

The honest-science rule: **a change only counts if it improves the solve rate on problems you didn't tune it on.**
