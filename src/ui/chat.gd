extends Control

const max_text_length := 14
const max_lines := 7

signal text_entered(new_text)

onready var _line_edit := $LineEdit as LineEdit
onready var _messages := $Messages as Label

func add_text(more_text : String) -> void:
	var lines := _messages.text.split('\n', false)
	lines.append_array(more_text.split('\n'))
	
	for _i in range(max_lines, lines.size()):
		lines.remove(0)
	
	var joined := lines.join('\n').strip_edges()
	if joined.empty(): return
	
	_messages.text = lines.join('\n')

func _on_LineEdit_text_entered(new_text := '') -> void:
	_line_edit.text = ''
	emit_signal('text_entered', new_text)

func _on_LineEdit_text_changed(new_text: String) -> void:
	var pos := _line_edit.caret_position
	
	new_text = new_text.substr(0, int(min(max_text_length, new_text.length())))
	_line_edit.text = new_text
	
	_line_edit.caret_position = pos
	
