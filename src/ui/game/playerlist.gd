extends Control

onready var _list := $List

func update_list(players : Array) -> void:
	_list.clear()
	for id in players:
		_list.add_item(str(id))
