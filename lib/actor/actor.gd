@tool
class_name Actor
extends Node3D

signal hovered(hover: bool)

@export var deck: Deck

@export var max_hp: int:
	get = _get_max_hp

@export var hp: int

@export var dead: bool

@export var temp_hp: int

var coordinate: Vector3i = Vector3i.ZERO:
	get():
		return Vector3i(
			floori(position.x),
			0,
			floori(position.z),
		)

var tile_key: int:
	get():
		return Utils.get_tile_key(coordinate)

var damaged: bool:
	get():
		return hp != max_hp or temp_hp > 0

var _editor_last_snap: Vector3 = Vector3.INF

var _hovered: bool

func can_cast_card_to(card: Card, target_tile: Vector3i) -> bool:
	var distance_tiles := distance_to_tile(target_tile)
	return card.range_tiles >= distance_tiles and card.is_valid(self, target_tile)


func distance_to_tile(pos: Vector3i) -> int:
	return absi(pos.x - coordinate.x) + absi(pos.z - coordinate.z)


func get_coordinate_in_direction(x_direction: float, z_direction: float) -> Vector3i:
	var addition := Vector3i(int(signf(x_direction)), 0, 0)\
		if absf(x_direction) > absf(z_direction)\
		else Vector3i(0, 0, int(signf(z_direction)))
	var out := coordinate + addition
	out.y = Game.instance.get_tile_height(out)
	return out


func snap_y() -> void:
	const DEF_Y := -1000
	var game: Game = get_tree().edited_scene_root if Engine.is_editor_hint() else Game.instance
	if game and game is Game:
		var map := game.overworld.grid_map
		var cells := map.get_used_cells()
		var max_y := DEF_Y
		for cell in cells:
			if cell.x == coordinate.x and cell.z == coordinate.z:
				max_y = maxi(cell.y, max_y)
		if max_y > DEF_Y:
			var cell_item := map.get_cell_item(Vector3i(coordinate.x, max_y, coordinate.z))
			var mesh := map.mesh_library.get_item_mesh(cell_item)
			position.y = max_y * 0.2 + mesh.get_aabb().size.y
		else:
			position.y = 0


func cast_card(card_pointer: Deck.Pointer, target_tile: Vector3i) -> void:
	@warning_ignore("redundant_await")
	await card_pointer.card.execute(self, target_tile)
	assert(card_pointer.deck == deck, "Actor %s is casting card from foreign deck")
	card_pointer.move_to_discard_pile()


## Since numbers on cards may be modified by actor's conditions, equipments
## etc. it needs to be computed by the actor.
func resolve_number(family: Enums.CardFamily, color: Enums.NumberColor, base: int) -> EffectNumber:
	return EffectNumber.new(self, family, color, base)


func _ready() -> void:
	if not Engine.is_editor_hint():
		if hp == 0 and not dead:
			hp = max_hp
		if not deck:
			# deck is optional, create empty deck if not provided
			deck = Deck.new()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and is_inside_tree() and get_tree().edited_scene_root != self:
		position.x = floorf(position.x) + 0.5
		position.z = floorf(position.z) + 0.5
		if position != _editor_last_snap:
			snap_y()
			_editor_last_snap = position


func _on_static_body_3d_mouse_entered() -> void:
	_hovered = true
	hovered.emit(true)


func _on_static_body_3d_mouse_exited() -> void:
	_hovered = false
	hovered.emit(false)

func _get_max_hp() -> int:
	return max_hp
