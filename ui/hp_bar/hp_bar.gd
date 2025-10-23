class_name HpBar
extends Control

@export var actor: Actor

@onready var _hp_line := %HpLine as Panel
@onready var _temp_hp_line := %TempHpLine as Panel
@onready var _hp_label := %HpLabel as Label
@onready var _temp_hp_label := %TempHpLabel as Label
@onready var _temp_hp_shield := %TempHpShield as Control


func _process(_delta: float) -> void:
	var max_hp: int = actor.max_hp
	var hp: int = actor.hp
	var temp_hp: int = actor.temp_hp

	if max_hp > 0:
		_hp_line.size.x = float(hp) / float(max_hp) * size.x
		_temp_hp_line.size.x = float(temp_hp) / float(max_hp) * size.x
		_hp_label.text = "%s/%s" % [hp, max_hp]
		_temp_hp_label.text = "%s" % temp_hp
		_temp_hp_shield.visible = temp_hp > 0
