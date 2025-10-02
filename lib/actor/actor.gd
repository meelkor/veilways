@tool
class_name Actor
extends Node3D

@export var deck: Deck

@export var hp: int

@export var max_hp: int:
	get = _get_max_hp

var coordinate: Vector3i = Vector3i.ZERO:
	get():
		return Vector3i(
			floori(position.x),
			0,
			floori(position.z),
		)

var tile_key: int:
	get():
		return Utils.get_tile_key(coordinate)

var _editor_last_snap: Vector3 = Vector3.INF


func get_coordinate_in_direction(x_direction: float, z_direction: float) -> Vector3i:
	var addition := Vector3i(int(signf(x_direction)), 0, 0)\
		if absf(x_direction) > absf(z_direction)\
		else Vector3i(0, 0, int(signf(z_direction)))
	return coordinate + addition


func snap_y() -> void:
	const DEF_Y := -1000
	var game: Game = get_tree().edited_scene_root if Engine.is_editor_hint() else Game.instance
	if game and game is Game:
		var map := game.overworld.grid_map
		var cells := map.get_used_cells()
		var max_y := DEF_Y
		for cell in cells:
			if cell.x == coordinate.x and cell.z == coordinate.z:
				max_y = maxi(cell.y, max_y)
		if max_y > DEF_Y:
			var cell_item := map.get_cell_item(Vector3i(coordinate.x, max_y, coordinate.z))
			var mesh := map.mesh_library.get_item_mesh(cell_item)
			position.y = max_y * 0.2 + mesh.get_aabb().size.y
		else:
			position.y = 0


func _ready() -> void:
	if not Engine.is_editor_hint():
		if deck:
			deck.fill_hand()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and is_inside_tree() and get_tree().edited_scene_root != self:
		position.x = floorf(position.x) + 0.5
		position.z = floorf(position.z) + 0.5
		if position != _editor_last_snap:
			snap_y()
			_editor_last_snap = position


func _get_max_hp() -> int:
	return max_hp
