extends Node2D

signal picked_word(word)

func pick_word(word : String) -> void:
	emit_signal("picked_word", word)

func _input(event):
	if not Input.is_action_just_pressed('ui_accept'): return
	
	if get_tree().is_network_server():
		pick_word("server")
	else:
		pick_word("client")
