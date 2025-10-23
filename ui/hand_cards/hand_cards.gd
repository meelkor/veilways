class_name HandCards
extends HBoxContainer

const CardView = preload("res://ui/card_view/card_view.gd")
const CardViewScene = preload("res://ui/card_view/card_view.tscn")

signal card_selected(pointer: Deck.Pointer)

@export var deck: Deck:
	set(v):
		if deck and deck.changed.is_connected(_update_cards):
			deck.changed.disconnect(_update_cards)
		deck = v
		_update_cards()
		if deck:
			deck.changed.connect(_update_cards)

@export var selected_cards: Array[int] = []:
	set(v):
		selected_cards = v
		if is_inside_tree():
			for idx in get_child_count():
				_minimize_card(idx)


func _ready() -> void:
	_update_cards()


func _update_cards() -> void:
	if is_inside_tree():
		for child in get_children():
			remove_child(child)
			child.queue_free()
		if deck:
			for idx in range(deck.hand.size()):
				var card := deck.hand[idx]
				var cont := Control.new()
				var view := CardViewScene.instantiate() as CardView
				view.card = card
				view.mouse_entered.connect(_maximize_card.bind(idx))
				view.mouse_exited.connect(_minimize_card.bind(idx))
				view.pressed.connect(func () -> void: card_selected.emit(deck.get_pointer(idx)))
				view.rotation_degrees = (idx - deck.hand.size() / 2.) * 1.5
				cont.add_child(view)
				cont.custom_minimum_size.x = view.custom_minimum_size.x * 0.45
				add_child(cont)
				_minimize_card(idx)
				view.highlight = false


func _minimize_card(idx: int) -> void:
	# todo: unsafe hack
	var view := get_child(idx).get_child(0) as CardView
	view.scale = Vector2.ONE * 0.7
	view.z_index = 0
	if selected_cards.has(idx):
		view.offset_bottom = -30
	else:
		view.offset_bottom = 30


func _maximize_card(idx: int) -> void:
	# todo: unsafe hack
	var view := get_child(idx).get_child(0) as CardView
	view.scale = Vector2.ONE
	view.z_index = 1
	view.offset_bottom = -offset_bottom
