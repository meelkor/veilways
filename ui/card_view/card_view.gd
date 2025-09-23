extends Button

@export var card: Card:
	set(v):
		card = v
		_update_content()

@export var highlight: bool:
	set(v):
		highlight = v
		_update_style()


func _ready() -> void:
	_update_content()
	await get_tree().process_frame
	_update_style()


func _update_style() -> void:
	if is_inside_tree():
		if highlight:
			scale = Vector2.ONE
			z_index = 1
		else:
			scale = Vector2.ONE * 0.7
			z_index = 0


func _update_content() -> void:
	if is_inside_tree():
		(%NameLabel as Label).text = card.name
		(%DescriptionLabel as Label).text = card.description
