extends Node2D

func _ready():
	if Network.init_local_peer() != OK: return
	var start_menu := preload('res://src/ui/start_menu.tscn').instance()
	add_child(start_menu)

	Network.connect('entered_room_callback', self, '_entered_room')

func _entered_room(success : bool, room_id : String, reason : int, is_local: bool) -> void:
	if not success:
		var error := "[error: %s] [room id: '%s'] [is_local: %s]" % [Network.error_2_string(reason), room_id, is_local]
		print(error)
		return
	
	remove_child(get_child(0))

	var room := preload('res://src/ui/room.tscn').instance()
	room.init(room_id)
	add_child(room)
