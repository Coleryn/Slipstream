class_name SquareVariant
extends Resource

## One square type. Every value here is tuned in assets/data/square_types.tres.

@export_enum("Normal", "Red", "Gold", "Big") var type: int = 0
@export var color: Color = Palette.SQUARE_NORMAL
@export var size_min: float = 28.0
@export var size_max: float = 52.0
@export var speed_multiplier: float = 1.0
@export var point_multiplier: float = 1.0
@export_range(0.0, 200.0, 5.0) var homing_rate: float = 0.0
@export_range(0.0, 300.0, 5.0) var max_drift: float = 0.0
@export var is_pickup: bool = false
@export_range(0.0, 15.0, 0.5) var shield_duration: float = 0.0
