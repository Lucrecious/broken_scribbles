extends Node2D

onready var _start_menu := preload('res://src/ui/start_menu.tscn')

var _current_room : Node2D

func _ready():
	var error := Network.init_client()
	if error != OK:
		var label := Label.new()
		label.rect_position = Vector2(500, 500)
		add_child(label)
		label.text = "Error: " + str(error)
		return

	Network.connect('entered_room_callback', self, '_entered_room')
	Network.connect('client_left_room', self, '_client_left_room')

	add_child(_start_menu.instance())

func _client_left_room(id : int, room_id : String) -> void:
	if id != get_tree().get_network_unique_id(): return

	remove_child(_current_room)
	add_child(_start_menu.instance())

func _entered_room(success : bool, room_id : String, reason : int, is_local: bool) -> void:
	if not success:
		var error := "[error: %s] [room id: '%s'] [is_local: %s]" % [Network.error_2_string(reason), room_id, is_local]
		print(error)
		return
	
	remove_child(get_child(0))

	var room := preload('res://src/ui/room.tscn').instance()
	room.init(room_id)
	add_child(room)
	_current_room = room
