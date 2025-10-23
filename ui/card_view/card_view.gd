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
		# todo: fix hardcoded player
		(%DescriptionLabel as RichTextLabel).text = _format_description(Game.instance.player)


## Fill in card text template correct values with correct formatting (e.g. for
## number with color compute the value for given actor and show it correctly)
func _format_description(actor: Actor) -> String:
	var regex := RegEx.create_from_string("\\[\\[(\\w+=\\d+:)+(\\d+)\\]\\]")
	var _family := card.family
	var description := card.description
	var result: RegExMatch
	result = regex.search(description)
	var color := Enums.NumberColor.NONE
	while result != null:
		var whole := result.get_string(0)
		var base := result.get_string(result.get_group_count()).to_int()
		for i in range(result.get_group_count() - 1):
			var param_str := result.get_string(i + 1)
			var parsed_param := param_str.substr(0, param_str.length() - 1).split("=")
			var param_name := parsed_param[0]
			var param_val := parsed_param[1].to_int()
			if param_name == "c":
				color = param_val as Enums.NumberColor
		var color_str := Enums.get_color(color).to_html()
		var total := actor.resolve_number(card.family, color, base).total

		var formatted := "[outline_size=4][outline_color=black][b][color=%s]%s[/color][/b][/outline_color][/outline_size]" % [color_str, total]
		description = description.replace(whole, formatted)
		result = regex.search(description)
	return description
