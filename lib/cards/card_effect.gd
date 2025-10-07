@abstract
class_name CardEffect
extends Resource

## Area of effect. Assumes circular AoE if more than 1.
@export var radius_tiles: int:
	get = _get_radius_tiles

## Range of the target tile that may be selected as target. 1 = only one tile
## in 4 cardinal directions. 2 = two tiles in 4 cardinal directions and 1 tiles
## in diagonals
@export var range_tiles: int:
	get = _get_range_tiles

@export var description: String:
	get = _get_description


func _get_radius_tiles() -> int:
	return radius_tiles


func _get_range_tiles() -> int:
	return range_tiles


func _get_description() -> String:
	return description


## Decide whether this card can be used on given target tile's coordinates.
## Used e.g. on mouse movement and before using the ability.
@abstract func is_valid(actor: Actor, target: Vector3i) -> bool


## Execute the actual effect, updating world as necessary (e.g. dealing damage,
## killing etc.)
@abstract func execute(actor: Actor, target: Vector3i) -> void


func _get_target_actors(target: Vector3i) -> Array[Actor]:
	return Game.instance.get_target_actors(target, radius_tiles)

