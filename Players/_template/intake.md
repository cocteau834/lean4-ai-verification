# 🏕️ Basecamp: {{NAME}}'s intake

**15–20 minutes. No wrong answers.** The Game Master (Claude, with a human in the loop) reads this and plans **your** route: where you start, what you skip, which quests get built just for you. Nobody else's route will look like yours.

Replace each *answer here* line with your answer (a few words is fine). Tick boxes by changing `[ ]` to `[x]`. When every *answer here* line is filled in, Basecamp counts as ✅ and you get 20 XP. Lines marked *optional* are optional.

---

**First, the important question. Pick your expedition animal** (one emoji, or just type the animal's name; it appears next to your name on your map and the scoreboard, e.g. 🦦 🐧 🦊 🐙):
_answer here_

Every quest also hides an egg 🥚. Clear the quest and an animal companion hatches into your menagerie. There are 20 to collect.

## Why this game exists (2-minute read)

AI can now write proofs, code and plans faster than anyone can check them by hand. So one question gets more valuable every year: **how do we know it's right?**

Lean is one of the best answers so far. It's a programming language in which a small, trusted program (the *kernel*) checks every step of a proof. Once Lean accepts something, you don't have to trust whoever wrote it, human or AI. That's why:

- the Lean community certified a 17-million-line proof of the Riemann Hypothesis, written with Claude, in about a day ([docs/WHY_NOW.md](../../docs/WHY_NOW.md));
- AI labs use Lean to train and grade AI systems on math, because its verdict can't be argued with;
- AWS uses Lean to prove that access-control and privacy code it runs for customers does what it claims.

You don't have to want a job "in Lean" for this to matter. The habits it trains (saying exactly what you mean, checking evidence instead of trusting confidence, asking what a guarantee does *not* cover) are what's asked of anyone who builds, evaluates or relies on AI: engineers, data scientists, statisticians, researchers and analysts. [docs/CAREERS.md](../../docs/CAREERS.md) has real job titles.

## 1 · The field tour: seven regions

Every quest is rated on these seven regions, so this tour is also the key to the quest map. The first three are about **what** gets verified. The last four are about **verifying AI**: checking what it produces, keeping it safe, measuring it, and knowing what a check really guarantees.

Read each one (about 30 seconds), then rate it: **0** not for me · **1** curious · **2** interested · **3** sign me up. These are a first guess, not a contract. Change them whenever you like; the Game Master compares them with what you actually enjoy.

### 🧮 Pure math
Proving things about numbers, functions and structures. It's where Lean started, and still where AI provers are tested hardest.
**Out there:** Mathlib, Lean's shared math library, holds hundreds of thousands of theorems. In 2026 AI systems solved open Erdős problems in Lean, and the Riemann Hypothesis proof was checked in it.
**Main focus in:** T0 · Proof Gym, Q04 · The Oracle Lies.
**My interest (0–3):** _answer here_

### 🎲 Statistics & probability
Proving facts about chance and data: that an estimator is unbiased, that a privacy mechanism really protects people, why a paradox happens. Still rare in Lean, which makes it a gap worth filling.
**Out there:** AWS's SampCert is a Lean-verified implementation of differential privacy, the math behind privacy-safe data releases. And AI evaluation runs on statistics: is a 4-point improvement real, or noise?
**Main focus in:** S1 · Monty Hall, S2 · Simpson's Paradox, the CAPSTONE.
**My interest (0–3):** _answer here_

### 💻 Verified software & policies
Proving that code, configurations and access rules do what they claim, for every input, not just the inputs you tested.
**Out there:** AWS's Cedar access-control language is verified in Lean, and companies like AWS, Microsoft and chip makers employ verification engineers. Much of this work also uses other tools (Dafny, Verus, Rocq); the ideas carry over.
**Main focus in:** A1 · Bug Bounty, V1 · The Policy Engine, V2 · Vericoding.
**My interest (0–3):** _answer here_

### 🤖 Checking AI output
Deciding whether something an AI produced (a proof, a formal statement, code, a spec, a policy change) is what was actually asked for. Lean checks the proof; a person still has to check that it proves the right thing.
**Out there:** AI companies pay reviewers to check AI-written Lean, and as AI writes more code, reviewing its specs becomes the human's main job.
**Main focus in:** Q04 · The Oracle Lies, Q06 · Spec Review, A1 · Bug Bounty, V2 · Vericoding.
**My interest (0–3):** _answer here_

### 🛡️ AI safety & security
Proving that a system *can't* do certain harmful things: a classifier can't be flipped by tiny noise, a data release can't expose one person, an AI agent can't overspend, a grader can't be gamed.
**Out there:** robustness certificates for neural networks, differential privacy, guardrails for AI agents, and research programs such as the UK's ARIA *Safeguarded AI*. Most safety work doesn't use Lean; in the formal-methods corner, it's a real edge.
**Main focus in:** Q07 · Red-Team the Grader, A2 · Neural Net Safety, V3 · Agent Guardrails.
**My interest (0–3):** _answer here_

### 📏 Evaluation & benchmarks
Measuring AI systems honestly: building test sets, running models, and telling a real improvement from luck. Lean problems make great benchmarks because every answer is checked automatically.
**Out there:** every AI lab has evaluation teams, and government AI institutes and independent evaluators test models before release.
**Main focus in:** A3 · Build a Mini-Prover, the CAPSTONE (SiblingBench).
**My interest (0–3):** _answer here_

### 🔍 Trust & auditing
Knowing exactly what "verified" guarantees, and what it doesn't: a hidden axiom, a statement that quietly drifted from the original, a grader an AI could fool.
**Out there:** this is how the Riemann Hypothesis proof was certified in a day: independent rebuilds, independent checkers, and tools confirming that the statement really was RH.
**Main focus in:** Q05 · The RH Audit, Q06 · Spec Review, Q07 · Red-Team the Grader.
**My interest (0–3):** _answer here_

The full table, with every quest rated on all seven, is in [docs/QUEST_GUIDE.md](../../docs/QUEST_GUIDE.md).

## 2 · Where you're coming from

**School, year, major(s):**
_answer here_

**Proof-based math so far.** Which courses, if any? (Discrete math, intro to proofs, real analysis, abstract algebra, ...)
_answer here_

**Programming.** Languages you're comfortable in, and roughly how comfortable (e.g. "Python: very, R: daily, Java: one class"):
_answer here_

**Stats / ML / AI courses taken or in progress:**
_answer here_

**Git and GitHub.** How at home are you? (never used / I push and pray / fluent)
_answer here_

**Ever touched a proof assistant (Lean, Coq/Rocq, Isabelle) or the Natural Number Game?**
_answer here_

## 3 · Rate yourself (1 = "what's that", 5 = "could teach it")

Replace the `?` with a number.

| Skill | 1–5 |
|---|:---:|
| Writing proofs by hand | ? |
| Induction | ? |
| Logic (∀, ∃, →, ¬) | ? |
| Probability | ? |
| Statistical inference (estimators, CIs, tests) | ? |
| Linear algebra | ? |
| Neural networks / deep learning | ? |
| Using LLM APIs in code | ? |
| Functional programming | ? |

## 4 · What else sounds fun? (tick as many as you like)

- [ ] Logic puzzles (knights & knaves, riddles)
- [ ] Famous math (primes, the Riemann Hypothesis, irrational numbers)
- [ ] Building tools: an AI that writes proofs
- [ ] Breaking things on purpose (red-teaming, finding loopholes)
- [ ] Competing with my sibling
- [ ] Cooperating with my sibling
- [ ] Something I could show an employer
- [ ] Other: _optional_

**One topic from your classes or life you'd love to see turned into a quest** (seriously, anything: a stats method, a game, a sport, an algorithm):
_answer here_

## 5 · How you like to play

**When you're stuck, do you prefer** (pick one: a nudge / a worked example / to grind it out / to ask an AI)?
_answer here_

**Short and many, or long and deep?** (e.g. "lots of 5-minute puzzles" vs "one big problem per session")
_answer here_

**Roughly how many sessions over break do you realistically see yourself doing?** (honest guesses welcome, zero judgment)
_answer here_

**Anything that would make this feel like homework, so the Game Master can avoid it?**
_answer here_

## 6 · Where you might be headed (optional, but it helps)

Do any of these sound interesting? [docs/CAREERS.md](../../docs/CAREERS.md) explains what each one involves. The Game Master uses your answers to point quests at the skills those jobs need.

- [ ] Research engineer or scientist on an AI-for-math / AI-reasoning team
- [ ] Formalization: writing and checking Lean for AI systems or big math projects
- [ ] Formal verification of software (proving code correct)
- [ ] AI safety and alignment research
- [ ] Evaluating AI systems (benchmarks, statistics, red-teaming)
- [ ] Data science or statistics, with AI on the side
- [ ] Grad school in math, CS or statistics
- [ ] No idea yet (totally fine)

**Jobs or fields you're curious about, in your own words:**
_optional_

**What do you already think about AI that writes math or code? Excited, skeptical, both?**
_optional_
