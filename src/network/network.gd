extends Node2D

const DEFAULT_IP := '127.0.0.1'
const DEFAULT_PORT := 31400
const MAX_PLAYERS := 10

signal create_room_attempted(room_name)
signal enter_room_attempted(room_name)

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

func _client_entered(id : int) -> void:
	_clients[id] = name

func _client_left(id : int) -> void:
	_clients.erase(id)

func init_local_peer() -> int:
	return _create_server_or_client()

func create_room(room_name : String) -> void:
	assert(_local_peer)

	rpc('_attempt_add_room', get_tree().get_network_unique_id(), room_name)

func enter_room(room_name : String) -> void:
	assert(_local_peer)

	rpc('_attempt_enter_room', get_tree().get_network_unique_id(), room_name)

master func _attempt_enter_room(from_id : int, room_name : String) -> void:
	if not room_name in _rooms:
		rpc_id(from_id, '_signal_enter_room_attempted', '')
		return
	
	rpc('_enter_room', from_id, room_name)
	rpc_id(from_id, '_signal_enter_room_attempted', room_name)

master func _attempt_add_room(from_id : int, room_name : String) -> void:
	if room_name in _rooms:
		rpc_id(from_id, '_signal_create_room_attempted', '')
		return
	
	rpc('_add_room', get_tree().get_rpc_sender_id(), room_name)
	rpc_id(from_id, '_signal_create_room_attempted', room_name)

remotesync func _add_room(id : int, name : String) -> void:
	var game = preload('res://src/game/game.tscn').instance()
	game.name = name
	game.init(id)
	add_child(game)
	_rooms[name] = game

remotesync func _enter_room(id : int, room_name : String) -> void:
	if not room_name in _rooms:
		assert(false)
		return
	
	var game = _rooms[room_name]
	game.add_player(id)

remotesync func _signal_create_room_attempted(room_name : String) -> void:
	emit_signal('create_room_attempted', room_name)

remotesync func _signal_enter_room_attempted(room_name : String) -> void:
	emit_signal('enter_room_attempted', room_name)
		
func _create_server_or_client() -> int:
	var peer = NetworkedMultiplayerENet.new()
	
	var success = peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	if success != OK:
		success = peer.create_client(DEFAULT_IP, DEFAULT_PORT)
	
	if success != OK: return success
	
	get_tree().set_network_peer(peer)

	_local_peer = peer

	return OK
