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

For any visual, UI, or game-feel work, always load and follow the dodge-ui-style skill.
