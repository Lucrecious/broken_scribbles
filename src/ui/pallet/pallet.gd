extends Control

signal color_picked(color)
signal pencil_picked
signal eraser_picked
signal scrap_picked

onready var _colors := $Colors.get_children()

onready var _pencil := $Tools/Pencil
onready var _eraser := $Tools/Eraser

func _ready() -> void:
	for color in _colors:
		color.connect('color_toggled', self, '_color_toggled')

func init() -> void:
	_color_toggled(_colors[-1], _colors[-1].modulate)
	_pencil.disabled = true

func _color_toggled(node : Control, color : Color) -> void:
	node.disable()
	
	for color in _colors:
		if color == node: continue
		color.off()
		color.enable()
	
	emit_signal('color_picked', color)

func _on_Pencil_pressed() -> void:
	_pencil.disabled = true
	_eraser.disabled = false
	emit_signal('pencil_picked')

func _on_Eraser_pressed() -> void:
	_pencil.disabled = false
	_eraser.disabled = true
	emit_signal('eraser_picked')

func _on_Scrap_pressed() -> void:
	emit_signal('scrap_picked')
