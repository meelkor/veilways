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

var _editor_last_snap: Vector3 = Vector3.INF


func get_coordinate_in_direction(x_direction: float, z_direction: float) -> Vector3i:
	return Vector3i(
		coordinate.x + int(signf(x_direction)),
		coordinate.y,
		coordinate.z + int(signf(z_direction)),
	)


func snap_y() -> void:
	var game: Game = Utils.editor_find_game(self) if Engine.is_editor_hint() else Game.instance
	var cells := game.overworld.grid_map.get_used_cells()
	var max_y := -1000
	for cell in cells:
		if cell.x == coordinate.x and cell.z == coordinate.z:
			max_y = maxi(cell.y, max_y)
	position.y = (max_y if max_y > -1000 else 0) * 0.2 + 0.2


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
