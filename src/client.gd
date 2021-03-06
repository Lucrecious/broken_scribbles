extends Node2D

onready var _start_menu := preload('res://src/ui/start_menu.tscn')
var _start_menu_instance : Node

onready var _sound_control := $SoundControl

var _current_room : Control

func _ready():
	_start_menu_instance = _start_menu.instance()
	add_child(_start_menu_instance)
	
	var error := Network.init_client()
	if error != OK:
		var label := Label.new()
		label.rect_position = Vector2(500, 500)
		add_child(label)
		label.text = "Error: " + str(error)
		return

	Network.connect('entered_room_callback', self, '_entered_room')
	Network.connect('client_left_room', self, '_client_left_room')

	_start_menu_instance.connect('exit_requested', self, '_exit_requested')

func _client_left_room(id : int, room_id : String) -> void:
	if id != get_tree().get_network_unique_id(): return

	remove_child(_current_room)
	_current_room.queue_free()
	_current_room = null

	_start_menu_instance = _start_menu.instance()
	add_child(_start_menu_instance)
	_start_menu_instance.connect('exit_requested', self, '_exit_requested')

func _entered_room(success : bool, room_id : String, reason : int) -> void:
	if not success:
		var error := "[error: %s] [room id: '%s']" % [Network.error_2_string(reason), room_id]
		print(error)
		return
	
	if _start_menu_instance:
		remove_child(_start_menu_instance)
		_start_menu_instance.queue_free()
		_start_menu_instance = null

	var room := preload('res://src/ui/room.tscn').instance()
	room.init(room_id)
	add_child(room)
	_current_room = room

	_current_room.game().connect('drawing_just_started', _sound_control, 'on_drawing_just_started')
	_current_room._room.connect('draw_sec_index_changed', _sound_control, 'on_draw_sec_index_changed')

func _notification(what):
	if what != MainLoop.NOTIFICATION_WM_QUIT_REQUEST: return
	_exit_requested()

func _exit_requested() -> void:
	Network.shut_down()
	get_tree().quit()
