tool
extends Control

signal color_toggled(control, color)

export(Color) var _color := Color.white setget _color_set, _color_get

onready var _button := $Button as TextureButton

func color() -> Color:
	return _color

func disable() -> void:
	_button.disabled = true

func enable() -> void:
	_button.disabled = false

func off() -> void:
	_button.pressed = false

func _color_set(color : Color) -> void:
	modulate = color
	_color = color

func _color_get() -> Color:
	return _color

func _ready() -> void:
	_color_set(_color)

func _on_Button_pressed() -> void:
	emit_signal('color_toggled', self, _color)
