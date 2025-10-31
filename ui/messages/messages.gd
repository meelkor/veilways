class_name Messages
extends ScrollContainer

static var now: Messages

const MAX_LINES = 20

@onready var _line_container := %LineContainer as VBoxContainer


func send_template(line: String, subjects: Array[Object]) -> void:
	send(TemplateText.format(line, subjects))


func send(line: String) -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = line;
	label.fit_content = true;
	_line_container.add_child(label)
	while _line_container.get_child_count() > MAX_LINES:
		var first_child := _line_container.get_child(0)
		_line_container.remove_child(first_child)
		first_child.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	set_deferred("scroll_vertical", 10000)


func _enter_tree() -> void:
	assert(not now, "There may be only one Messages")
	now = self


func _exit_tree() -> void:
	now = null
