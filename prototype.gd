extends Node3D

@onready var _player: Actor = $Player

@onready var _grid_map: GridMap = $GridMap

var _npcs: Dictionary[int, Actor] = {}

var _player_action_in_progress: bool = false

var _npc_action_in_progress: bool = false

var _last_direction: Vector3

var _mouse_down: bool = false

func _process(_delta: float) -> void:
	if _is_free() and _mouse_down:
		_do_player_action(PlayerAction.MOVE)


func _unhandled_input(event: InputEvent) -> void:
	var btn := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	if btn and btn.button_index == MOUSE_BUTTON_LEFT:
		_mouse_down = btn.pressed
	if motion:
		var mosue_pos := get_window().get_mouse_position()
		var x := (mosue_pos.x / get_window().size.x) * 2 - 1.
		var z := (mosue_pos.y / get_window().size.y) * 2 - 1.

		if x < 0 and z < 0:
			_last_direction = Vector3(0, 0, 1)
		elif x > 0 and z > 0:
			_last_direction = Vector3(0, 0, -1)
		elif x < 0 and z > 0:
			_last_direction = Vector3(1, 0, 0)
		elif x > 0 and z < 0:
			_last_direction = Vector3(-1, 0, 0)


func _do_player_action(action: PlayerAction, _card: Card = null) -> void:
	_player_action_in_progress = true
	if action == PlayerAction.MOVE:
		await _try_move_in_direction(_player, _last_direction)
	_player_action_in_progress = false
	# elif use card and assert card do card effect
	_npc_action_in_progress = true
	await _do_npc_logic()
	_npc_action_in_progress = false


## Returns whether the actor actually moved in given direction
func _try_move_in_direction(actor: Actor, direction: Vector3) -> bool:
	var next_coord := _get_coordinate_in_direction(_player, direction.x, direction.z)
	# todo: calculate highest block y and cache, so we can check in case there
	# is +3
	var next_y_plus2 := _grid_map.get_cell_item(next_coord + Vector3i(0, 2, 0))
	var walkables: Array[Vector3i] = [next_coord + Vector3i(0, 1, 0), next_coord + Vector3i(0, 0, 0), next_coord + Vector3i(0, -1, 0)]

	if next_y_plus2 == GridMap.INVALID_CELL_ITEM:
		var ok_i := walkables.find_custom(func (v: Vector3i) -> bool: return _grid_map.get_cell_item(v) != GridMap.INVALID_CELL_ITEM)
		if ok_i != -1:
			var tw := create_tween()
			var desired_pos := _grid_map.map_to_local(walkables[ok_i])
			tw.tween_property(actor, "position", desired_pos, 0.2)
			await tw.finished
			# todo: y coodrdinate changes here resulting in jump
			actor.coordinate = walkables[ok_i]
			return true
	return false


func _do_npc_logic() -> void:
	for npc_key: int in _npcs:
		var npc := _npcs[npc_key]
		await _try_move_in_direction(npc, npc.position - _player.position)


func _get_cursor_world_position() -> Vector3:
	const RAY_DISTANCE = 64.0

	var camera := get_viewport().get_camera_3d()
	var mouse_pos := get_viewport().get_mouse_position()

	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * RAY_DISTANCE

	var ray_params := PhysicsRayQueryParameters3D.create(from, to)
	var ray_result := get_world_3d().direct_space_state.intersect_ray(ray_params)

	return ray_result.get("position", Vector3.INF)


func _get_cursor_coordinate() -> Vector3i:
	var pos := _get_cursor_world_position()
	return _grid_map.local_to_map(pos)


func _get_coordinate_in_direction(actor: Actor, x_direction: float, z_direction: float) -> Vector3i:
	return Vector3i(
		actor.coordinate.x + int(signf(x_direction)),
		actor.coordinate.y,
		actor.coordinate.z + int(signf(z_direction)),
	)


func _is_free() -> bool:
	return not _npc_action_in_progress and not _player_action_in_progress


enum PlayerAction {
	MOVE,
	USE_CARD,
}
