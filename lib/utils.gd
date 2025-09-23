class_name Utils
extends Object


static func get_tile_key(pos: Vector3i) -> int:
	return pos.z << 32 | pos.x
