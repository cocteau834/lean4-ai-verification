# 🧑‍🔬 Where this leads

Every quest in this repo is a small version of something people get paid to do. This page says what those jobs are actually called, what a working day looks like, which skills matter, and where the game trains each one.

*Written November 2026. Job titles and employers change fast, so treat the names below as search terms, not a directory.*

## What the jobs are called

Titles like "AI proof researcher" or "AI alignment analyst" don't really exist. Here are the ones that do:

| Area | Titles to search for | Who hires (examples) | Lean every day? |
|---|---|---|---|
| **AI for math / formal reasoning** | Research Engineer, Research Scientist, Member of Technical Staff (AI for Math, Reasoning, Formal Methods) | AI labs and startups building provers: Google DeepMind, Harmonic, Axiom, Math, Inc., Anthropic, OpenAI and others | Yes |
| **Formalization** | Formalization Engineer, Lean Engineer, formal-math contractor or annotator | The same companies (they need people who write and *check* Lean), the Lean FRO, the Mathlib Initiative, university formalization projects | Yes |
| **Automated reasoning in industry** | Applied Scientist (Automated Reasoning), Formal Verification Engineer | AWS (Cedar and SampCert are verified in Lean), Microsoft, Galois, chip, security and finance companies | Often (Lean, Dafny, Rocq, SMT solvers) |
| **AI safety via formal methods** | Research Scientist or Engineer working on verified code, specifications and "guaranteed-safe AI" | Safety research groups and funded programs such as the UK's ARIA *Safeguarded AI* | Sometimes |
| **AI evaluation** | Research Engineer (Evaluations), Evaluation Scientist | AI labs, government AI Security Institutes, independent evaluators such as METR | Rarely, but the skills (benchmarks, statistics, adversarial testing) transfer directly |

## Lean beyond pure math

Much of the Lean work happening right now has nothing to do with the Riemann Hypothesis:

- **Verified software and policies.** AWS's Cedar is a language companies use to write access rules ("who may read this file?"). Its behavior is modeled and proved in Lean, including properties like "a forbid rule always beats a permit." Quest V1 builds a small version, down to checking an AI's policy change. SampCert, the privacy library from Quest S3, is the same idea: proving that the code which actually runs does what it claims.
- **Checking AI-written code.** AI writes a lot of code now. In *verified code generation* (sometimes called "vericoding"), the AI writes the code, a specification and a proof, and the human's job becomes judging whether the spec is right. The classic trap is in Quest Q06: "the output is sorted" is satisfied by a function that always returns the empty list. Quest V2 is a whole review of an AI's code + spec + proof.
- **Safety properties of AI systems.** Robustness certificates for neural networks (A2), privacy guarantees (S3), and invariants for AI agents that act in the world ("never spends more than the budget", Quest V3).
- **Evaluation and training infrastructure.** Graders, benchmarks and verified problem sets for AI labs (Q07, A3, the capstone).

Two honest caveats. AI-for-math teams are still where Lean is used most intensively at AI companies, and strong math is an advantage everywhere in this field. And much software verification uses other tools (Dafny, Verus, Coq/Rocq, SMT solvers). The ideas carry over directly: specs, proofs, trust, and what a check really guarantees. Lean is one strong way to learn them.

One honest note on safety jobs: most AI-alignment jobs never touch Lean. In the formal-methods corner of safety, Lean is a real differentiator. Everywhere else, the habits this game builds still carry over: precise specifications, evidence someone else can check, adversarial testing and honest statistics.

## A day in the life

*Sam is a composite, not a real person: a research engineer on an AI-for-math team.*

| Time | What Sam does | Where you practice it |
|---|---|---|
| 9:00 | Reads the overnight run. The prover attempted 5,000 Lean problems; Sam samples the failures. Timeouts? Wrong tactics? Or did the model find a way to *cheat* the checker? | A3, Q07 |
| 10:30 | **Statement review.** A new pipeline turned 300 informal problems into Lean statements. Sam flags the ones that don't mean what the original says: a dropped hypothesis, natural-number subtraction, division by zero quietly equal to 0. | Q06, Q05, A1 |
| 12:00 | Infrastructure. A Mathlib upgrade broke 3% of the stored proofs, so Sam writes a script to re-check and repair them. | the Expedition engine itself, A3 |
| 14:00 | Writes Lean by hand: a lemma the model keeps failing on, to understand why. If it's general, Sam opens a pull request to Mathlib. | every quest |
| 15:30 | Evaluation meeting. The new model beats the old one on a held-out benchmark by 4 points. Is that real? pass@k with confidence intervals, a paired test, a contamination check. | S1, S2, CAPSTONE |
| 17:00 | Writes it up for the team and answers a beginner's question on the Lean Zulip. | logs, CAPSTONE report |

