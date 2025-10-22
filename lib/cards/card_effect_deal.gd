## Basic effect which deals static amount of damage/hp/conditions
class_name CardEffectDeal
extends CardEffect

@export var damage: int

@export var temp_hp: int

@export var requires_actor_target: bool

@export var conditions: Array[Condition]


func is_valid(actor: Actor, target: Vector3i) -> bool:
	var target_actor := Game.instance.get_tile_actor(target)
	return !!target_actor and (range_tiles == 0) == (actor == target_actor)


func execute(actor: Actor, target: Vector3i) -> void:
	var target_actor := Game.instance.get_tile_actor(target)
	if damage > 0:
		Game.instance.deal_damage(actor, target_actor, damage)
	if temp_hp > 0:
		Game.instance.grant_temp_hp(target_actor, temp_hp)


func _get_description() -> String:
	var lines: Array[String]
	if damage > 0:
		lines.append("Deals %s damage to target." % temp_hp)
	if temp_hp > 0:
		lines.append("Grants %s temporary HP." % temp_hp)
	return "\n".join(lines)
