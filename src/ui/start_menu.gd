extends Control

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
		Network.rpc_id(Network.server_id, 'create_room', '')
		return
	
	var room := available[randi() % available.size()] as Room
	if not room:
		assert(false)
		return
	
	Network.rpc_id(Network.server_id, 'enter_room', room.id())

