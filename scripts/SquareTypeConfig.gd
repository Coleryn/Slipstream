class_name SquareTypeConfig
extends Resource

## All square variants and their spawn weights, in one tunable place.

@export_group("Variants")
@export var normal: SquareVariant
@export var red: SquareVariant
@export var big: SquareVariant
@export var gold: SquareVariant

@export_group("Spawn weights")
@export var weight_normal: float = 70.0
@export var weight_red: float = 10.0
@export var weight_red_at_max: float = 30.0
@export var weight_big: float = 12.0
@export var weight_gold: float = 4.0


func _init() -> void:
	if normal == null:
		normal = SquareVariant.new()
	if red == null:
		red = SquareVariant.new()
		red.type = 1
		red.color = Palette.SQUARE_FAST
		red.size_min = 30.0
		red.size_max = 46.0
		red.speed_multiplier = 1.45
		red.homing_rate = 60.0
		red.max_drift = 120.0
	if big == null:
		big = SquareVariant.new()
		big.type = 3
		big.size_min = 62.0
		big.size_max = 78.0
		big.speed_multiplier = 0.6
		big.point_multiplier = 3.0
	if gold == null:
		gold = SquareVariant.new()
		gold.type = 2
		gold.color = Palette.SQUARE_GOLD
		gold.size_min = 26.0
		gold.size_max = 34.0
		gold.is_pickup = true
		gold.shield_duration = 4.0


func pick(progress: float) -> SquareVariant:
	var ramp: float = clampf(progress, 0.0, 1.0)
	var variants: Array[SquareVariant] = [normal, red, big, gold]
	var weights: Array[float] = [weight_normal, lerpf(weight_red, weight_red_at_max, ramp), weight_big, weight_gold]
	var total: float = 0.0
	for weight in weights:
		total += maxf(weight, 0.0)
	if total <= 0.0:
		return normal
	var roll: float = randf() * total
	for i in variants.size():
		roll -= maxf(weights[i], 0.0)
		if roll <= 0.0:
			return variants[i]
	return normal
