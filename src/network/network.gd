extends Node2D

const DEFAULT_IP := '127.0.0.1'
const DEFAULT_PORT := 31400
const MAX_PLAYERS := 10

signal entered_room_callback(success, room_id, reason, is_local)
signal room_added(room_id)

enum {
	Error_none = 0,
	Error_unknown,
	Error_room_does_not_exist,
	Error_client_already_in_room
}

func error_2_string(error : int) -> String:
	match error:
		Error_none: return "None"
		Error_unknown: return "Unknown"
		Error_room_does_not_exist: return "Room does not exist"
		Error_client_already_in_room: return "Client already in room"
	
	return str(error)

var _local_peer : NetworkedMultiplayerENet = null

var _clients := { }
var _rooms := { }

func _ready():
	get_tree().connect('network_peer_connected', self, '_client_entered')
	get_tree().connect('network_peer_disconnected', self, '_client_left')

func print_rooms() -> void:
	for id in _rooms:
		var r = _rooms[id]
		prints(r.nickname(), r.id(), r.clients())

func init_local_peer() -> int:
	return _create_server_or_client()

func create_room(room_name : String) -> void:
	assert(_local_peer)
	if not _local_peer: return

	var local_id := get_tree().get_network_unique_id()
	if _abort_create_room(local_id): return

	rpc('_attempt_add_room', local_id, room_name)

func enter_room(room_id : String) -> void:
	assert(_local_peer)
	if not _local_peer: return
	
	var local_id := get_tree().get_network_unique_id()
	if _abort_enter_room(local_id, room_id): return
	
	rpc('_attempt_enter_room', local_id, room_id)

func get_room(room_id : String) -> Room:
	if not room_id in _rooms: return null
	return _rooms[room_id] as Room

func play_game(room_id : String) -> void:
	rpc('_play_game', get_tree().get_network_unique_id(), room_id)
	
master func _play_game(id : int, room_id : String) -> void:
	if not room_id in _rooms: return
	if not id in _rooms[room_id].clients(): return
	_rooms[room_id].add_game()

func _abort_enter_room(client_id : int, room_id : String) -> bool:
	var is_local := client_id == get_tree().get_network_unique_id()

	if not room_id in _rooms:
		rpc_id(client_id, '_signal_entered_room', false, room_id, Error_room_does_not_exist, is_local)
		return true
	
	var in_room := _get_room_for_id(client_id)
	if in_room != '':
		rpc_id(client_id, '_signal_entered_room', false, in_room, Error_client_already_in_room, is_local)
		return true
	
	return false

func _abort_create_room(client_id : int) -> bool:
	var is_local := client_id == get_tree().get_network_unique_id()

	var in_room := _get_room_for_id(client_id)
	if in_room != '':
		rpc_id(client_id, '_signal_entered_room', false, in_room, Error_client_already_in_room, is_local)
		return true
	
	return false

func _client_entered(id : int) -> void:
	_clients[id] = true

	if not is_network_master(): return
	
	_sync(id)

func _client_left(id : int) -> void:
	_clients.erase(id)

func _sync(id : int) -> void:
	var room_states := {}
	for id in _rooms:
		var r = _rooms[id] as Room
		room_states[id] = { nickname = r.nickname(), clients = r.clients() }
	
	rpc_id(id, '_sync_rooms', room_states)
	
remotesync func _sync_rooms(room_states : Dictionary) -> void:
	for id in room_states:
		var clients := room_states[id].clients as Array
		if not clients.size(): continue

		_add_room(id, room_states[id].nickname, clients[0])
		_rooms[id]._clients = clients

func _get_room_for_id(id : int) -> String:
	for room_id in _rooms:
		var room := _rooms[room_id] as Room
		if id in room.clients(): return room_id
	
	return ''

master func _attempt_enter_room(from_id : int, room_id : String) -> void:
	if _abort_enter_room(from_id, room_id): return

	rpc('_enter_room', from_id, room_id)
	rpc_id(from_id, '_signal_entered_room', true, room_id, Error_none, from_id == get_tree().get_network_unique_id())

master func _attempt_add_room(from_id : int, room_name : String) -> void:
	if _abort_create_room(from_id): return

	var room_id := UUID.v4()
	rpc('_add_room', room_id, room_name, from_id)
	_rooms[room_id].connect('just_emptied', self, '_room_just_emptied')

	rpc_id(from_id, '_signal_entered_room', true, room_id, Error_none, from_id == get_tree().get_network_unique_id())

func _room_just_emptied(room_id : String) -> void:
	assert(is_network_master())
	if not is_network_master(): return
	
	rpc('_remove_room', room_id)

remotesync func _remove_room(room_id : String) -> void:
	if not room_id in _rooms: return

	var room := _rooms[room_id] as Room
	if room.clients().size(): return
	
	_rooms.erase(room_id)
	remove_child(room)
	room.queue_free()

remotesync func _add_room(room_id : String, nickname : String, creator_id : int) -> void:
	var room = preload('res://src/network/room.tscn').instance()
	room.init(room_id, nickname)
	room.add_client(creator_id)

	add_child(room)
	_rooms[room_id] = room
	emit_signal('room_added', room_id)

remotesync func _enter_room(id : int, room_id : String) -> void:
	(_rooms[room_id] as Room).add_client(id)


remotesync func _signal_entered_room(success : bool, room_id : String, reason : int, is_local : bool) -> void:
	emit_signal('entered_room_callback', success, room_id, reason, is_local)
		
func _create_server_or_client() -> int:
	var peer = NetworkedMultiplayerENet.new()
	
	var success = peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	if success != OK:
		success = peer.create_client(DEFAULT_IP, DEFAULT_PORT)
	
	if success != OK: return success
	
	get_tree().set_network_peer(peer)

	_local_peer = peer

	return OK
