import Mathlib

/-
  ┌──────────────────────────────────────────────────────────────┐
  │  STATISTICIAN'S PATH · S1 · MONTY HALL, VERIFIED  ⏱ 30–45 min│
  └──────────────────────────────────────────────────────────────┘

  Three doors. A car behind one, goats behind two. You pick a door. The host,
  who knows where the car is, opens a different door to show a goat. Should
  you switch?

  In 1990 Marilyn vos Savant answered "switch: you win 2/3 of the time."
  Around 10,000 readers wrote in to say she was wrong, nearly 1,000 of them
  with PhDs. Paul Erdős reportedly refused to believe it until he watched a
  computer simulation.

  We won't simulate. We will list every equally likely world and let Lean
  count them, which settles it for good. Then we change one detail of the
  story and watch the answer change.
-/

namespace S1

abbrev Door := Fin 3

def doors : List Door := [0, 1, 2]

/-- The host opens a door that is neither the car nor your pick
(if there's a choice, the lowest-numbered one; you'll see it doesn't matter). -/
def hostOpens (car pick : Door) : Door :=
  (doors.filter (fun d => d != car && d != pick)).headD 0

/-- Switching means moving to the door that is neither your pick nor the open one. -/
def switchTo (pick opened : Door) : Door :=
  (doors.filter (fun d => d != pick && d != opened)).headD 0

/-- All 9 equally likely worlds: (where the car is, which door you picked). -/
def games : List (Door × Door) :=
  [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2), (2, 0), (2, 1), (2, 2)]

def stayWins (g : Door × Door) : Bool := g.2 == g.1
def switchWins (g : Door × Door) : Bool := switchTo g.2 (hostOpens g.1 g.2) == g.1

-- Look at every world: (car, pick), the door the host opens, and whether switching wins.
#eval games.map (fun g => (g, hostOpens g.1 g.2, switchWins g))

/-- Probability = (number of worlds where `win` happens) / 9. -/
def prob (win : Door × Door → Bool) : ℚ := (games.filter win).length / games.length

/-! ## Puzzles -/

/-- 1 · In how many of the 9 worlds does staying win? -/
theorem stay_count : (games.filter stayWins).length = 3 := by
  sorry

/-- 2 · ...and switching? -/
theorem switch_count : (games.filter switchWins).length = 6 := by
  sorry

/-- 3 · Turn the count into a probability. -/
theorem stay_prob : prob stayWins = 1 / 3 := by
  sorry

/-- 4 · Same for switching. -/
theorem switch_prob : prob switchWins = 2 / 3 := by
  sorry

/-- 5 · The verdict, stated the way vos Savant's readers needed to hear it. -/
theorem switching_is_better : prob stayWins < prob switchWins := by
  sorry

/- 🧑‍🔬 ON THE JOB · The mechanism behind the data
   Same observation, different process, different answer. AI benchmarks
   work the same way: how problems were selected, filtered or leaked into
   training data changes what a score means. Asking "how was this sample
   generated?" is an evaluator's superpower.
-/

/-! ## 🐉 BOSS · "Monty Fall"

Change one detail. The host forgets where the car is, slips, and opens one
of the two other doors at RANDOM. It happens to show a goat. NOW should you
switch?

The worlds are now (car, pick, opened) with opened ≠ pick: 3 × 3 × 2 = 18
equally likely worlds. We only look at the ones where a goat was revealed.
-/

def fallGames : List (Door × Door × Door) :=
  (doors.flatMap fun car => doors.flatMap fun pick => doors.map fun o => (car, pick, o)).filter
    (fun g => g.2.2 != g.2.1)

def goatShown (g : Door × Door × Door) : Bool := g.2.2 != g.1
def fallSwitchWins (g : Door × Door × Door) : Bool := switchTo g.2.1 g.2.2 == g.1

#eval fallGames.length
#eval (fallGames.filter goatShown).length

/-- BOSS · Among the worlds where a goat was shown, switching wins EXACTLY half
the time. (Stated without division: wins × 2 = total.) -/
theorem monty_fall : ((fallGames.filter goatShown).filter fallSwitchWins).length * 2 =
    (fallGames.filter goatShown).length := by
  sorry

end S1

/-
  The statistician's moral, worth putting in your log: the data you SEE is the
  same in both games (a goat behind door #k), but the answer changes, because
  the process that generated the data changed. Conditioning depends on the
  mechanism, not only on the outcome.

  Stuck? `python3 scripts/expedition.py hint <puzzle>` reveals one hint at a time:
  first the idea, then the Lean move. Hints are logged so the Game Master can see
  where help was needed. There's no XP penalty; using hints well is part of the game.
-/
