extends Control

onready var _username_edit := $VBox/Username as LineEdit
onready var _create_room_button := $VBox/CreateRoom as Button
onready var _enter_room_button := $VBox/EnterRoom as Button
onready var _room_name_edit := $VBox/RoomName as LineEdit

func _ready() -> void:
	Network.connect('create_room_attempted', self, '_create_room_attempted')
	Network.connect('enter_room_attempted', self, '_enter_room_attempted')

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

func _create_room_attempted(room_name : String) -> void:
	call_deferred('_enable_ui')
	if room_name == '':
		print('Error creating room...')	
		return
	
	prints('Created room: ', room_name)

func _enter_room_attempted(room_name : String) -> void:
	call_deferred('_enable_ui')
	if room_name == '':
		print('Room does not exist')
		return
	
	prints('Entered room: ', room_name)

func _on_CreateRoom_pressed() -> void:
	Network.create_room(_room_name_edit.text)
	_disable_ui()
	
func _on_EnterRoom_pressed() -> void:
	Network.enter_room(_room_name_edit.text)
	_disable_ui()
