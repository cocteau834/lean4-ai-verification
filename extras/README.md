# Optional: put the Game Master on autopilot

By default the Game Master runs when **Dad** types `/gm` in Claude Code. That keeps a human in the loop, costs nothing extra on a Claude subscription, and lets him read everything before it's pushed. That's the recommended setup.

If you'd rather have the GM react on its own, this workflow adds two things:

| Trigger | What happens |
|---|---|
| A player pushes a change to `log.md` or `intake.md` | A **dispatch** pass runs, writes their `DISPATCH.md` (and sometimes a custom quest), and commits it |
| `@claude` in an issue or comment, e.g. "@claude hint for knightsB4?" | Claude replies as a hint-giving **tutor** |
| Actions → *Game Master (Claude)* → *Run workflow* | Run any pass by hand: `plan`, `dispatch`, `review` |

## Turning it on

1. **Install the Claude GitHub App** on the repo: <https://github.com/apps/claude>. Or run `claude` in a terminal inside the repo and use `/install-github-app`, which also offers to add the secret.
2. **Add the secret** `ANTHROPIC_API_KEY` (repo → Settings → Secrets and variables → Actions).
3. **Copy the workflow in:**
   ```bash
   cp extras/claude-game-master.yml .github/workflows/
   git add .github/workflows/claude-game-master.yml && git commit -m "Enable automatic Game Master" && git push
   ```

## Costs and caveats

- It's billed to the API key per run. A dispatch pass reads several files and compiles Lean, so expect roughly a dollar or two per pass with Opus (less with `--model claude-sonnet-5-5`, which you can set in the workflow's `claude_args`). Two players logging once a day comes to a modest amount over a break; check your usage in the Anthropic Console.
- Automatic passes can't see `instructor/` (it never leaves Dad's machine), so **review passes are best run locally**, where the private report can be written.
- Each automatic pass commits straight to `main`. Players should keep doing `git pull` at the start of each session (they already do).
