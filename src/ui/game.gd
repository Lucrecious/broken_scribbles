extends Control

signal drawing_just_started

var _game : Game
var _room : Room

onready var _pick_a_word := preload('res://src/ui/pick_a_word.tscn')

onready var _header := $Header as LineEdit
onready var _drawing_board := $DrawingCanvas
onready var _done_button := $Done
onready var _pallet := $Pallet
onready var _time_left_label := $TimeLeft as TimeLeftControl

onready var _scribble_chain_handler := $ScribbleChainHandler

var _pick_a_word_instance : Control

func init(room : Room, game : Game) -> void:
	_room = room;
	_game = game
	_game.connect('phase_changed', self, '_phase_changed')
	_game.connect('received_scribble_chain', self, '_on_received_scribble_chain')
	_game.connect('phase_timeout', self, '_phase_timeout')
	_game.connect('phase_timer_started', self, '_phase_timer_started')
	
func _ready() -> void:
	_time_left_label.clear()
	
func _phase_timer_started() -> void:
	if _game.get_phase() != Game.Phase_Draw: return
	emit_signal('drawing_just_started')

func _phase_timeout() -> void:
	_drawing_board.drawable = false
	_done_button.disabled = true

	if _game.get_phase() == Game.Phase_ChooseWord:
		_word_picked(0)
		return

	if _game.get_phase() == Game.Phase_Draw:
		_game.rpc_id(Network.server_id, 'update_current_drawing', _drawing_board.get_image_info())
		return
	
	if _game.get_phase() == Game.Phase_Guess:
		_game.rpc_id(Network.server_id, 'done_guess', _header.text)
		return

func _on_received_scribble_chain(player_id : int) -> void:
	_scribble_chain = _game._scribble_chains[player_id]

func _phase_changed(old_phase : int, new_phase : int) -> void:
	if old_phase == Game.Phase_ChooseWord:
		_remove_pick_a_word_dialog()

	if new_phase == Game.Phase_ChooseWord:
		_on_choose_word()
		return

	if new_phase == Game.Phase_Guess:
		_on_guess_drawing()
		return

	if new_phase == Game.Phase_Draw:
		_on_draw_guess()
		return

	if new_phase == Game.Phase_ShowScribbleChain:
		_header.editable = false
		_header.text = ''
		_drawing_board.drawable = false
		_drawing_board.clear()
		#_done_button.disabled = true
		_done_button.disabled = false
		return

	if new_phase == Game.Phase_End:
		_done_button.disabled = false
		return

func _on_draw_guess() -> void:
	_done_button.disabled = false
	
	_header.editable = false
	_header.text = _game.get_local_guess()

	_drawing_board.drawable = true
	_drawing_board.clear()

func _on_guess_drawing() -> void:
	_done_button.disabled = false
	
	_header.editable = true
	_header.text = ''

	_drawing_board.drawable = false
	_drawing_board.set_image(_game.get_local_image())

func _on_choose_word() -> void:
	_pick_a_word_instance = _pick_a_word.instance()
	_pick_a_word_instance.init(_game.local_word_choices())
	add_child(_pick_a_word_instance)
	_pick_a_word_instance.connect('word_picked', self, '_word_picked')

func _word_picked(index : int) -> void:
	_game.rpc_id(Network.server_id, 'pick_word', get_tree().get_network_unique_id(), index)
	_remove_pick_a_word_dialog()

func _remove_pick_a_word_dialog() -> void:
	if not _pick_a_word_instance: return
	remove_child(_pick_a_word_instance)
	_pick_a_word_instance.queue_free()
	_pick_a_word_instance = null

func _on_Done_pressed() -> void:
	if not _game: return
	
	_done_button.disabled = true
	_drawing_board.drawable = false
	_header.editable = false
	
	if _game.get_phase() == Game.Phase_Draw:
		_on_done_phase_draw()
		return

	if _game.get_phase() == Game.Phase_Guess:
		_on_done_phase_guess()
		return

	if _game.get_phase() == Game.Phase_ShowScribbleChain:
		#_drawing_board.clear()
		_done_button.disabled = false
		_on_done_show_scribble_chain()
		return

	if _game.get_phase() == Game.Phase_End:
		_done_button.disabled = false;
		_on_done_end()
		return

func _on_done_end() -> void:
	_room.rpc_id(Network.server_id, 'leave_room')
	
var _scribble_chain := []
var _chain_node : Control
func _on_done_show_scribble_chain() -> void:
	if _scribble_chain.empty():
		if _chain_node:
			get_parent().remove_child(_chain_node)
			_chain_node.queue_free()
			_chain_node = null

		_game.rpc_id(Network.server_id, 'done_show_scribble_chain')
		_done_button.disabled = true
		return
	
	_scribble_chain_handler.set_chain(_scribble_chain)
	_scribble_chain_handler.start()

	_scribble_chain.clear()

func _on_done_phase_draw() -> void:
	_game.rpc_id(Network.server_id, 'update_current_drawing', _drawing_board.get_image_info())
	_done_button.disabled = false

func _on_done_phase_guess() -> void:
	_game.rpc_id(Network.server_id, 'done_guess', _header.text)

func _on_DrawingCanvas_mouse_entered() -> void:
	_drawing_board.set_cursor_as_brush()

func _on_DrawingCanvas_mouse_exited() -> void:
	Input.set_custom_mouse_cursor(null, 0)

func _on_DrawingCanvas_canvas_changed() -> void:
	if not _game: return
	_game.rpc_unreliable_id(Network.server_id, 'update_current_drawing', _drawing_board.get_image_info())

func _on_UpdateTimerTick_timeout() -> void:
	if not _game: return
	
	_time_left_label.clear()

	if not _game.is_phase_timer_ticking(): return
	
	_time_left_label.update_time(
		_game.phase_timer_time_left(),
		_game.phase_timer_time_wait()
	)

func _on_Pallet_color_picked(color) -> void:
	_drawing_board.set_brush_color(color)

func _on_Pallet_eraser_picked() -> void:
	_drawing_board.set_brush_as_eraser()

func _on_Pallet_pencil_picked() -> void:
	_drawing_board.set_brush_as_pencil()

func _on_Pallet_scrap_picked() -> void:
	_drawing_board.clear()

func _on_ScribbleChainHandler_show_chain_part(part) -> void:
	if part is Dictionary:
		_drawing_board.set_image(part)
	if part is String:
		_header.text = part
