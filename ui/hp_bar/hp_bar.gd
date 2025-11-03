@tool
class_name HpBar
extends Control

const HP_BAR_TEMP_HP_LARGE = preload("res://ui/hp_bar/hp_bar_temp_hp_large.tres");
const HP_BAR_TEMP_HP_SMALL = preload("res://ui/hp_bar/hp_bar_temp_hp_small.tres");

@export var actor: Actor

@onready var _hp_line := %HpLine as Panel
@onready var _temp_hp_line := %TempHpLine as Panel
@onready var _hp_label := %HpLabel as Label
@onready var _temp_hp_label := %TempHpLabel as Label
@onready var _temp_hp_shield := %TempHpShield as Control


func _process(_delta: float) -> void:
	var max_hp: int = 100
	var hp: int = 60
	var temp_hp: int = 30
	if actor:
		max_hp = actor.max_hp
		hp = actor.hp
		temp_hp = actor.temp_hp

	if max_hp > 0:
		_hp_line.size.x = float(hp) / float(max_hp) * size.x
		_temp_hp_line.size.x = float(temp_hp) / float(max_hp) * size.x
		_hp_label.text = "%s/%s" % [hp, max_hp]
		_temp_hp_label.text = "%s" % temp_hp
		_temp_hp_shield.visible = temp_hp > 0


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_READY:
		if size.y > 8:
			_temp_hp_line.add_theme_stylebox_override("panel", HP_BAR_TEMP_HP_LARGE)
			_hp_label.visible = true
		else:
			_temp_hp_line.add_theme_stylebox_override("panel", HP_BAR_TEMP_HP_SMALL)
			_hp_label.visible = false
