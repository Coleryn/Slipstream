class_name Palette
extends RefCounted

## Single source of truth for every color in the game.
## Never hardcode a color anywhere else - reference these instead.

const BACKGROUND: Color = Color("#2a445d")
const PANEL: Color = Color("#1f3347")
const PLAYER: Color = Color("#ffffff")
const PLAYER_INNER: Color = Color("#dbe4ec")
const SQUARE_NORMAL: Color = Color("#8fa3b5")
const SQUARE_FAST: Color = Color("#e85d5d")
const SQUARE_GOLD: Color = Color("#f2c94c")
const TEXT: Color = Color("#ffffff")
const TEXT_DIM: Color = Color(1.0, 1.0, 1.0, 0.7)

const INNER_DARKEN_FACTOR: float = 0.82


static func shade(color: Color, factor: float) -> Color:
	return Color(color.r * factor, color.g * factor, color.b * factor, color.a)


static func lift(color: Color, amount: float) -> Color:
	var clamped: float = clampf(amount, 0.0, 1.0)
	return Color(
		lerpf(color.r, 1.0, clamped),
		lerpf(color.g, 1.0, clamped),
		lerpf(color.b, 1.0, clamped),
		color.a)
