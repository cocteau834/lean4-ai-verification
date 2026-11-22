# Players

One folder per verifier. Create yours with:

```bash
python3 scripts/expedition.py join YourName
```

Inside your folder:

| File | Who writes it | What it's for |
|---|---|---|
| `intake.md` | you, once | Basecamp: who you are and what you like. Your route is planned from it. |
| `quests/` | the Expedition drops quests here; you solve them | Your copies of each quest. Edit freely. |
| `log.md` | you, after each session | Two minutes of notes. This is how you steer what comes next. |
| `MAP.md` | the engine, after every push | Your progress map, rank, badges and next steps. |
| `DISPATCH.md` | the Game Master | Feedback, hints and new side quests made for you. |
| `CAREER_CARDS.md` | the engine, after every push | One card per cleared quest: where the skill shows up in real jobs. |
| `ROUTE.md`, `route.json` | the Game Master | Your personal route (appears after your intake is read). |
| `hints.json` | the `hint` command | Which hints you've revealed (the Game Master uses it to see where to help). |
| `detours.json` | the `detour` command | Detour tokens you've spent. |

`_template/` is what new players start from. Leave it alone.

Removing a player (for example a test player): `python3 scripts/expedition.py leave Name --yes`, then commit and push.
