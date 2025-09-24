## Represents current game session containing everything including the Player,
## NPCs, overworld map etc. Handles the main game loop (game ticks and actions).
## Also serves as the main channel for nodes to communicate through
##
## So other nodes and card effect can easily access current Game instace, it is
## exposed as static Game.instance
class_name Game
extends Node

const HandCards = preload("res://ui/hand_cards/hand_cards.gd")

## Currently active game instance for everyone to access. Set/unset on tree
## enter/exit.
static var instance: Game

signal active_card_changed()

## Player state including player deck etc. May or may not be actually part of
## the tree.
@export var player: Player

## Current world map
##
## todo: should be dynamically created and support multiple
@export var overworld: Overworld

## UI with player's cards. todo: probably should be elsewhere...
@export var hand_cards: HandCards

## Card player selected and is currently selecting taget for.
var active_card: Deck.Pointer:
	set(v):
		if active_card and v and active_card.compare(v):
			v = null
		active_card = v
		active_card_changed.emit()

## All spawned NPCs across all overworlds
var _npcs: Dictionary[int, Npc] = {}

var _player_action_in_progress: bool = false

var _npc_action_in_progress: bool = false


## Get NPC on given tile or null
func get_tile_npc(tile: Vector3i) -> Npc:
	return _npcs[Utils.get_tile_key(tile)]


func deal_damage(actor: Actor, amount: int, _color: Enums.EffectColor) -> void:
	actor.hp = maxi(0, actor.hp - amount)
	if actor.hp == 0:
		var npc := actor as Npc
		if npc:
			_npcs.erase(Utils.get_tile_key(npc.coordinate))
			npc.queue_free()
		else:
			get_tree().quit()


## Return true if neither player or NPCs is currently moving
func is_free() -> bool:
	return not _npc_action_in_progress and not _player_action_in_progress


## Check whether given tile exists has no obstructions
func is_tile_navigable(tile: Vector3i) -> bool:
	var cell_item := overworld.grid_map.get_cell_item(tile)
	var key := Utils.get_tile_key(tile)
	var player_key := Utils.get_tile_key(player.coordinate)
	if not _npcs[key] and player_key != key and cell_item != GridMap.INVALID_CELL_ITEM:
		var item_name := overworld.grid_map.mesh_library.get_item_name(cell_item)
		return not item_name.begins_with("wall_")
	return false


func _ready() -> void:
	# todo: hand cards could access deck by itself via Game instance, but I
	# want to have it reusable? Wrap into "GameUi"? Or move into Player?
	hand_cards.deck = player.deck
	active_card_changed.connect(func () -> void:
		if active_card:
			hand_cards.selected_cards = [active_card.hand_index]
			hand_cards.offset_bottom = 140
		else:
			hand_cards.selected_cards = []
			hand_cards.offset_bottom = 0
	)
	hand_cards.card_selected.connect(func (pointer: Deck.Pointer) -> void: active_card = pointer)



func _process(_delta: float) -> void:
	if is_free() and player.movement_direction:
		_do_player_action(PlayerAction.MOVE)


func _do_player_action(action: PlayerAction, _card: Card = null) -> void:
	_player_action_in_progress = true
	if action == PlayerAction.MOVE:
		# todo: I don't like that we need to read it again here...
		# ActionMovement enum class after all?
		await _try_move_in_direction(player, player.movement_direction)
	_player_action_in_progress = false
	# elif use card and assert card do card effect
	_npc_action_in_progress = true
	await _do_npc_logic()
	_npc_action_in_progress = false


## Returns whether the actor actually moved in given direction
##
## todo: maybe move parts of this code into Overworld class
func _try_move_in_direction(actor: Actor, direction: Vector3) -> bool:
	var next_coord := player.get_coordinate_in_direction(direction.x, direction.z)
	# todo: calculate highest block y and cache, so we can check in case there
	# is +3, also better access to grid_map
	var next_y_plus2 := overworld.grid_map.get_cell_item(next_coord + Vector3i(0, 2, 0))
	var walkables: Array[Vector3i] = [next_coord + Vector3i(0, 1, 0), next_coord + Vector3i(0, 0, 0), next_coord + Vector3i(0, -1, 0)]

	if next_y_plus2 == GridMap.INVALID_CELL_ITEM:
		var ok_i := walkables.find_custom(func (v: Vector3i) -> bool: return overworld.grid_map.get_cell_item(v) != GridMap.INVALID_CELL_ITEM)
		if ok_i != -1:
			var tw := create_tween()
			var desired_pos := overworld.grid_map.map_to_local(walkables[ok_i])
			tw.tween_property(actor, "position", desired_pos, 0.2)
			await tw.finished
			# todo: y coodrdinate changes here resulting in jump
			actor.coordinate = walkables[ok_i]
			return true
	return false


func _do_npc_logic() -> void:
	for npc_key: int in _npcs:
		var npc := _npcs[npc_key]
		await _try_move_in_direction(npc, npc.position - player.position)


func _enter_tree() -> void:
	assert(not instance, "There may be only one World")
	instance = self


func _exit_tree() -> void:
	instance = null


enum PlayerAction {
	MOVE,
	USE_CARD,
}
