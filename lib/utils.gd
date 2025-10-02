class_name Utils
extends Object

@warning_ignore("integer_division")
const TILE_RANGE: int = (1 << 32 - 1) / 2


static func get_tile_key(pos: Vector3i) -> int:
	return (pos.z + TILE_RANGE) << 32 | (pos.x + TILE_RANGE)
