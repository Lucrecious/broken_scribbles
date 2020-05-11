extends Control

signal exit_requested

func _on_TakeASeat_pressed() -> void:
	_find_a_room()

func _find_a_room():
	var rooms := Network.get_room_ids()
	var available := []
	for id in rooms:
		var room := Network.get_room(id)
		if not room: continue
		if room.game_started(): continue
		if room.clients().size() > 7: continue
		available.append(room)
	
	if available.empty():
		var room_name := _get_random_room_name()
		Network.rpc_id(Network.server_id, 'create_room', room_name)
		return
	
	var room := available[randi() % available.size()] as Room
	if not room:
		assert(false)
		return
	
	Network.rpc_id(Network.server_id, 'enter_room', room.id())

func _get_random_room_name() -> String:
	var adjective := Constants.RoomAdjectives.keys()[randi() % Constants.RoomAdjectives.size()] as String
	var noun := Constants.RoomNouns.keys()[randi() % Constants.RoomNouns.size()] as String

	return '%s %s' % [adjective.replace('_', ' ').to_lower(), noun.replace('_', ' ').to_lower()]

func _on_Exit_pressed() -> void:
	emit_signal('exit_requested')
