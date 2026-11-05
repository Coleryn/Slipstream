class_name FeedbackConfig
extends Resource

## Every timing and strength used for game feel, in one tunable place.

@export_group("Screen shake")
@export var shake_enabled: bool = true
@export_range(0.05, 1.0, 0.01) var shake_duration: float = 0.28
@export_range(0.0, 24.0, 0.5) var shake_strength: float = 7.0
@export_range(0.0, 24.0, 0.5) var max_shake_strength: float = 12.0
@export_range(0.05, 1.0, 0.01) var crash_shake_duration: float = 0.16
@export_range(0.0, 16.0, 0.5) var crash_shake_strength: float = 3.5

@export_group("Slow motion")
@export_range(0.05, 1.0, 0.01) var slowmo_scale: float = 0.35
@export_range(0.05, 1.0, 0.01) var slowmo_duration: float = 0.25

@export_group("Player")
@export_range(0.0, 0.5, 0.01) var player_fade_in_time: float = 0.18
@export_range(0.0, 0.5, 0.01) var near_miss_distance: float = 18.0
@export_range(0.0, 0.4, 0.01) var near_miss_pulse_time: float = 0.16
@export_range(0.0, 0.5, 0.01) var near_miss_pulse_scale: float = 0.12
@export_range(0.02, 0.6, 0.01) var player_shrink_time: float = 0.14
@export_range(0.0, 0.5, 0.01) var freeze_frame: float = 0.1

@export_group("Shield")
@export_range(0.05, 0.6, 0.01) var shield_expand_time: float = 0.2
@export_range(1.0, 6.0, 0.5) var shield_ring_gap: float = 6.0
@export_range(1.0, 8.0, 0.5) var shield_ring_width: float = 2.0
@export_range(0.0, 1.0, 0.05) var shield_alpha: float = 0.8
@export_range(0.2, 3.0, 0.1) var shield_flicker_time: float = 1.0
@export_range(4.0, 40.0, 1.0) var shield_flicker_speed: float = 22.0

@export_group("Pulse")
@export_range(40.0, 400.0, 10.0) var pulse_radius: float = 150.0
@export_range(20.0, 600.0, 10.0) var pulse_push_strength: float = 320.0
@export_range(0.05, 0.6, 0.01) var pulse_push_duration: float = 0.25
@export_range(0.0, 20.0, 0.5) var pulse_cooldown: float = 8.0
@export_range(0.05, 0.5, 0.01) var pulse_ring_time: float = 0.28
@export_range(1.0, 6.0, 0.5) var pulse_ring_width: float = 2.0
@export_range(0.0, 1.0, 0.05) var pulse_ring_alpha: float = 0.85
@export_range(0.0, 10.0, 0.5) var pulse_square_shake: float = 2.5

@export_group("Player trail")
@export_range(0.05, 1.0, 0.01) var trail_lifetime: float = 0.22
@export_range(0.01, 0.2, 0.01) var trail_interval: float = 0.035
@export_range(0.0, 1.0, 0.01) var trail_alpha: float = 0.25
@export_range(0.0, 1.0, 0.05) var trail_shrink: float = 0.4

@export_group("Square look")
@export_range(0.2, 0.9, 0.01) var square_inner_ratio: float = 0.55

@export_group("Player look")
@export_range(0.2, 0.9, 0.01) var player_inner_ratio: float = 0.55

@export_group("Squares")
@export_range(0.0, 0.5, 0.01) var square_fade_in_time: float = 0.25

@export_group("Particles")
@export_range(0, 64, 1) var death_particles: int = 14
@export_range(0.0, 400.0, 10.0) var particle_speed: float = 170.0
@export_range(2.0, 24.0, 1.0) var particle_size: float = 8.0
@export_range(0.05, 1.0, 0.01) var particle_lifetime: float = 0.38
@export_range(0.0, 20.0, 0.5) var particle_drag: float = 5.0
@export_range(0.0, 1.0, 0.05) var particle_shrink: float = 1.0

@export_group("Crash")
@export_range(0, 32, 1) var crash_particles: int = 8
@export_range(0.0, 400.0, 10.0) var crash_particle_speed: float = 130.0
@export_range(0.05, 1.5, 0.01) var popup_lifetime: float = 0.4
@export_range(0.0, 200.0, 2.0) var popup_rise: float = 46.0
@export_range(1.0, 4.0, 0.1) var shockwave_expand: float = 2.5
@export_range(0.05, 0.4, 0.01) var shockwave_time: float = 0.25
@export_range(1.0, 6.0, 0.5) var shockwave_width: float = 2.0
@export_range(0.0, 1.0, 0.05) var shockwave_alpha: float = 0.9
@export_range(0.0, 12.0, 0.5) var particle_spin: float = 4.0

@export_group("Telegraph")
@export_range(0.0, 1.0, 0.05) var telegraph_time: float = 0.4
@export_range(0.0, 0.5, 0.01) var telegraph_fade: float = 0.12
@export_range(1.0, 6.0, 0.5) var telegraph_width: float = 2.0
@export_range(0.0, 1.0, 0.05) var telegraph_alpha: float = 0.4
@export_range(8.0, 60.0, 1.0) var telegraph_height: float = 14.0
@export_range(12, 48, 1) var popup_font_size: int = 32

@export_group("UI")
@export_range(0.05, 0.5, 0.01) var hud_fade_in_time: float = 0.25
@export_range(0.05, 1.0, 0.01) var ui_delay: float = 0.12
@export_range(0.05, 1.0, 0.01) var ui_fade_time: float = 0.2
@export_range(0.85, 1.0, 0.01) var button_press_scale: float = 0.96
@export_range(0.02, 0.3, 0.01) var button_pop_time: float = 0.07
@export_range(1.0, 2.0, 0.05) var combo_pop_scale: float = 1.3
@export_range(0.02, 0.4, 0.01) var combo_pop_time: float = 0.12

@export_group("Audio")
@export var placeholder_audio: bool = true