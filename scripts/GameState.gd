extends Node

## Global run state. Mutable values live here so any scene can read them.

var score: int = 0
var combo: int = 1
var speed: float = 0.0
var high_score: int = 0


func commit_high_score() -> void:
	high_score = maxi(high_score, score)


func reset() -> void:
	score = 0
	combo = 1
	speed = 0.0
