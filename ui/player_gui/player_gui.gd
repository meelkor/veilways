class_name PlayerGui
extends Control

@onready var hand_cards := $HandCards as HandCards


func _ready() -> void:
	var game := Game.instance
	var player := game.player
	# todo: hand cards could access deck by itself via Game instance, but I
	# want to have it reusable? Wrap into "GameUi"? Or move into Player?
	hand_cards.deck = player.deck
	game.active_card_changed.connect(func () -> void:
		if game.active_card:
			hand_cards.selected_cards = [game.active_card.hand_index]
			hand_cards.offset_bottom = 140
		else:
			hand_cards.selected_cards = []
			hand_cards.offset_bottom = 0
	)
	hand_cards.card_selected.connect(func (pointer: Deck.Pointer) -> void: game.active_card = pointer)
