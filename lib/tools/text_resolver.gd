class_name TemplateText
extends Object


## Fill in card text template correct values with correct formatting (e.g. for
## number with color compute the value for given actor and show it correctly)
static func format(template: String, subjects: Array[Object]) -> String:
	var regex := RegEx.create_from_string("\\[\\[(\\d)\\.(?:((?:\\w+=\\d+:?)+):)?(\\w+)\\]\\]")
	var result: RegExMatch
	result = regex.search(template)
	var color := Enums.NumberColor.NONE
	var family := Enums.CardFamily.GENERIC
	while result != null:
		var whole := result.get_string(0)
		var subject := subjects[result.get_string(1).to_int()]
		var params := result.get_string(2)
		if params:
			for param_str in params.split(":"):
				var parsed_param := param_str.split("=")
				var param_name := parsed_param[0]
				var param_val := parsed_param[1].to_int()
				if param_name == "color":
					color = param_val as Enums.NumberColor
				elif param_name == "family":
					family = param_val as Enums.CardFamily
				else:
					return "Invalid param"
		var key := result.get_string(3)
		var formatted: String
		if key.is_valid_int():
			# resolve it as number with color etc.
			var color_str := Enums.get_color(color).to_html()
			var actor := subject as Actor
			if actor:
				var total := actor.resolve_number(family, color, key.to_int()).total
				formatted = "[outline_size=4][outline_color=black][b][color=%s]%s[/color][/b][/outline_color][/outline_size]" % [color_str, total]
			else:
				formatted = "!non_actor_subject!"
		else:
			# try to read property from subject, whatever it is
			var val: Variant = subject.get(key)
			if val is StringName:
				formatted = val
			else:
				push_warning("No key %s in %s" % [key, subject])
				formatted = "!no_key_%s!" % key

		template = template.replace(whole, formatted)
		result = regex.search(template)

	return template
