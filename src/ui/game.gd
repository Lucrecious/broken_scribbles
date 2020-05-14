extends Control

signal drawing_just_started

var _game : Game
var _room : Room

onready var _header := $Header as LineEdit
onready var _drawing_board := $DrawingCanvas
onready var _pallet := $Pallet
onready var _time_left_label := $TimeLeft as TimeLeftControl
onready var _player_list := $PlayerList

onready var _from_arrow := $FromArrow

onready var _pick_a_word := $PickAWord

onready var _scribble_chain_handler := $ScribbleChainHandler

func init(room : Room, game) -> void:
	_room = room;
	_game = game
	_game.connect('phase_changed', self, '_phase_changed')
	_game.connect('phase_timeout', self, '_phase_timeout')
	_game.connect('phase_timer_started', self, '_phase_timer_started')

	_player_list.select(_game.players().find(get_tree().get_network_unique_id()))
	
func _ready() -> void:
	_time_left_label.clear()
	_pallet.init()
	_from_arrow.visible = false
	
func _phase_timer_started() -> void:
	if _game.get_phase() == Game.Phase_Draw:
		emit_signal('drawing_just_started')

func _phase_timeout() -> void:
	_drawing_board.drawable = false
	_header.editable = false

	if _game.get_phase() == Game.Phase_Draw:
		_game.rpc_id(Network.server_id, 'update_current_part', _drawing_board.get_image_info())
		return
	
	if _game.get_phase() == Game.Phase_Guess:
		_game.rpc_id(Network.server_id, 'update_current_part', _header.text)
		return

func _phase_changed(old_phase : int, new_phase : int) -> void:
	if old_phase == Game.Phase_ChooseWord:
		_pick_a_word.visible = false
	
	_header.placeholder_text = ''

	if new_phase == Game.Phase_End:
		_header.editable = true
		_header.placeholder_text = 'Type anything...'
		_header.text = ''
		_drawing_board.clear()
		_drawing_board.drawable = true
		_player_list.select(_game.players().find(get_tree().get_network_unique_id()))
		return

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
		_time_left_label.hide_numbers()
		_time_left_label.modulate = Color.coral
		_header.editable = false
		_header.text = ''
		_drawing_board.drawable = false
		_drawing_board.clear()

		_on_done_show_scribble_chain()
		return

	if new_phase == Game.Phase_End:
		return

func _on_draw_guess() -> void:
	_header.editable = false

	var part := _game.holding_part() as Dictionary
	
	if part.part is String:
		_header.text = part.part.replace('_', ' ')
	else:
		_header.text = '* Error: Draw Anything *'

	_drawing_board.drawable = true
	_drawing_board.clear()

func _on_guess_drawing() -> void:
	_header.placeholder_text = 'Make your guess!'
	_header.editable = true
	_header.text = ''

	_drawing_board.drawable = false

	var part := _game.holding_part() as Dictionary
	if part.part is Dictionary:
		_drawing_board.set_image(_game.holding_part())
	else:
		_drawing_board.clear()

func _on_choose_word() -> void:
	_pick_a_word.visible = true
	_pick_a_word.clear()
	_pick_a_word.init(_game.local_word_choices())
	_pick_a_word.connect('word_picked', self, '_word_picked')

func _word_picked(index : int) -> void:
	_game.rpc_id(Network.server_id, 'pick_word', get_tree().get_network_unique_id(), index)

var _show_scribble_chain_index := 0
func _on_done_show_scribble_chain() -> void:
	var parts := _game.get_parts(_show_scribble_chain_index) as Array

	if parts.empty(): return

	_player_list.select(_game.players().find(_game.players()[_show_scribble_chain_index]))

	_show_scribble_chain_index += 1
	
	_scribble_chain_handler.set_chain(parts)
	_scribble_chain_handler.start()

func _on_DrawingCanvas_mouse_entered() -> void:
	_drawing_board.set_cursor_as_brush()

func _on_DrawingCanvas_mouse_exited() -> void:
	Input.set_custom_mouse_cursor(null, 0)

func _on_DrawingCanvas_canvas_changed() -> void:
	if not _game: return
	_game.rpc_unreliable_id(Network.server_id, 'update_current_part', _drawing_board.get_image_info())

func _on_UpdateTimerTick_timeout() -> void:
	if not _game: return
	
	_time_left_label.clear()

	if not _game.is_phase_timer_ticking(): return
	
	_time_left_label.update_time(
		_game.phase_timer_time_left(),
		_game.phase_timer_time_wait())

func _on_Pallet_color_picked(color) -> void:
	_drawing_board.set_brush_color(color)

func _on_Pallet_eraser_picked() -> void:
	_drawing_board.set_brush_as_eraser()

func _on_Pallet_pencil_picked() -> void:
	_drawing_board.set_brush_as_pencil()

func _on_Pallet_scrap_picked() -> void:
	_drawing_board.clear()

func _on_ScribbleChainHandler_show_chain_part(part) -> void:
	if not part:
		_from_arrow.visible = false
		_from_arrow.flip_v = false
		return
	
	if part is Dictionary:
		_drawing_board.set_image(part)
	if part is String:
		_header.text = part.replace('_', ' ')
	
	# This just skips the first part...
	if not _from_arrow.visible:
		if not _from_arrow.flip_v:
			_from_arrow.flip_v = true
			return
			
		_from_arrow.visible = true
		_from_arrow.flip_v = false
	
	_from_arrow.flip_v = not _from_arrow.flip_v

func _on_Header_text_entered(new_text: String) -> void:
	if new_text.strip_edges().empty(): return
	if not _game: return
	if _game.get_phase() != Game.Phase_Guess: return
	_header.editable = false
	_game.rpc_id(Network.server_id, 'update_current_part', _header.text)
