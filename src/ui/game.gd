extends Control

var _game : Game

onready var _pick_a_word := preload('res://src/ui/pick_a_word.tscn')

func init(game : Game) -> void:
	_game = game
	_game.connect('phase_changed', self, '_phase_changed')

func _phase_changed(_old_phase : int, new_phase : int) -> void:
	print('phase changed')
	if new_phase == Game.Phase_ChooseWord:
		_on_choose_word()

func _on_choose_word() -> void:
	var node := _pick_a_word.instance()
	node.init(_game.local_word_choices())
	add_child(node)
	node.connect('word_picked', self, '_word_picked')

func _word_picked(index : int) -> void:
	_game.rpc_id(1, 'pick_word', get_tree().get_network_unique_id(), index)




