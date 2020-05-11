extends Control

var _room_id := ''

onready var _pick_a_word := preload('res://src/ui/pick_a_word.tscn')

onready var _nickname := $InfoPanel/Nickname
onready var _players := $Game/PlayerList
onready var _room := Network.get_room(_room_id) as Room
onready var _chat := $Chat

onready var _game_ui := $Game as Control

onready var _play_button := $InfoPanel/Buttons/Play as Button
onready var _time_cycle := $InfoPanel/Buttons/TimeCycle as Button
onready var _time_index := 0 if not _room else _room._draw_sec_index

func init(room_id : String) -> void:
	_room_id = room_id

func game() -> Control:
	return _game_ui

func _gui_input(event: InputEvent) -> void:
	if not event.is_action_pressed('send_chat', false): return
	#if not _text_edit.has_focus(): return

func _ready() -> void:
	if not _room: return
	
	_room.connect('client_added', self, '_send_info')
	_room.connect('client_added', self, '_update_usernames')
	_room.connect('client_left', self, '_on_client_left')
	_room.connect('game_created', self, '_on_game_created')
	_room.connect('received_message', self, '_on_received_message')
	_room.connect('draw_sec_index_changed', self, '_on_draw_sec_index_changed')
	
	_nickname.text = _room.nickname()

	_update_usernames()

	_setup_leader()
	
	_time_cycle.text = str(Constants.get_draw_seconds(-1))

func _send_info(_id : int) -> void:
	send_chat_message('/play to start game')

func _on_received_message(from_id : int, message : String) -> void:
	var names := _room.client_nickname(from_id).split(' ', false)
	var initials := ''
	for n in names:
		initials += n[0]
	
	_chat.add_text('%s:%s' % [initials, message])

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
	var nicknames := []
	for id in _room.clients():
		var nickname := _room.client_nickname(id)
		nicknames.append(nickname)

	_players.update_list(nicknames)

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

func send_chat_message(message : String) -> void:
	_room.rpc_unreliable_id(Network.server_id, 'send_chat_message', message)

func _on_TimeCycle_pressed() -> void:
	if _room.clients().empty(): return
	if _room.clients()[0] != get_tree().get_network_unique_id(): return
	
	var sec := Constants.get_draw_seconds(_time_index) as float
	if sec == -1: return
		
	_time_cycle.text = str(sec)
	_time_index = (_time_index + 1) % Constants.VALID_DRAW_SECONDS.size()
	
	_room.rpc_id(Network.server_id, 'change_drawing_time', _time_index)

func _on_draw_sec_index_changed(index : int) -> void:
	_time_cycle.text = str(Constants.get_draw_seconds(index))

func _on_LeaveRoomButton_pressed() -> void:
	_room.rpc_id(Network.server_id, 'leave_room')
