class_name Actor
extends Node3D

@export var deck: Deck

@export var hp: int

@export var max_hp: int:
	get = _get_max_hp

var coordinate: Vector3i = Vector3i.ZERO:
	set(v):
		position.x = float(v.x) + 0.5
		position.y = float(v.y) * 0.2
		position.z = float(v.z) + 0.5
		coordinate = v

@onready var world := get_parent()


func get_coordinate_in_direction(x_direction: float, z_direction: float) -> Vector3i:
	return Vector3i(
		coordinate.x + int(signf(x_direction)),
		coordinate.y,
		coordinate.z + int(signf(z_direction)),
	)


func _ready() -> void:
	if deck:
		deck.fill_hand()


func _get_max_hp() -> int:
	return max_hp
