extends Control

var _room_id := ''
var _username_scene 

onready var _nickname := $Panel/Nickname

onready var _players := $Panel/Players

onready var _room := Network.get_room(_room_id)

func init(room_id : String) -> void:
	_room_id = room_id

func _ready() -> void:
	if not _room: return
	
	_room.connect('client_added', self, '_client_added')
	
	_nickname.text = _room.nickname()

	var username_template := $Panel/Players/Username
	username_template.text = ''
	_username_scene = PackedScene.new()
	_username_scene.pack(username_template)

	_update_usernames()

func _client_added(id : int) -> void:
	_update_usernames()

func _update_usernames() -> void:
	for c in _players.get_children():
		_players.remove_child(c)
		c.queue_free()
	
	for i in _room.clients():
		var username := _username_scene.instance() as Label
		username.text = str(i)
		_players.add_child(username)

func _on_CopyID_pressed() -> void:
	OS.clipboard = _room_id
