extends Node2D

signal picked_word(id, word)

var _word

func pick_word(word : String) -> void:
	emit_signal("picked_word", get_tree().get_network_unique_id(), word)
