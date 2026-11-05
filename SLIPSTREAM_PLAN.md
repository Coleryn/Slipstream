# Slipstream: Godot 4 Endless Runner Plan

A minimalist endless runner in the style of Coolmath's *Dodge* (flat circles and squares). This file has two parts:

- **Part 1: Master prompt.** Copy this section into a file named `AGENTS.md` in your project root so OpenCode reads it as persistent context.
- **Part 2: Milestones.** A to-do checklist with one prompt per milestone. Give OpenCode **one milestone at a time**, test it in Godot, commit, then move on.

---

## Before you start

- [ ] Create an empty Godot 4 project
- [ ] Run `git init` and commit after every milestone, so you can roll back bad AI changes
- [ ] Copy Part 1 into `AGENTS.md` in the project root
- [ ] Open OpenCode in the project folder

---

# Part 1: Master prompt (copy into `AGENTS.md`)

```markdown
# Project: "Slipstream" - minimalist endless runner (Godot 4, GDScript)

## Concept
A flat, minimalist 2D endless runner. The player is a circle that auto-runs
"forward" (the world scrolls downward). The player only moves left/right by
dragging (mouse or touch). Squares fall from the top in lanes at different
speeds. Touching any square = game over. The core mechanic: squares that
collide with EACH OTHER shatter and give bonus points, so the player steers
to make fast squares crash into slow ones while staying safe.

## Art style
- Flat shapes only, no sprite assets. Draw everything with _draw() or
  ColorRect/Polygon2D.
- Palette: dark navy background, light-blue/white player circle, grey
  squares (normal), red squares (fast), gold squares (rare bonus).
- Soft particle bursts and light screen shake on crashes.

## Technical rules
- Godot 4.x, GDScript with static typing. Use Godot 4 syntax only
  (no KinematicBody2D, no `onready var`, use @onready, CharacterBody2D, etc.).
- Keep scripts small and one responsibility each.
- Use scenes: Main, Player, Square, Spawner, HUD, GameOver.
- Use an Autoload `GameState` for score, combo, speed, high score.
- Use collision layers: 1 = player, 2 = squares.
- Squares are axis-aligned (no rotation). Use Area2D for squares and player.
- Player collision shape slightly smaller than the drawn circle (forgiving).
- Use object pooling or reuse for squares and particles.
- Export-friendly: support both mouse and touch input (relative drag).
- Target: portrait 540x960 viewport, stretch mode canvas_items.
- No external addons.

## Rules for the agent
- Work only on the milestone I give you; do not implement future features.
- Do not modify files unrelated to the current milestone.
- After each milestone, list the files changed and how to test it.
- Keep values (speeds, spawn rates, colors) as exported variables or in a
  single config script so I can tune them easily.
- Ask before adding anything not in this document.
```

---

# Part 2: Milestones

## M1: Project setup
- [ ] Portrait window, stretch settings
- [ ] Folder structure (`scenes/`, `scripts/`)
- [ ] Main scene
- [ ] `GameState` autoload with `score`, `combo`, `speed`, `high_score`

**Prompt:**
> Set up the Godot project per AGENTS.md: window size and stretch settings, folders (scenes/, scripts/), a Main scene, and an empty GameState autoload with score, combo, speed and high_score variables.

## M2: Player
- [ ] Circle drawn via `_draw()`
- [ ] Moves on the X axis only (fixed Y near the bottom)
- [ ] Relative drag input (mouse and touch), smoothed with lerp
- [ ] Clamped to screen bounds

**Prompt:**
> Create the Player scene (Area2D, drawn circle, collision on layer 1). Move it horizontally using relative drag from mouse or touch, with smoothing, clamped to screen bounds. Y position is fixed near the bottom.

## M3: Squares and spawner
- [ ] Square scene (Area2D, drawn square, random size and speed)
- [ ] Spawner creates squares above the screen in random lanes
- [ ] Squares recycled when off-screen
- [ ] Spawn interval and speed range exposed as exported variables

**Prompt:**
> Create the Square scene and a Spawner. Squares fall at random speeds in random lanes. Recycle them when off-screen. Spawn interval and speed range must be exported variables.

## M4: Death and restart
- [ ] Player touching a square ends the run
- [ ] GameOver UI with score and Restart button
- [ ] Restart fully resets state

**Prompt:**
> Add game over when the player touches a square. Show a GameOver UI with the score and a Restart button. Restarting must fully reset state.

## M5: Square-vs-square crashes (core mechanic)
- [ ] Detect square-square collisions (layer 2 vs layer 2)
- [ ] Both squares destroyed, bonus points awarded
- [ ] Brief slow-motion on crash
- [ ] Spawner occasionally puts a fast square behind a slow one in the same lane

**Prompt:**
> Implement collisions between squares: when two overlap, destroy both, add bonus points to GameState, and trigger a short slow-motion effect. Update the Spawner to occasionally spawn a fast square behind a slower one in the same lane to create crash opportunities.

> **Checkpoint:** if this isn't fun with plain boxes, fix it here before adding anything else.

## M6: Score, combo and HUD
- [ ] Distance score ticks up over time
- [ ] Combo window timer; chain crashes raise the multiplier
- [ ] Multiplier resets when the timer expires
- [ ] HUD shows score, multiplier and high score
- [ ] High score saved to disk

**Prompt:**
> Add distance-based scoring and a combo system: crashes within a time window increase the multiplier, which resets when the timer expires. Create a HUD to show score, multiplier and high score. Save the high score with ConfigFile.

## M7: Difficulty curve
- [ ] Speed scales with `base + k * sqrt(time)`
- [ ] Spawn interval shrinks over time
- [ ] Every spawn pattern leaves a passable gap wider than the player

**Prompt:**
> Implement a difficulty ramp using speed = base + k*sqrt(time) and a shrinking spawn interval. Make sure every spawn pattern leaves a passable gap wider than the player.

## M8: Juice
- [ ] Particle burst of small squares on crash
- [ ] Light screen shake
- [ ] Trail behind the player
- [ ] Audio hooks for crash and death sounds

**Prompt:**
> Add polish: particle bursts on crashes, light screen shake, a trail behind the player, and placeholder audio hooks for crash and death sounds.

## M9: Special squares (optional)
- [ ] Red fast squares with slight homing
- [ ] Big slow squares worth lots of points
- [ ] Gold squares that grant a short shield

**Prompt:**
> Add three square variants (red fast with slight homing, large slow high-value, gold shield pickup). Configure each in one data resource or config script.

## M10: Pulse ability (optional)
- [ ] Button or second-finger tap pushes nearby squares away
- [ ] Cooldown with indicator in the HUD

**Prompt:**
> Add a pulse ability that pushes nearby squares away with a cooldown indicator in the HUD.

## M11: Export
- [ ] Create Android or Web export preset
- [ ] Test on a real device
- [ ] Tune controls and difficulty

---

## Tips for working with OpenCode

- **Test before moving on.** Give specific bug reports ("squares don't get destroyed when they collide"), not "it's broken".
- **Stop refactors.** If it starts rewriting your project, tell it: "Do not modify files unrelated to this milestone."
- **Godot version.** If it writes Godot 3 code, say: "Use Godot 4 syntax only."
- **Tune values yourself.** Fun comes from tweaking speeds and spawn rates, not from the AI's first guess.
- **Commit often.** One commit per working milestone.
