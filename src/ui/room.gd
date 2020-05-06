extends Control

var _room_id := ''
var _username_scene 

onready var _pick_a_word := preload('res://src/ui/pick_a_word.tscn')

onready var _nickname := $InfoPanel/Nickname
onready var _players := $InfoPanel/Players
onready var _room := Network.get_room(_room_id)

onready var _game_ui := $Game

onready var _play_button := $InfoPanel/Buttons/Play as Button

func init(room_id : String) -> void:
	_room_id = room_id

func _ready() -> void:
	if not _room: return
	
	_game_ui.visible = false
	
	_room.connect('client_added', self, '_update_usernames')
	_room.connect('client_left', self, '_update_usernames')
	_room.connect('game_created', self, '_on_game_created')
	
	_nickname.text = _room.nickname()

	var username_template := $InfoPanel/Players/Username
	username_template.text = ''
	_username_scene = PackedScene.new()
	_username_scene.pack(username_template)

	_update_usernames()

	_setup_leader()

func _setup_leader() -> void:
	var leader_id := _room.clients()[0] as int
	if get_tree().get_network_unique_id() == leader_id:
		_play_button.disabled = false
	else:
		_play_button.disabled = true

func _update_usernames(_id := 0) -> void:
	for c in _players.get_children():
		_players.remove_child(c)
		c.queue_free()
	
	for i in _room.clients():
		var username := _username_scene.instance() as Label
		username.text = str(i)
		_players.add_child(username)

func _on_CopyID_pressed() -> void:
	OS.clipboard = _room_id

func _on_game_created() -> void:
	assert(_room.game())
	_play_button.visible = false
	if not _room.game(): return
	_game_ui.visible = true
	_game_ui.init(_room.game())

func _on_Play_pressed() -> void:
	var leader_id := _room.clients()[0] as int
	if leader_id != get_tree().get_network_unique_id(): return
	
	Network.play_game(_room_id)
	_play_button.disabled = true
