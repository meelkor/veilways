class_name Deck
extends Resource

@export_range(1, 10, 1) var hand_size: int = 5

## LIFO (0 = bottom)
@export var draw_pile: Array[Card]

@export var hand: Array[Card]

## LIFO (0 = bottom)
@export var discard_pile: Array[Card]


## Try to fill hand from drawing deck, shuffling discard pile into it if
## necessary.
func fill_hand() -> void:
	var to_add := hand_size - hand.size()
	if to_add > 0:
		var to_draw := mini(draw_pile.size(), to_add)
		var slice_start := draw_pile.size() - to_draw
		hand.append_array(draw_pile.slice(slice_start))
		draw_pile.resize(slice_start)
		if draw_pile.size() == 0 and discard_pile.size() > 0:
			shuffle()
			fill_hand()
		emit_changed()


## Return discard pile into drawing deck and shuffle
func shuffle() -> void:
	draw_pile.append_array(discard_pile)
	discard_pile.resize(0)
	hand.shuffle()
	emit_changed()


func get_pointer(index: int) -> Pointer:
	var pointer := Pointer.new()
	pointer.deck = self
	pointer.hand_index = index
	return pointer


## Structure pointing to single card in this deck.
class Pointer:
	extends RefCounted

	var deck: Deck

	var hand_index: int

	var invalid := false

	var card: Card:
		get():
			assert(not invalid, "Trying to access card of invalidated pointer")
			return deck.hand[hand_index]


	func compare(v: Pointer) -> bool:
		return v.deck == deck and v.hand_index == hand_index


	## Move card from hand into discard pile. Doesn't trigger discard action. Marks
	## pointer as invalid so it cannot be used to acces the card anymore.
	func move_to_discard_pile() -> void:
		var discarded_card := card
		invalid = true
		deck.hand.remove_at(hand_index)
		deck.discard_pile.append(discarded_card)
