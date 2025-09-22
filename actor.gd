class_name Actor
extends Node3D

var coordinate: Vector3i = Vector3i.ZERO:
	set(v):
		position.x = float(v.x) + 0.5
		position.y = float(v.y) * 0.2
		position.z = float(v.z) + 0.5
		coordinate = v
