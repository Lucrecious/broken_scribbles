extends Node2D

const DEFAULT_IP := '127.0.0.1'
const DEFAULT_PORT := 31400
const MAX_PLAYERS := 10

signal entered_room_callback(success, room_id, reason)
signal room_added(room_id)

enum {
	Error_none = 0,
	Error_general,
	Error_room_does_not_exist,
	Error_client_already_in_room
}

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
	if _get_room_for_id(local_id) != '':
		_signal_entered_room(false, '', Error_client_already_in_room)
		return

	rpc('_attempt_add_room', local_id, room_name)

func enter_room(room_id : String) -> void:
	assert(_local_peer)
	if not _local_peer: return
	
	if not room_id in _rooms:
		_signal_entered_room(false, '', Error_room_does_not_exist)
		return
	
	var local_id := get_tree().get_network_unique_id()
	if _get_room_for_id(local_id) != '':
		_signal_entered_room(false, '', Error_client_already_in_room)
		return
	
	rpc('_attempt_enter_room', local_id, room_id)
	
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
		_add_room(id, room_states[id].nickname)
		_rooms[id]._clients = room_states[id].clients

func _get_room_for_id(id : int) -> String:
	for room_id in _rooms:
		var room := _rooms[room_id] as Room
		if id in room.clients(): return room_id
	
	return ''

master func _attempt_enter_room(from_id : int, room_id : String) -> void:
	rpc('_enter_room', from_id, room_id)
	rpc_id(from_id, '_signal_entered_room', true, room_id, Error_none)

master func _attempt_add_room(from_id : int, room_name : String) -> void:
	var room_id := UUID.v4()
	rpc('_add_room', room_id, room_name)
	(_rooms[room_id] as Room).add_client(from_id)
	rpc_id(from_id, '_signal_entered_room', true, room_id, Error_none)

remotesync func _add_room(room_id : String, nickname : String) -> void:
	var room = preload('res://src/network/room.tscn').instance()
	room.init(room_id, nickname)
	add_child(room)
	_rooms[room_id] = room
	emit_signal('room_added', room_id)

remotesync func _enter_room(id : int, room_id : String) -> void:
	(_rooms[room_id] as Room).add_client(id)


remotesync func _signal_entered_room(success : bool, room_id : String, reason : int) -> void:
	emit_signal('entered_room_callback', success, room_id, reason)
		
func _create_server_or_client() -> int:
	var peer = NetworkedMultiplayerENet.new()
	
	var success = peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	if success != OK:
		success = peer.create_client(DEFAULT_IP, DEFAULT_PORT)
	
	if success != OK: return success
	
	get_tree().set_network_peer(peer)

	_local_peer = peer

	return OK
