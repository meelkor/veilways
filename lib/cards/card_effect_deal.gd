class_name CardEffectDeal
extends CardEffect

@export var color: Enums.EffectColor

@export var damage: int

@export var requires_actor_target: bool

@export var conditions: Array[Condition]


func is_valid(actor: Actor, target: Vector3i) -> bool:
	var target_actor := Game.instance.get_tile_actor(target)
	return !!target_actor and actor != target_actor


func execute(actor: Actor, target: Vector3i) -> void:
	var target_actor := Game.instance.get_tile_actor(target)
	Game.instance.deal_damage(actor, target_actor, damage)
