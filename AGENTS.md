# Project: "Slipstream" - minimalist endless runner (Godot 4.7, GDScript)

## Concept
A flat, minimalist 2D endless runner. The player is a circle that auto-runs
"forward" (the world scrolls downward). The player only moves left/right by
dragging (mouse or touch). Squares fall from the top in lanes at different
speeds. Touching any square = game over. The core mechanic: squares that
collide with EACH OTHER shatter and give bonus points, so the player steers to
make fast squares crash into slow ones while staying safe.

**Agency rule (most important design rule):** crashes must be something the
player can influence, not a passive light show.
- Planned crash pairs meet around 35-60% of the screen height
  (`Spawner.crash_y_min_ratio` / `crash_y_max_ratio`), close enough to react to.
- The red chaser of a pair is telegraphed (lane line) and homes a little
  (`pair_homing_scale`). Standing under the slow square's lane baits it in.
- Pulse pushes squares away and crashes caused by pushed squares pay a bonus
  (`Main.pulse_crash_multiplier`, credit window `FeedbackConfig.pulse_credit_time`).
- New spawns avoid lanes that already have a square near the top
  (`Spawner.lane_clear_height`), so crashes do not happen for free off-screen.
Do not add mechanics that make crashes happen regardless of what the player does.

## Status
Milestones M1-M10 in `SLIPSTREAM_PLAN.md` are implemented (project, player,
squares, death/restart, crashes, scoring/combo/HUD, difficulty, juice, special
squares, pulse) plus menu, pause, transitions, safe-area handling and background
music. M11 (export + real-device tuning) is still open.

## Art style
- Flat shapes only. Draw everything with `_draw()` / `ColorRect` / `Polygon2D`.
  No sprites or icons. The only bundled asset is the Nunito font (one typeface).
- Every color comes from `scripts/Palette.gd`. Never hardcode a color
  (scenes included: set colors from script via `Palette`).
- Palette: background `#2a445d`, player white (inner disc `#dbe4ec`), normal and
  big squares grey-blue `#8fa3b5`, red/fast `#e85d5d`, gold `#f2c94c`.
- Flat two-tone shapes (inner shape ~55%), sharp corners, no gradients, shadows,
  glow or emoji. Faint drifting background squares are allowed (`Backdrop`).
- Soft particle bursts and light screen shake on crashes.
- For any visual, UI, or game-feel work, load and follow
  `.opencode/skills/dodge-ui-style/SKILL.md`.

## Technical rules
- Godot 4.7, GL Compatibility renderer, GDScript with static typing. Godot 4
  syntax only (`@onready`, `CharacterBody2D`, typed arrays...).
- Portrait 540x960 viewport, stretch mode `canvas_items`.
- Autoloads: `GameState` (score, combo, speed, high score), `AudioManager`
  (all sound and music), `Transition` (scene fades).
- Scenes: Menu (main scene), Main, Player, Square, Spawner, HUD, GameOver,
  PauseOverlay. Collision layers: 1 = player, 2 = squares. Squares are
  axis-aligned Area2Ds. Player hitbox is smaller than the drawn circle.
- Squares are pooled and recycled by `Spawner`, never freed. Particles and
  popups are pooled too.
- Input: relative drag (mouse and touch). Pulse = HUD button, Space, or a tap
  with a second finger (`Main.second_finger_pulse`).
- Keep scripts small and single-purpose. No external addons.
- All tunables live in resources/config scripts, never as magic numbers:
  `FeedbackConfig` (game feel, audio flags), `DifficultyConfig` (speed curve,
  spawn density, fairness), `SquareTypeConfig` + `assets/data/square_types.tres`
  (variants and spawn weights), `Palette`, `UiMetrics`.

## Gameplay rules to preserve
- **Fairness:** every horizontal band keeps a gap wider than the player
  (`player_diameter + gap_margin`). The Spawner fixes violations only on squares
  that are fully above the screen. Nothing may pop in or out of existence on
  screen (rule 7 of the style skill: motion is the decoration).
- **Spawning is distance-based:** `interval = spacing / current speed`, with
  spacing shrinking over time (`DifficultyConfig.spawn_spacing_*`). Do not go
  back to a time-only interval; it flattens difficulty after a few seconds.
- **Gold squares are shield pickups** and ghost through other squares (they
  never crash).
- **Slow-motion has two tiers:** minor for ordinary crashes, full strength for
  big squares, pulse crashes, or combo >= `slowmo_major_combo`.

## Audio and music (AudioManager owns everything)
- SFX hooks: crash (pitch rises with combo), death, click, near miss, pulse.
  A file at `res://assets/audio/<name>.wav` replaces the generated blip.
- **Background music (BGM):** a quiet, calm loop that runs through menu and
  game and survives scene changes.
  - Default is generated in code by `scripts/MusicBuilder.gd`: 4 bars,
    Am - F - C - G, 92 BPM, soft pad + sparse bass + plucked arpeggio, 16 kHz
    mono, seamless loop (notes wrap around the loop end).
  - It is built on a `WorkerThreadPool` task, never on the main thread, and
    skipped when the audio driver is `Dummy` (headless).
  - To use real music, drop a looping `res://assets/audio/bgm.ogg`; it replaces
    the generated track automatically.
  - `Music On/Off` and `Sound On/Off` are separate and persist in
    `user://settings.cfg`. Music ducks (-9 dB) on pause and game over
    (`AudioManager.set_music_ducked`).
- BGM rules: calm and minimal, no vocals, no big dynamic jumps, around -14 dB so
  SFX stay readable, no new audio addons. Musical constants (tempo, chords,
  levels) stay as consts at the top of `MusicBuilder`.
- After any change to `MusicBuilder` run `tests/check_music.tscn`
  (build time, loop length, seam smoothness).

## Rules for the agent
- Work only on the task given. Do not modify files unrelated to it.
- Tuning existing values is fine. Ask before adding a new feature, system,
  screen, mechanic or dependency that is not described in this file.
- Keep values (speeds, spawn rates, colors, audio levels) as exported variables
  or in the config scripts above so they can be tuned in the editor.
- After each task, list the files changed and how to test it.
- Run the checks below before saying a task is done.
- Commit once per working task so bad changes can be rolled back.

## Tooling
- Godot executable (no `godot` on PATH). Target Godot 4.7:
  `C:\Users\Lenovo\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe`
  (older 4.6 console build: `C:\Users\Lenovo\Downloads\Software\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe`)
- Fresh clone or new `class_name` script: run once with `--import` so the global
  class cache exists, otherwise `class_name` scripts fail to parse:
  `& "<exe>" --headless --path "<project root>" --import`
- Checks (run from the project root, headless):
  - Parse/boot: `& "<exe>" --headless --path "<project root>" --quit`
  - Config sanity: `... res://tests/check_feedback_config.tscn`
  - Music: `... res://tests/check_music.tscn`
  - Balance probe (crash heights, density over time, wall counters):
    `... --fixed-fps 60 --path "<project root>" res://tests/sim_run.tscn`
    (`--fixed-fps 60` makes it run much faster than real time.)
- API docs (stable tracks 4.7): https://docs.godotengine.org/en/stable/
