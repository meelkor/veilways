## Represents current game session containing everything including the Player,
## NPCs, overworld map etc. Handles the main game loop (game ticks and actions).
## Also serves as the main channel for nodes to communicate through
##
## So other nodes and card effect can easily access current Game instace, it is
## exposed as static Game.instance
class_name Game
extends Node

## Currently active game instance for everyone to access. Set/unset on tree
## enter/exit.
static var instance: Game

signal active_card_changed()

## Emitted whenever player's turn ends or starts
signal progressed()

## Player state including player deck etc. May or may not be actually part of
## the tree.
@export var player: Player

## Current world map
##
## todo: should be dynamically created and support multiple
@export var overworld: Overworld

## Card player selected and is currently selecting taget for.
var active_card: Deck.Pointer:
	set(v):
		if active_card and v and active_card.compare(v):
			v = null
		active_card = v
		active_card_changed.emit()

## All spawned NPCs across all overworlds
var _npcs: Dictionary[int, Npc] = {}

var _player_action_in_progress: bool = false:
	set(v):
		_player_action_in_progress = v
		progressed.emit()

var _npc_action_in_progress: bool = false:
	set(v):
		_npc_action_in_progress = v
		progressed.emit()

var _height_cache: Dictionary[int, int]


func get_target_actors(tile: Vector3i, range_tiles: int) -> Array[Actor]:
	var out: Array[Actor]
	for actor: Actor in _npcs.values():
		if actor.distance_to_tile(tile) <= range_tiles:
			out.append(actor)
	if player.distance_to_tile(tile) <= range_tiles:
		out.append(player)
	return out


## Get NPC on given tile or null
func get_tile_npc(tile: Vector3i) -> Npc:
	var npc := _npcs.get(Utils.get_tile_key(tile), null) as Npc
	if npc and npc.visible:
		return npc
	else:
		return null


## Get Actor on given tile or null
func get_tile_actor(tile: Vector3i) -> Actor:
	if player.coordinate == tile:
		return player
	else:
		return _npcs.get(Utils.get_tile_key(tile), null)


func deal_damage(source_actor: Actor, target_actor: Actor, number: EffectNumber) -> void:
	Messages.now.send_template("[[0.name]] dealt %s damage to [[1.name]]." % number.to_template(), [source_actor, target_actor])
	target_actor.hp = maxi(0, target_actor.hp - number.total)
	if target_actor.hp == 0:
		kill(target_actor)


func grant_temp_hp(target_actor: Actor, number: EffectNumber) -> void:
	Messages.now.send_template("[[0.name]] gained %s temporary HP." % number.to_template(), [target_actor])
	target_actor.temp_hp += mini(number.total, target_actor.max_hp)


func kill(actor: Actor) -> void:
	actor.dead = true
	var npc := actor as Npc
	if npc:
		Messages.now.send_template("[[0.name]] died.", [actor])
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
	if not _npcs.has(key) and player.tile_key != key and cell_item != GridMap.INVALID_CELL_ITEM:
		var item_name := overworld.grid_map.mesh_library.get_item_name(cell_item)
		return not item_name.begins_with("wall_")
	return false


## Bread and butter of the game loop, since all actions in the world are
## triggered by player's action.
func do_player_action(action: PlayerAction, _card: Card = null) -> void:
	assert(is_free(), "Trying to do player action when not free")
	_player_action_in_progress = true

	@warning_ignore("redundant_await")
	var done_anything := await action.do_action(player)

	if not done_anything:
		_player_action_in_progress = false
		return # turn didn't happen

	_player_action_in_progress = false
	# elif use card and assert card do card effect
	_npc_action_in_progress = true
	await _do_npc_logic()
	_npc_action_in_progress = false
	_do_start_of_turn_logic()


## Get max y coordinate on given tile's x,z coords
func get_tile_height(tile: Vector3i) -> int:
	var key := Utils.get_tile_key(tile)
	if not _height_cache.has(key):
		var cells := overworld.grid_map.get_used_cells()
		var max_y := -1000
		for cell in cells:
			if cell.x == tile.x and cell.z == tile.z:
				max_y = maxi(cell.y, max_y)
		_height_cache[key] = max_y if max_y > -1000 else 0
	return _height_cache[key]


## Returns whether the actor actually moved in given direction
##
## todo: maybe move parts of this code into Overworld class
func try_move_in_direction(actor: Actor, direction: Vector3) -> bool:
	var next_coord := actor.get_coordinate_in_direction(direction.x, direction.z)
	var current_y := get_tile_height(actor.coordinate)

	if absi(current_y - next_coord.y) < 2:
		if not is_tile_navigable(next_coord):
			return false
		var tw := create_tween()
		var desired_pos := overworld.grid_map.map_to_local(next_coord)
		tw.tween_property(actor, "position", desired_pos, 0.2)
		await tw.finished
		return true
	return false


func find_active_actors() -> Array[Actor]:
	# todo introduce index:
	var actors: Array[Actor] = [player]
	actors.append_array(_npcs.values())
	return actors


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for npc: Npc in find_children("", "Npc"):
		_npcs[npc.tile_key] = npc
	# wait for active area to detect actors, dunno why two frames are needed
	await get_tree().physics_frame
	await get_tree().physics_frame
	_fill_all_active_hands()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return


## Called after each player's turn (even cooldown one). Expire buffs, temp
## health etc.
func _do_start_of_turn_logic() -> void:
	for actor in find_active_actors():
		actor.temp_hp = maxi(actor.temp_hp - 1, 0)
	_fill_all_active_hands()


func _do_npc_logic() -> void:
	for npc: Npc in find_active_actors().filter(_is_npc):
		var npc_key := npc.tile_key
		if npc.visible:
			await try_move_in_direction(npc, player.position - npc.position)
			_npcs.erase(npc_key)
			_npcs[npc.tile_key] = npc


func _is_npc(actor: Actor) -> bool:
	return actor is Npc


## Fill hand for all active actors (player + npcs)
func _fill_all_active_hands() -> void:
	for actor in find_active_actors():
		actor.deck.fill_hand()


func _enter_tree() -> void:
	assert(not instance, "There may be only one Game")
	instance = self


func _exit_tree() -> void:
	instance = null
