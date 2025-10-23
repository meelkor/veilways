class_name EffectNumber
extends RefCounted

var color: Enums.NumberColor

var family: Enums.CardFamily

var base: int

var actor: Actor

var total: int:
	get = _get_total


func _init(i_actor: Actor, i_family: Enums.CardFamily, i_color: Enums.NumberColor, i_base: int = 0) -> void:
	actor = i_actor
	family = i_family
	color = i_color
	base = i_base


func _get_total() -> int:
	# todo: sum up bonuses here from conditions, equipment and passives
	return base
