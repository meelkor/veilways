class_name Deck
extends Resource

const HAND_SIZE = 5

## LIFO (0 = bottom)
@export var drawing_deck: Array[Card]

@export var hand: Array[Card]

## LIFO (0 = bottom)
@export var discard_pile: Array[Card]


## Try to fill hand from drawing deck, shuffling discard pile into it if
## necessary.
func fill_hand() -> void:
	var to_add := HAND_SIZE - hand.size()
	if to_add > 0:
		var to_draw := mini(drawing_deck.size(), to_add)
		var slice_start := drawing_deck.size() - to_draw
		hand.append_array(drawing_deck.slice(slice_start))
		drawing_deck.resize(slice_start)
		if drawing_deck.size() == 0 and discard_pile.size() > 0:
			shuffle()
			fill_hand()
		emit_changed()


## Return discard pile into drawing deck and shuffle
func shuffle() -> void:
	hand.append_array(discard_pile)
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

	var card: Card:
		get():
			return deck.hand[hand_index]


	func compare(v: Pointer) -> bool:
		return v.deck == deck and v.hand_index == hand_index
