extends Control

onready var _list := $List

func select(index : int) -> void:
	if index < 0: return
	if index >= _list.items.size(): return
	
	_list.select(index, true)

func update_list(text : Array) -> void:
	_list.clear()
	for item in text:
		_list.add_item(str(item))
