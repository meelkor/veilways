@abstract
class_name PlayerAction
extends RefCounted


@abstract func do_action(actor: Actor) -> bool


class Move:
	extends PlayerAction

	var direction: Vector3

	func do_action(actor: Actor) -> bool:
		return await Game.instance.try_move_in_direction(actor, direction)


	func _init(dir: Vector3) -> void:
		direction = dir


class UseCard:
	extends PlayerAction

	var pointer: Deck.Pointer

	var target_tile: Vector3i


	func do_action(actor: Actor) -> bool:
		if pointer.card.effect.is_valid(actor, target_tile):
			await actor.cast_card(pointer, target_tile)
			return true
		else:
			return false


	func _init(p: Deck.Pointer, target: Vector3i) -> void:
		pointer = p
		target_tile = target
