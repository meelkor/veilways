@tool
class_name Npc
extends Actor

@export var npc_name: String

@onready var _hp_bar_wrapper := %HpBarWrapper as Control
@onready var _hp_bar := %HpBar as HpBar
@onready var _self_ray_cast := $SelfRayCast as RayCast3D

func _ready() -> void:
	super._ready()
	_hp_bar.actor = self
	hovered.connect(_update_hp_bar_size)


func _process(delta: float) -> void:
	super._process(delta)

	if not Engine.is_editor_hint():
		# todo: we can do this only once ig?
		var camera := get_viewport().get_camera_3d()
		if _self_ray_cast.is_colliding():
			var pos3d := _self_ray_cast.get_collision_point() + Vector3.UP * 0.25
			var pos2d := camera.unproject_position(pos3d)
			_hp_bar_wrapper.global_position = pos2d
			_hp_bar.visible = _hovered or damaged


func _update_hp_bar_size(large: bool) -> void:
	if large:
		_hp_bar.size.y = 24
		_hp_bar.position.y = -20
	else:
		_hp_bar.size.y = 4
		_hp_bar.position.y = 0


func _to_string() -> String:
	return "NPC_%s" % npc_name
