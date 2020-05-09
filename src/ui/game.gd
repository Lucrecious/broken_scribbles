extends Control

var _game : Game
var _room : Room

onready var _pick_a_word := preload('res://src/ui/pick_a_word.tscn')

onready var _header := $Header as TextEdit
onready var _drawing_board := $Center/DrawingPanel/Center/Background/DrawingCanvas
onready var _done_button := $Done
onready var _pallet := $Pallet

var _pick_a_word_instance : Control

func _ready() -> void:
	for n in _pallet_names:
		_pallet.add_item(n)

func init(room : Room, game : Game) -> void:
	_room = room;
	_game = game
	_game.connect('phase_changed', self, '_phase_changed')
	_game.connect('received_scribble_chain', self, '_on_received_scribble_chain')

func _on_received_scribble_chain(player_id : int) -> void:
	_scribble_chain = _game._scribble_chains[player_id]
	_done_button.disabled = false

func _phase_changed(_old_phase : int, new_phase : int) -> void:
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
		_header.readonly = true
		_drawing_board.drawable = false
		return

	if new_phase == Game.Phase_End:
		_done_button.disabled = false
		return

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
	_game.rpc_id(Network.server_id, 'pick_word', get_tree().get_network_unique_id(), index)

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
	
	for i in range(_scribble_chain.size()):
		var val = _scribble_chain[i]
		if val is String: _scribble_chain[i] = val
		if not val is Dictionary: continue
		var image := _drawing_board.get_image_from(val) as Image
		_scribble_chain[i] = image
	
	var chain_node := preload('res://src/ui/scribble_chain.tscn').instance()
	chain_node.init(_scribble_chain)
	get_parent().add_child(chain_node)
	#move_child(chain_node, 0)
	_chain_node = chain_node
	_chain_node.rect_position = Vector2(0, 300)

	_scribble_chain.clear()

func _on_done_phase_draw() -> void:
	_game.rpc_id(Network.server_id, 'done_drawing', _drawing_board.get_image_info())

func _on_done_phase_guess() -> void:
	_game.rpc_id(Network.server_id, 'done_guess', _header.text)

var _pallet_colors := [Color.blue, Color.black, Color.green, Color.red]
var _pallet_names := 'blue,black,green,red'.split(',')
func _on_Pallet_item_selected(index: int) -> void:
	_drawing_board.set_brush_color(_pallet_colors[index])

func _on_DrawingCanvas_mouse_entered() -> void:
	_drawing_board.set_cursor_as_brush()


func _on_DrawingCanvas_mouse_exited() -> void:
	Input.set_custom_mouse_cursor(null, 0)
