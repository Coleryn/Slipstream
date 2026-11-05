class_name FeedbackConfig
extends Resource

## Every timing and strength used for game feel, in one tunable place.

@export_group("Screen shake")
@export var shake_enabled: bool = true
@export_range(0.05, 1.0, 0.01) var shake_duration: float = 0.28
@export_range(0.0, 24.0, 0.5) var shake_strength: float = 7.0
@export_range(0.05, 1.0, 0.01) var crash_shake_duration: float = 0.16
@export_range(0.0, 16.0, 0.5) var crash_shake_strength: float = 3.5

@export_group("Slow motion")
@export_range(0.05, 1.0, 0.01) var slowmo_scale: float = 0.35
@export_range(0.05, 1.0, 0.01) var slowmo_duration: float = 0.25

@export_group("Player death")
@export_range(0.0, 0.5, 0.01) var freeze_frame: float = 0.1
@export_range(0.02, 0.6, 0.01) var player_shrink_time: float = 0.14
@export_range(0, 64, 1) var death_particles: int = 14
@export_range(0.0, 400.0, 10.0) var particle_speed: float = 170.0
@export_range(2.0, 24.0, 1.0) var particle_size: float = 8.0
@export_range(0.05, 1.0, 0.01) var particle_lifetime: float = 0.38

@export_group("Crash")
@export_range(0, 32, 1) var crash_particles: int = 8
@export_range(0.0, 400.0, 10.0) var crash_particle_speed: float = 130.0
@export_range(0.05, 1.5, 0.01) var popup_lifetime: float = 0.55
@export_range(0.0, 200.0, 2.0) var popup_rise: float = 46.0
@export_range(12, 48, 1) var popup_font_size: int = 32

@export_group("Game over UI")
@export_range(0.0, 0.5, 0.01) var ui_delay: float = 0.12
@export_range(0.05, 1.0, 0.01) var ui_fade_time: float = 0.2