For someone doing **AI safety with formal methods**, the same day tilts toward writing specifications of what a system must never do, checking that a proof actually covers the risk people care about (and not a convenient neighbor of it), and red-teaming the checker before an AI finds the hole.

## The skill map

Ten skills employers in this space look for, where the game trains each one, and how to go further. (To pick quests by *topic* instead, see the seven regions in the [Quest Guide](QUEST_GUIDE.md).)

| # | Skill | Trained in | Going further |
|---|---|---|---|
| 1 | **Lean fluency**: read goals, choose moves, read errors | Q00 to Q03, then every quest | *Mathematics in Lean*; one Mathlib pull request |
| 2 | **Finding things in Mathlib** | `exact?` everywhere, Q04, Q05, the [Field Guide](FIELD_GUIDE.md) | Loogle, LeanSearch, Mathlib naming conventions |
| 3 | **Formalization**: turning words into exact statements | T0, Q02 (encoding knights and knaves), S2 (building a paradox), V1 and V3 (modeling a system as types, rules and states) | Formalize one lemma from a course you took |
| 4 | **Statement review**: does the formal version mean what the words mean? | **Q06** (the misformalization hunt), **V2** (reviewing and strengthening an AI's spec), Q05 (vacuous and weakened statements), A1 (ℕ subtraction) | Have an AI formalize statements from your courses and review them |
| 5 | **The trust model**: kernel, axioms, `sorry`, `native_decide`, what "verified" actually guarantees | Q05 | Read the Lean community's RH verification statement; run `#print axioms` on your own work |
| 6 | **Adversarial thinking**: how optimizers (and AIs) game checkers | **Q07** (red-team the grader), V3 (jailbreaking an agent guardrail), V1 (finding the leak in a policy change), Q05, the *Break the Expedition* bounty | Harden the mini-prover's checks; read about reward hacking and specification gaming |
| 7 | **ML for theorem proving**: LLM loops, search, verifier feedback | A3, CAPSTONE | Add retrieval or best-of-n to the mini-prover and measure it |
| 8 | **Evaluation and statistics**: benchmarks, pass@k, confidence intervals, confounding | S1, S2, A3, CAPSTONE | Stratified results, contamination checks, cost-normalized comparisons |
| 9 | **Verification beyond math**: programs, policies, privacy, neural networks, AI agents | A1, **V1–V3**, S3, A2 | Dafny or Verus for code; SampCert for privacy; VNN-COMP for networks |
| 10 | **Engineering and communication**: git, CI, Python, clear write-ups | every push, your logs, the CAPSTONE report | Clear PR descriptions; one public write-up |

## What makes an applicant stand out

- **Public, checkable work.** A repo with real Lean proofs, a tool you built and a write-up. This one counts, especially the capstone.
- **One contribution to a big formal library.** Even a small Mathlib pull request (a lemma or a docstring) shows you can work inside a huge codebase with code review.
- **Evidence of judgment.** A write-up of something that *didn't* work, and why, says more than a list of successes.
- **The adjacent fundamentals.** Python and ML basics for the AI side; probability and statistics depth for the evaluation side; proofs for both.
- **Being part of the community.** Asking good questions (and later answering them) on the Lean Zulip gets noticed.

## After the break

1. Finish the capstone and write it up properly. It's the single best portfolio piece here.
2. Work through *Mathematics in Lean* (free online).
3. Formalize one lemma you proved in a class, then post it on the Lean Zulip or open a Mathlib pull request.
4. Read three primary sources: the AlphaProof paper, the Lean community's Riemann Hypothesis statement, and Anthropic's zeta-zeros write-up (links in [WHY_NOW.md](WHY_NOW.md)).
5. Look at summer options: math or CS research programs (REUs), community events such as *Lean Together*, and alignment fellowships such as MATS.

Your **career cards** (in `Players/<you>/CAREER_CARDS.md`) collect one of these connections for every quest you clear.
