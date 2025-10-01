class_name Utils
extends Object


static func get_tile_key(pos: Vector3i) -> int:
	return pos.z << 32 | pos.x


static func editor_find_game(node: Node) -> Game:
	while node and not node is Game:
		node = node.get_parent()
	return node
