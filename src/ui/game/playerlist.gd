extends Control

onready var _list := $List

func update_list(text : Array) -> void:
	_list.clear()
	for item in text:
		_list.add_item(str(item))
