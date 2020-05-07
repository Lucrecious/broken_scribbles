extends Control

var _game : Game

onready var _pick_a_word := preload('res://src/ui/pick_a_word.tscn')

onready var _header := $Header as TextEdit
onready var _drawing_board := $Center/DrawingPanel/Center/Background/DrawingCanvas
onready var _done_button := $Done

var _pick_a_word_instance : Control

func init(game : Game) -> void:
	_game = game
	_game.connect('phase_changed', self, '_phase_changed')

func _phase_changed(_old_phase : int, new_phase : int) -> void:
	print('phase changed')
	if new_phase == Game.Phase_ChooseWord:
		_on_choose_word()
	if new_phase == Game.Phase_Guess:
		_on_guess_drawing()
	if new_phase == Game.Phase_Draw:
		_on_draw_guess()

func _on_draw_guess() -> void:
	_done_button.disabled = false
	
	_header.readonly = true
	_header.text = _game.get_local_guess()

	_drawing_board.drawable = true
	_drawing_board.clear()

func _on_guess_drawing() -> void:
	_done_button.disabled = false
	
	_header.readonly = false
	_header.text = ''

	_drawing_board.drawable = true
	_drawing_board.set_image(_game.get_local_image())

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

func _on_Done_pressed() -> void:
	_done_button.disabled = true
	_drawing_board.drawable = false
	_header.readonly = true
	
	if _game.get_phase() == Game.Phase_Draw:
		_on_done_phase_draw()
	elif _game.get_phase() == Game.Phase_Guess:
		_on_done_phase_guess()

func _on_done_phase_draw() -> void:
	var image := _drawing_board.texture.get_data() as Image
	
	image.lock()
	var image_info := {
		uncompressed_size = image.get_data().size(),
		bytes = image.get_data().compress(File.COMPRESSION_FASTLZ),
		size = image.get_size(),
		format = image.get_format()
	}
	image.unlock()
	
	_game.rpc('done_drawing', image_info)

func _on_done_phase_guess() -> void:
	_game.rpc('done_guess', _header.text)







