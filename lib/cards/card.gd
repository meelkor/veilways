class_name Card
extends Resource

@export var name: String

@export var effect: CardEffect

## If set to non-empty string, overrides the generated description provided by
## the effect.
@export var description: String:
	get:
		if description:
			return description
		else:
			return effect.description


## Return true if card can be only target on self and thus target selection
## doesn't need to happen.
func is_self() -> bool:
	return effect.range_tiles == 0
