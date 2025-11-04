class_name PlayerGui
extends Control

@onready var _hand_cards := %HandCards as HandCards
@onready var _draw_pile_button := %DrawPileButton as Button
@onready var _discard_pile_button := %DiscardPileButton as Button
@onready var _hp_bar := %HpBar as HpBar


func _ready() -> void:
	var game := Game.instance
	var player := game.player
	_hp_bar.actor = player
	# todo: hand cards could access deck by itself via Game instance, but I
	# want to have it reusable? Wrap into "GameUi"? Or move into Player?
	_hand_cards.deck = player.deck
	game.active_card_changed.connect(func () -> void:
		if game.active_card:
			_hand_cards.selected_cards = [game.active_card.hand_index]
			_hand_cards.offset_bottom = 140
		else:
			_hand_cards.selected_cards = []
			_hand_cards.offset_bottom = 0
	)
	_hand_cards.card_selected.connect(func (pointer: Deck.Pointer) -> void: game.active_card = pointer)
	player.deck.changed.connect(func () -> void:
		_draw_pile_button.text = "%s cards" % len(player.deck.draw_pile)
		_discard_pile_button.text = "%s cards" % len(player.deck.discard_pile)
	)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		Game.instance.active_card = null
