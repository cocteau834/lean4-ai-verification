# Game Master's journal

The GM's memory between passes (Claude remembers nothing on its own). Append a dated entry after every pass: what you saw, what you changed, what to watch next time. Keep it kind and factual. Players can read it.

---

## 2026-11-22 · setup

- Expedition created: Basecamp intake (B00); Q00 Orientation (everyone's first quest); Q01–Q05 (core); T0 Proof Gym (optional, for rusty provers); S1–S3 (stats); A1–A3 (AI); co-op CAPSTONE.
- Q06 Spec Review and Q07 Red-Team the Grader open after Q05; keep them on every route (statement review and adversarial thinking are the two most career-relevant skills).
- Players get 2 detour tokens and a logged hint ladder for every puzzle (`Quests/hints/`).
- No players yet. First pass will be **plan**, once both intakes are ✅ on the scoreboard.
- Watch for: the two players have different backgrounds (statistics senior; AI + math sophomore). Routes should diverge from day one.

## 2026-11-22 · quest ratings and the Verified Systems path

- New track **Verified Systems Path**: V1 · The Policy Engine (opens after Q02), V2 · Vericoding and V3 · Agent Guardrails (both open after V1 and Q03). Badge 🏛️ Systems Verifier. The capstone now also opens after V2.
- Every quest is rated on seven regions (🧮 math, 🎲 stats, 💻 software & policies, 🤖 checking AI output, 🛡️ AI safety & security, 📏 evaluation, 🔍 trust & auditing) in `quests.json`. `docs/QUEST_GUIDE.md` is generated from the ratings.
- The intake now opens with "why this game exists" and a field tour of the seven regions, with an interest rating (0–3) after each. The engine reads them (`interests` in `report`), logs re-ratings in the trail, and shows each player their matches and their mix so far.
- Watch for: stated interests vs. what each player actually does. Interests are a first guess.

