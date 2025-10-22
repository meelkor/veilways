@tool
class_name Npc
extends Actor

@export var npc_name: String


func _to_string() -> String:
	return "NPC_%s" % npc_name
