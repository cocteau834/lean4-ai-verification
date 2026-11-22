# Why Lean, why now

*Written November 22, 2026. The Game Master adds to this as news happens. Every item links to a source; dispatches should only cite things that are here or that have been checked.*

## The week this course was written: the Riemann Hypothesis

**The problem.** In 1859 Bernhard Riemann guessed that every "nontrivial" zero of the zeta function ζ(s) has real part exactly ½. If true, it pins down how the prime numbers are distributed, as precisely as possible. It's one of the Clay Millennium Problems ($1,000,000 prize) and has been the most famous open question in mathematics for over 160 years.

**August 2026: a warm-up.** Anthropic reported that an unreleased research version of Claude, asked by a staff member to "take a real stab" at RH, failed at the full problem. Along the way, though, it improved a long-standing bound: it showed at least **67.2%** of the zeta function's zeros lie on the critical line, up from **41.6%**. The result came with a Lean formalization (worked on with Anthropic staff member Eric Easley) that passes the community's statement-checking tool `comparator`, and experts Brian Conrey and Dan Goldston reviewed the paper. Anthropic said explicitly that it did not expect these techniques to lead to a proof of RH itself. ([Anthropic](https://www.anthropic.com/research/riemann-zeta))

**November 20, 2026: the claim.** Levent Alpöge, a mathematician at Anthropic, released a Lean library of about **17 million lines** (around 175,000 files), written with Claude, that claims to prove the Riemann Hypothesis. He also claims it extends to the Generalized Riemann Hypothesis for Dirichlet L-functions. The headline theorem is stated using Mathlib's own `RiemannHypothesis` definition, and the code depends only on Mathlib. ([mirror and README](https://github.com/CocoSgt/riemann-hypothesis-lean))

**November 21, 2026: the verification.** In a joint statement endorsed by the Lean FRO and the Mathlib Initiative, the Lean and Mathlib communities said they have *"full confidence that Alpöge's proof of the Riemann Hypothesis is correct."* ([Lean community blog](https://leanprover-community.github.io/blog/posts/riemann-hypothesis/)) How they got there in about a day:

- **It compiles.** Dozens of people built the library independently and got the same proof export.
- **The proof is valid.** The exported proof was re-checked by Lean's kernel and by several independent checkers written in other programming languages, run on an inert export so that no code in the proof sources could interfere.
- **The statement is really RH.** A separate file isolates the theorem statement and imports only Mathlib, and two independent tools confirmed the proved theorem is exactly Mathlib's `RiemannHypothesis`, a definition number theorists had vetted long before.

**What it doesn't settle yet.** Mathematicians are quick to point out that a *checked* proof is not an *understood* proof. Nobody can yet explain the new ideas in plain mathematics, and Alpöge has said he wants to simplify and explain the argument. Manchester's Thomas Bloom noted that written out for humans it would run to 250,000+ pages, and others stressed that a machine-checked proof can tell you *that* something is true long before anyone understands *why*. ([reactions](https://officechai.com/ai/how-mathematicians-have-reacted-to-claimed-riemann-hypothesis-proof-by-anthropics-levent-alpoge/), [Scientific American](https://www.scientificamerican.com/article/what-the-riemann-hypothesis-proof-really-means-about-ai-and-the-future/))

**Why it matters for you.** This is the clearest demonstration yet of the idea behind this whole course: **you don't have to trust the AI, or the author, if you can trust the checker.** Quest Q05 (*The RH Audit*) has you run the same three checks yourself: compile, `#print axioms`, and statement matching.

## The road here (2024–2026)

| When | What | Why it matters |
|---|---|---|
| Jul 2024 | Google DeepMind's **AlphaProof** reaches silver-medal level at the International Math Olympiad, with proofs written in Lean. | The first big "LLM + Lean" result. |
| Jul 2025 | Harmonic's **Aristotle** reaches gold-medal level at IMO 2025 with Lean-verified solutions. | Formal and verified, not just "the model says so". |
| Dec 2025 | **AxiomProver** reports Lean-checked solutions to all 12 Putnam 2025 problems. ([benchmark comparison](https://arxiv.org/pdf/2605.20120)) | College-level competition math, machine-checked. |
| Feb–Mar 2026 | Math, Inc.'s **Gauss** completes Lean proofs of Viazovska's sphere-packing theorems (Fields Medal work): dimension 8 together with human formalizers, then dimension 24 working mostly from the original paper. ([EPFL](https://actu.epfl.ch/news/prof-viazovska-s-proofs-of-sphere-packing-formaliz/), [IEEE Spectrum](https://spectrum.ieee.org/ai-proof-verification)) | AI formalizing frontier research mathematics. |
| May 2026 | DeepMind's **AlphaProof Nexus** resolves 9 open Erdős problems (two open for 56 years) and 44 OEIS conjectures, for a few hundred dollars each, with all proofs in Lean. ([paper](https://arxiv.org/abs/2605.22763), [The Decoder](https://the-decoder.com/google-deepminds-alphaproof-nexus-solves-decades-old-math-problems-for-a-few-hundred-dollars/)) | AI solving genuinely open problems, with proofs anyone can check. |
| Aug 2026 | Claude improves the critical-line zero bound, from 41.6% to 67.2%, Lean-verified. ([Anthropic](https://www.anthropic.com/research/riemann-zeta)) | See above. |
| Oct 2026 | An **AI-assisted Lean formalization of the Poincaré conjecture** (Perelman's proof) appears. ([arXiv](https://arxiv.org/abs/2610.08329)) | Huge geometric proofs are now in reach. |
| Nov 2026 | The Riemann Hypothesis, in Lean. | See above. |

## Not just math: verified AI in industry

- **Code an AI wrote, proved correct.** The direction of travel is that AI generates code *and* a proof that it meets its spec, and a checker like Lean verifies the proof. Quest A1 (*Bug Bounty*) is a miniature version.
- **AWS** uses Lean in production. **Cedar**, the authorization-policy language, is verified in Lean, and **SampCert** is a Lean-verified implementation of differential-privacy sampling (the math in Quest S3). ([SampCert](https://github.com/leanprover/SampCert))
- **Neural-network verification** proves that a network's output can't flip under small input changes (robustness) and is an active research and competition area (VNN-COMP). Quest A2 builds a certificate by hand.
- **"Guaranteed safe AI"**: research programs such as the UK's ARIA *Safeguarded AI* aim to put formal, checkable guarantees around powerful AI systems.

## What this means for a statistician and an AI engineer

- **For AI:** the frontier systems above are all *search plus verification* loops. Knowing how the verifier works, and what it does and doesn't guarantee, is a rare and valuable skill. Building and *evaluating* such loops (Quest A3 and the capstone) is real research-engineering work.
- **For statistics:** benchmarks and evaluations of AI provers are a statistics problem. Small samples, pass@k estimators, paired comparisons, contamination and honest uncertainty all come into it. Formal verification is also showing up in privacy (differential privacy) and in verified numerical code.
- **For both:** "Can you verify it?" is becoming the question that separates a demo from something you can deploy.
