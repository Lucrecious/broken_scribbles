extends Control

onready var _room_name_edit := $VBox/RoomName as LineEdit
onready var _create_room_button := $VBox/CreateRoom as Button
onready var _enter_room_button := $VBox/EnterRoom as Button
onready var _room_list_select := $VBox/Rooms as ItemList

func _ready() -> void:
	Network.connect('entered_room_callback', self, '_entered_room')
	Network.connect('room_added', self, '_on_room_added')

	_init_room_ids()

func _init_room_ids() -> void:
	_room_ids := get_room_ids()

func _disable_ui():
	_create_room_button.disabled = true
	_enter_room_button.disabled = true
	_room_name_edit.editable = false

func _enable_ui():
	_create_room_button.disabled = false
	_enter_room_button.disabled = false
	_room_name_edit.editable = true

var _room_ids := []
func _on_room_added(room_id : String) -> void:
	_room_ids.append(room_id)
	
	_room_list_select.clear()
	for id in _room_ids:
		var nickname := Network.get_room(id).nickname()
		_room_list_select.add_item(nickname)
	

func _entered_room(success : bool, room_id : String, reason : int, is_local: bool) -> void:
	call_deferred('_enable_ui')

func _on_CreateRoom_pressed() -> void:
	Network.rpc_id(Network.server_id, 'create_room', _room_name_edit.text)
	_disable_ui()
	
func _on_EnterRoom_pressed() -> void:
	var items := _room_list_select.get_selected_items()
	if items.empty(): return
	var room_id := _room_ids[items[0]] as String
	Network.rpc_id(Network.server_id, 'enter_room', room_id)
	_disable_ui()
