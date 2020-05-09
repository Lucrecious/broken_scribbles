extends Control

var _room_id := ''

onready var _pick_a_word := preload('res://src/ui/pick_a_word.tscn')

onready var _nickname := $InfoPanel/Nickname
onready var _players := $InfoPanel/Players
onready var _room := Network.get_room(_room_id) as Room

onready var _text_edit := $Chat/Panel/VBox/TypingBorder/TypingPanel/TextEdit as TextEdit
onready var _chat_history := $Chat/Panel/VBox/HistoryBorder/HistoryPanel/Chat as Label

onready var _game_ui := $Game

onready var _play_button := $InfoPanel/Buttons/Play as Button

func init(room_id : String) -> void:
	_room_id = room_id

func _gui_input(event: InputEvent) -> void:
	if not event.is_action_pressed('send_chat', false): return
	if not _text_edit.has_focus(): return

func _ready() -> void:
	$Game/Center/DrawingPanel/Center/Background.self_modulate = Color.black
	if not _room: return
	
	_game_ui.visible = false
	
	_room.connect('client_added', self, '_update_usernames')
	_room.connect('client_left', self, '_on_client_left')
	_room.connect('game_created', self, '_on_game_created')
	_room.connect('received_message', self, '_on_received_message')
	
	_nickname.text = _room.nickname()

	_update_usernames()

	_setup_leader()

func _on_received_message(from_id : int, message : String) -> void:
	message = '%d: %s' % [from_id, message]
	var lines := _chat_history.text.split('\n', false)
	lines += message.split('\n')
	for _i in range(_chat_history.max_lines_visible, lines.size()):
		lines.remove(0)
	
	_chat_history.text = ''
	for line in lines:
		_chat_history.text += '%s\n' % line

func _on_client_left(_id : int) -> void:
	_update_usernames()
	_setup_leader()

func _setup_leader() -> void:
	_play_button.disabled = true
	if not _room.clients().size(): return
	
	var leader_id := _room.clients()[0] as int
	if get_tree().get_network_unique_id() != leader_id: return
	_play_button.disabled = false

func _update_usernames(_id := 0) -> void:
	_players.clear()
	for id in _room.clients():
		_players.add_item(str(id))

func _on_game_created() -> void:
	assert(_room.game())
	_play_button.visible = false
	if not _room.game(): return
	_game_ui.visible = true
	_game_ui.init(_room, _room.game())

func _on_Play_pressed() -> void:
	var leader_id := _room.clients()[0] as int
	if leader_id != get_tree().get_network_unique_id(): return
	
	_room.rpc_id(Network.server_id, 'play_game')
	_play_button.disabled = true

func _on_Leave_pressed() -> void:
	_room.rpc_id(Network.server_id, 'leave_room')

func _on_TextEdit_text_changed() -> void:
	if not Input.is_action_just_pressed('send_chat'): return
	var message := _text_edit.text
	_text_edit.text = ''
	
	_room.rpc_unreliable_id(Network.server_id, 'send_chat_message', message)
