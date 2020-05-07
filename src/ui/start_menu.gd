extends Control

onready var _username_edit := $VBox/Username as LineEdit
onready var _create_room_button := $VBox/CreateRoom as Button
onready var _enter_room_button := $VBox/EnterRoom as Button
onready var _room_name_edit := $VBox/RoomName as LineEdit

func _ready() -> void:
	Network.connect('entered_room_callback', self, '_entered_room')

func _disable_ui():
	_username_edit.editable = false
	_create_room_button.disabled = true
	_enter_room_button.disabled = true
	_room_name_edit.editable = false

func _enable_ui():
	_username_edit.editable = true
	_create_room_button.disabled = false
	_enter_room_button.disabled = false
	_room_name_edit.editable = true

func _entered_room(success : bool, room_id : String, reason : int, is_local: bool) -> void:
	call_deferred('_enable_ui')

func _on_CreateRoom_pressed() -> void:
	Network.rpc_id(Network.server_id, 'create_room', _room_name_edit.text)
	_disable_ui()
	
func _on_EnterRoom_pressed() -> void:
	Network.rpc_id(Network.server_id, 'enter_room', _room_name_edit.text)
	_disable_ui()

func _on_Debug_pressed() -> void:
	Network.print_rooms()
