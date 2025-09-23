class_name CardEffectDeal
extends CardEffect

@export var color: Enums.EffectColor

@export var damage: int

@export var requires_actor_target: bool

@export var cards: Array[Card]


func is_valid(target: Vector3i) -> bool:
	return Game.instance.is_tile_navigable(target) and Game.instance.get_tile_npc(target) != null


func execute(target: Vector3i) -> void:
	var npc := Game.instance.get_tile_npc(target)
	Game.instance.deal_damage(npc, damage, color)
