extends Node2D


func _ready():
	if Network.init_local_peer() != OK: return
	var start_menu = preload('res://src/ui/start_menu.tscn').instance()
	add_child(start_menu)
