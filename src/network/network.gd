extends Node2D

#const DEFAULT_IP := '127.0.0.1'
const DEFAULT_IP := '18.222.136.215'
const DEFAULT_PORT := 31400
const MAX_PLAYERS := 10

const cert_location := 'user://cert.crt'
const private_key_location := 'user://private.key'

const server_id := 1

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

var _local_peer : WebSocketMultiplayerPeer = null

var _clients := { }
var _rooms := { }

func _ready():
	get_tree().connect('network_peer_connected', self, '_client_entered')
	get_tree().connect('network_peer_disconnected', self, '_client_left')

func _process(delta: float) -> void:
	if _local_peer is WebSocketServer:
		_listen_server(_local_peer as WebSocketServer)
	elif _local_peer is WebSocketClient:
		_listen_client(_local_peer as WebSocketClient)

func _listen_server(server : WebSocketServer) -> void:
	if not server.is_listening(): return
	server.poll()

func _listen_client(client : WebSocketClient) -> void:
	if client.get_connection_status() != NetworkedMultiplayerPeer.CONNECTION_CONNECTED &&\
		client.get_connection_status() != NetworkedMultiplayerPeer.CONNECTION_CONNECTING: return
	
	client.poll()

func print_rooms() -> void:
	for id in _rooms:
		var r = _rooms[id]
		prints(r.nickname(), r.id(), r.clients())

func init_client() -> int:
	var client := WebSocketClient.new()
	var url := 'wss://' + DEFAULT_IP + ':' + str(DEFAULT_PORT)
	
	var cert := X509Certificate.new()
	cert.load(cert_location)
	client.trusted_ssl_certificate = cert
	
	
	var success := client.connect_to_url(url, PoolStringArray(), true)
	if success != OK: return success
	get_tree().set_network_peer(client)
	_local_peer = client
	return OK

func init_server() -> int:
	var server := WebSocketServer.new()
	
	var dir := Directory.new()
	var cert := X509Certificate.new()
	var key := CryptoKey.new()
	if not dir.file_exists(private_key_location):
		var crypto := Crypto.new()
		key = crypto.generate_rsa(4096)
		cert = crypto.generate_self_signed_certificate(key, "CN=%s,O=myorganisation,C=IT" % DEFAULT_IP)
	else:
		cert.load(cert_location)
		key.load(private_key_location)
	
	cert.save(cert_location)
	
	server.private_key = key
	server.ssl_certificate = cert

	var success := server.listen(DEFAULT_PORT, PoolStringArray(), true)
	if success != OK: return success
	print(success)
	get_tree().set_network_peer(server)
	_local_peer = server
	return OK

master func create_room(room_name : String) -> void:
	assert(_local_peer)
	if not _local_peer: return

	var sender_id := get_tree().get_rpc_sender_id()
	if _abort_create_room(sender_id): return

	var room_id := UUID.v4()
	rpc('_add_room', sender_id, room_id, room_name)

master func enter_room(room_id : String) -> void:
	assert(_local_peer)
	if not _local_peer: return
	
	var sender_id := get_tree().get_rpc_sender_id()
	if _abort_enter_room(sender_id, room_id): return
	
	rpc('_attempt_enter_room', sender_id, room_id)

master func play_game(room_id : String) -> void:
	rpc('_play_game', get_tree().get_rpc_sender_id(), room_id)

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

func get_room(room_id : String) -> Room:
	if not room_id in _rooms: return null
	return _rooms[room_id] as Room

puppetsync func _attempt_enter_room(from_id : int, room_id : String) -> void:
	(_rooms[room_id] as Room).add_client(from_id)
	if from_id != get_tree().get_network_unique_id(): return
	_signal_entered_room(true, room_id, Error_none, from_id == get_tree().get_network_unique_id())

puppetsync func _add_room(from_id : int, room_id : String, room_name : String) -> void:
	_add_room_node(room_id, room_name, from_id)
	_rooms[room_id].connect('just_emptied', self, '_room_just_emptied')

	if from_id != get_tree().get_network_unique_id(): return
	_signal_entered_room(true, room_id, Error_none, from_id == get_tree().get_network_unique_id())

puppetsync func _signal_entered_room(success : bool, room_id : String, reason : int, is_local : bool) -> void:
	emit_signal('entered_room_callback', success, room_id, reason, is_local)
		
puppetsync func _play_game(id : int, room_id : String) -> void:
	if not room_id in _rooms: return
	if not id in _rooms[room_id].clients(): return
	_rooms[room_id].add_game()

puppetsync func _remove_room(room_id : String) -> void:
	if not room_id in _rooms: return

	var room := _rooms[room_id] as Room
	if room.clients().size(): return
	
	_rooms.erase(room_id)
	remove_child(room)
	room.queue_free()

func _add_room_node(room_id : String, nickname : String, creator_id : int) -> void:
	var room = preload('res://src/network/room.tscn').instance()
	room.init(room_id, nickname)
	room.add_client(creator_id)

	add_child(room)
	_rooms[room_id] = room
	emit_signal('room_added', room_id)
		
func _get_room_for_id(id : int) -> String:
	for room_id in _rooms:
		var room := _rooms[room_id] as Room
		if id in room.clients(): return room_id
	
	return ''

func _room_just_emptied(room_id : String) -> void:
	assert(is_network_master())
	if not is_network_master(): return
	
	rpc('_remove_room', room_id)

func _client_entered(id : int) -> void:
	print('client entered: %d' % id)
	_clients[id] = true
	
	_sync(id)

func _sync(id : int) -> void:
	if not is_network_master(): return

	var room_states := {}
	for id in _rooms:
		var r = _rooms[id] as Room
		room_states[id] = { nickname = r.nickname(), clients = r.clients() }
	
	rpc_id(id, '_sync_rooms', room_states)

puppet func _sync_rooms(room_states : Dictionary) -> void:
	for id in room_states:
		var clients := room_states[id].clients as Array
		if not clients.size(): continue

		_add_room_node(id, room_states[id].nickname, clients[0])
		_rooms[id]._clients = clients

func _client_left(id : int) -> void:
	_clients.erase(id)
