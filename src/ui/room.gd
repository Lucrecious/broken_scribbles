extends Control

var _room_id := ''

onready var _pick_a_word := preload('res://src/ui/pick_a_word.tscn')

onready var _nickname := $InfoPanel/Nickname
onready var _players := $InfoPanel/Players
onready var _room := Network.get_room(_room_id) as Room

onready var _game_ui := $Game

onready var _play_button := $InfoPanel/Buttons/Play as Button

func init(room_id : String) -> void:
	_room_id = room_id

func _ready() -> void:
	if not _room: return
	
	_game_ui.visible = false
	
	_room.connect('client_added', self, '_update_usernames')
	_room.connect('client_left', self, '_on_client_left')
	_room.connect('game_created', self, '_on_game_created')
	
	_nickname.text = _room.nickname()

	_update_usernames()

	_setup_leader()

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
