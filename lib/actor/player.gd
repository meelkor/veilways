@tool
class_name Player
extends Actor

var _last_direction: Vector3

var _mouse_down: bool = false

var movement_direction: Vector3:
	get: return _last_direction if _mouse_down else Vector3.ZERO

## Direction decal
@onready var _arrow := $Arrow as Decal

## Container for all decal tiles that highlight range for active card
@onready var _range_decals := $RangeDecals as Node3D

## Container for all decal tiles that highlight current AoE decals (positioned
## untder cursor)
@onready var _effect_decals := $EffectDecals as Node3D


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		Game.instance.active_card_changed.connect(_update_range_decals)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		var free := Game.instance.is_free()
		_arrow.visible = free and not Game.instance.active_card
		_range_decals.visible = Game.instance.active_card != null and free
		_effect_decals.visible = Game.instance.active_card != null and free


func _update_range_decals() -> void:
	const CARDINALS: Array[Vector3] = [Vector3.BACK, Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT]
	const DIAGONALS: Array[Vector3] = [Vector3.BACK + Vector3.LEFT, Vector3.LEFT + Vector3.FORWARD, Vector3.FORWARD + Vector3.RIGHT, Vector3.RIGHT + Vector3.BACK]
	for child in _range_decals.get_children():
		_range_decals.remove_child(child)
	for child in _effect_decals.get_children():
		_effect_decals.remove_child(child)
	var card := Game.instance.active_card.card if Game.instance.active_card else null
	if card:
		for i in range(1, card.effect.range_tiles + 1):
			for vec in CARDINALS:
				var decal := preload("res://lib/actor/range_area.tscn").instantiate() as Decal
				decal.position = vec * i
				_range_decals.add_child(decal)
			if i % 2 == 0:
				for vec in DIAGONALS:
					var decal := preload("res://lib/actor/range_area.tscn").instantiate() as Decal
					decal.position = vec * i / 2
					_range_decals.add_child(decal)

		_effect_decals.add_child(preload("res://lib/actor/effect_area.tscn").instantiate() as Decal)
		for i in range(1, card.effect.radius_tiles):
			for vec in CARDINALS:
				var decal := preload("res://lib/actor/effect_area.tscn").instantiate() as Decal
				decal.position = vec * i
				_effect_decals.add_child(decal)
			if i % 2 == 0:
				for vec in DIAGONALS:
					var decal := preload("res://lib/actor/effect_area.tscn").instantiate() as Decal
					decal.position = vec * i / 2
					_effect_decals.add_child(decal)


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

		if Game.instance.active_card:
			var cursor_coord := _get_cursor_coordinate()
			_effect_decals.position = Vector3(cursor_coord) + Vector3(0.5, 0, 0.5)
			var distance := absi(coordinate.x - cursor_coord.x) + absi(coordinate.z - cursor_coord.z)
			var decal_cl := Color.GREEN if distance <= Game.instance.active_card.card.effect.range_tiles and distance > 0 else Color.RED
			for decal: Decal in _effect_decals.get_children():
				decal.modulate = decal_cl


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
