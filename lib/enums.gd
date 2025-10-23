class_name Enums
extends Object

enum CardFamily {
	SWORD,
	SHIELD,
	BOOK,
	CROSSBOW,
}

enum NumberColor {
	NONE,
	SILVER,
	GREEN,
	RED,
}


static func get_color(cl: NumberColor) -> Color:
	match cl:
		NumberColor.NONE:
			return Color.BLACK
		NumberColor.SILVER:
			return Color(0.8, 0.8, 0.8)
		NumberColor.GREEN:
			return Color.GREEN
		NumberColor.RED:
			return Color.RED
		_:
			return Color.HOT_PINK
