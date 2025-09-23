class_name Player
extends Actor

var _last_direction: Vector3

var _mouse_down: bool = false

var movement_direction: Vector3:
	get: return _last_direction if _mouse_down else Vector3.ZERO

## Direction decal
@onready var _arrow := $Arrow as Decal


func _process(_delta: float) -> void:
	_arrow.visible = Game.instance.is_free()


func _unhandled_input(event: InputEvent) -> void:
	var btn := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	if btn and btn.button_index == MOUSE_BUTTON_LEFT:
		_mouse_down = btn.pressed
	if motion:
		var mosue_pos := get_window().get_mouse_position()
		var win_size := get_viewport().get_visible_rect().size
		var x := (mosue_pos.x / win_size.x) * 2 - 1.
		var z := (mosue_pos.y / win_size.y) * 2 - 1.

		if x < 0 and z < 0:
			_last_direction = Vector3(0, 0, 1)
			_arrow.rotation_degrees.y = 180
		elif x > 0 and z > 0:
			_last_direction = Vector3(0, 0, -1)
			_arrow.rotation_degrees.y = 0
		elif x < 0 and z > 0:
			_last_direction = Vector3(1, 0, 0)
			_arrow.rotation_degrees.y = -90
		elif x > 0 and z < 0:
			_last_direction = Vector3(-1, 0, 0)
			_arrow.rotation_degrees.y = 90
		_arrow.position = _last_direction


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
	# todo: wrap into some Game method??
	return Game.instance.overworld.grid_map.local_to_map(pos)
