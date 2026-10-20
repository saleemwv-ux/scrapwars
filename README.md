# ScrapWars

A 1v1 real-time card battler set in a junkyard full of scrap robots. Two lanes,
a river of oil sludge, elixir, princess towers and a king tower, against a
computer opponent. Built with **Godot 4** and GDScript; all art is drawn in
code as placeholders.

![ScrapWars gameplay](docs/screenshot.png)

## How to open and play it

1. Download **Godot 4** (4.3 or newer, the standard version, *not* the .NET one) from
   <https://godotengine.org/download>. Unzip it; there's nothing to install.
2. Download this repository: on GitHub press **Code → Download ZIP**, then unzip it.
3. Start Godot. In the Project Manager click **Import**, browse to the unzipped
   folder and pick `project.godot`, then click **Import & Edit**.
4. Press the **Play** button (▶) at the top right, or press **F5**.

## How to play

- Tap (or click) a card, then tap your half of the arena to deploy it. You can also drag a card onto the arena.
- Cards cost elixir. Elixir refills over time, up to 10. In the last minute it refills twice as fast.
- Destroy a princess tower to earn a crown and unlock deploying on that side of the enemy's half.
- Destroying the king tower wins instantly. Otherwise, after 3 minutes the side with more crowns wins.
  If crowns are tied there's 1 minute of sudden-death overtime, then the side whose weakest tower is healthier wins.
- The king tower sleeps until it's hit or one of its princess towers falls.

## Cards

| Card | Cost | What it does |
| --- | --- | --- |
| Scrapper | 3 | Tough melee bot with a giant wrench. Hits ground only. |
| Bolt Archers | 3 | Two ranged bots. Hit air and ground. |
| Junk Giant | 5 | Slow, very tough tank. Only attacks buildings. |
| Drone Swarm | 3 | Three flying drones. Hit air and ground. |
| Gear Gremlins | 2 | Four fast, fragile biters. |
| Magnet Cannon | 3 | Defensive building. Lasts 30 seconds and pulls tanks toward it. |
| Fire Bomb | 4 | Spell. Area damage anywhere on the map (reduced against towers). |
| Wrecking Ram | 4 | Fast. Charges straight at buildings. |

Card stats live in `scripts/cards.gd`, so balancing is a matter of editing numbers there.

## Project layout

| File | Purpose |
| --- | --- |
| `scenes/main.tscn` | The only scene; everything else is created from code. |
| `scripts/game.gd` | Match controller: towers, elixir, hands, deploying, damage, collisions, win rules, arena art. |
| `scripts/unit.gd` | Troops and buildings: targeting, bridge pathing, attacking. |
| `scripts/tower.gd` | King and princess towers. |
| `scripts/ai.gd` | The computer opponent. |
| `scripts/hud.gd` | Cards, elixir bar, timer, crowns, placement preview, start and end screens. |
| `scripts/cards.gd` | Card data. |
| `scripts/art.gd` | Placeholder robot drawings. |
| `scripts/arena.gd` | Arena layout constants. |

## Automated check

Two AIs can play a whole match with no window, which is a quick way to check
that nothing crashes:

```sh
godot --headless --fixed-fps 60 -- --autotest
```

It prints a line like `AUTOTEST_RESULT winner=0 crowns=3-1 ...` and exits.
