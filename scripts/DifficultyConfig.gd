class_name DifficultyConfig
extends Resource

## The difficulty curve. One instance shared by Main and the Spawner.

@export_group("Speed curve")
@export var base_speed: float = 180.0
@export var speed_growth: float = 20.0
@export var max_speed: float = 460.0

@export_group("Spawn interval")
@export var interval_start: float = 0.55
@export var interval_shrink: float = 0.35
@export var interval_min: float = 0.3

@export_group("Square size")
@export var size_growth: float = 0.25

@export_group("Fairness")
@export var player_diameter: float = 32.0
@export var gap_margin: float = 24.0
@export var band_padding: float = 100.0
@export_range(0.0, 200.0, 5.0) var max_wall_nudge: float = 60.0

@export_group("Debug")
@export var debug_stats: bool = false
