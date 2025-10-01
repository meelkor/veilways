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
	const RAY_RANGE = 64.0
	var from := Vector3(position.x, RAY_RANGE, position.z)
	var to := Vector3(position.x, -RAY_RANGE, position.z)
	var ray_params := PhysicsRayQueryParameters3D.create(from, to)
	var ray_result := get_world_3d().direct_space_state.intersect_ray(ray_params)
	position.y = ray_result.get("position", Vector3.ZERO).y


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
