@tool
class_name Player
extends Actor

var _last_direction: Vector3

var _mouse_down: bool = false

## Direction in which the player actively wants to go
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
		Game.instance.active_card_changed.connect(_prepare_card_decals)
		Game.instance.progressed.connect(_update_arrow_decal)


func _process(delta: float) -> void:
	super._process(delta)
	if not Engine.is_editor_hint():
		var game := Game.instance
		var free := game.is_free()
		_range_decals.visible = game.active_card != null and free
		_effect_decals.visible = game.active_card != null and free

		if free and movement_direction != Vector3.ZERO:
			game.do_player_action(PlayerAction.Move.new(movement_direction))


func _update_arrow_decal() -> void:
	var game := Game.instance
	var free := game.is_free()
	var next := get_coordinate_in_direction(_last_direction.x, _last_direction.z)
	_arrow.rotation_degrees.y = -90 * _last_direction.x + 180 * maxf(_last_direction.z, 0)
	_arrow.visible = game.is_tile_navigable(next) and not game.active_card and free
	_arrow.position = _last_direction


func _prepare_card_decals() -> void:
	const CARDINALS: Array[Vector3] = [Vector3.BACK, Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT]
	const DIAGONALS: Array[Vector3] = [Vector3.BACK + Vector3.LEFT, Vector3.LEFT + Vector3.FORWARD, Vector3.FORWARD + Vector3.RIGHT, Vector3.RIGHT + Vector3.BACK]
	for child in _range_decals.get_children():
		_range_decals.remove_child(child)
	for child in _effect_decals.get_children():
		_effect_decals.remove_child(child)
	var card := Game.instance.active_card.card if Game.instance.active_card else null
	if card:
		if card.range_tiles == 0:
			var decal := preload("res://lib/actor/effect_area.tscn").instantiate() as Decal
			decal.position = Vector3.ZERO
			_effect_decals.add_child(decal)
		else:
			for i in range(1, card.range_tiles + 1):
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
			for i in range(1, card.radius_tiles):
				for vec in CARDINALS:
					var decal := preload("res://lib/actor/effect_area.tscn").instantiate() as Decal
					decal.position = vec * i
					_effect_decals.add_child(decal)
				if i % 2 == 0:
					for vec in DIAGONALS:
						var decal := preload("res://lib/actor/effect_area.tscn").instantiate() as Decal
						decal.position = vec * i / 2
						_effect_decals.add_child(decal)
		_update_effect_decals()


func _unhandled_input(event: InputEvent) -> void:
	var btn := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	var game := Game.instance
	if btn and btn.button_index == MOUSE_BUTTON_LEFT:
		if game.is_free():
			if game.active_card:
				_mouse_down = false
				var target_tile := _get_cursor_coordinate()
				if game.active_card.card.is_self():
					target_tile = coordinate
				if can_cast_card_to(game.active_card.card, target_tile):
					var pointer := game.active_card
					game.active_card = null
					game.do_player_action(PlayerAction.UseCard.new(pointer, target_tile))
			else:
				_mouse_down = btn.pressed
		else:
			_mouse_down = false
	if motion:
		var mosue_pos := get_window().get_mouse_position()
		var win_size := get_viewport().get_visible_rect().size
		var x := (mosue_pos.x / win_size.x) * 2 - 1.
		var z := (mosue_pos.y / win_size.y) * 2 - 1.

		if x < 0 and z < 0:
			_last_direction = Vector3(0, 0, 1)
		elif x > 0 and z > 0:
			_last_direction = Vector3(0, 0, -1)
		elif x < 0 and z > 0:
			_last_direction = Vector3(1, 0, 0)
		elif x > 0 and z < 0:
			_last_direction = Vector3(-1, 0, 0)

		_update_arrow_decal()
		_update_effect_decals()


func _update_effect_decals() -> void:
	var game := Game.instance
	if game.active_card:
		var card := game.active_card.card
		var range_tiles := card.range_tiles
		var target_tile := _get_cursor_coordinate()
		if card.is_self():
			target_tile = coordinate

		_effect_decals.position = Vector3(target_tile) + Vector3(0.5, 0, 0.5)
		var distance := absi(coordinate.x - target_tile.x) + absi(coordinate.z - target_tile.z)
		# todo: maybe range check should be moved into is_valid? or separate
		# method?
		var valid := distance <= card.range_tiles and (distance > 0 or card.is_self()) and card.is_valid(self, target_tile)
		var decal_cl := Color.GREEN if valid else Color.RED
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


func _to_string() -> String:
	return "Player"
