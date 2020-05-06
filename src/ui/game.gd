extends Control

var _game : Game

onready var _pick_a_word := preload('res://src/ui/pick_a_word.tscn')

var _pick_a_word_instance : Control

func init(game : Game) -> void:
	_game = game
	_game.connect('phase_changed', self, '_phase_changed')

func _phase_changed(_old_phase : int, new_phase : int) -> void:
	print('phase changed')
	if new_phase == Game.Phase_ChooseWord:
		_on_choose_word()

func _on_choose_word() -> void:
	_pick_a_word_instance = _pick_a_word.instance()
	_pick_a_word_instance.init(_game.local_word_choices())
	add_child(_pick_a_word_instance)
	_pick_a_word_instance.connect('word_picked', self, '_word_picked')

func _word_picked(index : int) -> void:
	if is_network_master():
		_game.pick_word(get_tree().get_network_unique_id(), index)
	else:
		_game.rpc('pick_word', get_tree().get_network_unique_id(), index)

	if not _pick_a_word_instance: return
	remove_child(_pick_a_word_instance)
	_pick_a_word_instance.queue_free()
	_pick_a_word_instance = null




