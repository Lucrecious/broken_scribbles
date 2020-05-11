extends Node2D

#const DEFAULT_IP := '127.0.0.1'
const DEFAULT_IP := '18.222.136.215'
const DEFAULT_PORT := 31400
const MAX_PLAYERS := 10

const cert_location := 'user://cert.crt'
const private_key_location := 'user://private.key'

const server_id := 1

signal entered_room_callback(success, room_id, reason)
signal room_added(room_id)
signal room_removed(room_id)
signal client_left_room(id, room_id)

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

func shut_down() ->  void:
	if not _local_peer is WebSocketClient: return
	(_local_peer as WebSocketClient).disconnect_from_host()

func init_client() -> int:
	var client := WebSocketClient.new()
	var url := 'ws://' + DEFAULT_IP + ':' + str(DEFAULT_PORT)
	
	#var cert := X509Certificate.new()
	#cert.load('res://asserts/ssl/cert.crt')
	#client.trusted_ssl_certificate = cert
	
	var success := client.connect_to_url(url, PoolStringArray(), true)
	if success != OK: return success
	get_tree().set_network_peer(client)
	_local_peer = client
	return OK

func init_server() -> int:
	var server := WebSocketServer.new()
	
	#var dir := Directory.new()
	#var cert := X509Certificate.new()
	#var key := CryptoKey.new()
	#if not dir.file_exists(private_key_location):
	#	var crypto := Crypto.new()
	#	key = crypto.generate_rsa(4096)
	#	cert = crypto.generate_self_signed_certificate(key, "CN=%s,O=myorganisation,C=IT" % DEFAULT_IP)
	#else:
	#	cert.load(cert_location)
	#	key.load(private_key_location)
	
	#cert.save(cert_location)
	
	#server.private_key = key
	#server.ssl_certificate = cert

	var success := server.listen(DEFAULT_PORT, PoolStringArray(), true)
	if success != OK: return success
	get_tree().set_network_peer(server)
	_local_peer = server
	return OK

func leave_room(client_id : int, room_id : String) -> void:
	if not is_network_master(): return
	if not room_id in _rooms: return
	if not client_id in _rooms[room_id].clients(): return

	rpc('_remove_client_from_room', client_id, room_id)

remotesync func _remove_client_from_room(id : int, room_id : String) -> void:
	_rooms[room_id].remove_client(id)
	emit_signal('client_left_room', id, room_id)

master func create_room(room_name : String) -> void:
	assert(_local_peer)
	if not _local_peer: return

	var sender_id := get_tree().get_rpc_sender_id()
	if _abort_create_room(sender_id): return

	var room_id := UUID.v4()
	var name := _create_random_name()
	rpc('_add_room', sender_id, room_id, room_name, name)

master func enter_room(room_id : String) -> void:
	assert(_local_peer)
	if not _local_peer: return
	
	var sender_id := get_tree().get_rpc_sender_id()
	if _abort_enter_room(sender_id, room_id): return
	
	var name := _create_random_name()

	rpc('_attempt_enter_room', sender_id, room_id, name)

func _create_random_name() -> String:
	var adjective := Constants.FeelingAdjectives.keys()[randi() % Constants.FeelingAdjectives.size()] as String
	adjective = adjective.to_lower()
	
	var animal := Constants.Animals.keys()[randi() % Constants.Animals.size()] as String
	animal = animal.to_lower()
	
	return '%s %s' % [adjective, animal]

func _abort_enter_room(client_id : int, room_id : String) -> bool:
	if not room_id in _rooms:
		rpc_id(client_id, '_signal_entered_room', false, room_id, Error_room_does_not_exist)
		return true
	
	var in_room := _get_room_for_id(client_id)
	if in_room != '':
		rpc_id(client_id, '_signal_entered_room', false, in_room, Error_client_already_in_room)
		return true
	
	return false

func _abort_create_room(client_id : int) -> bool:
	var in_room := _get_room_for_id(client_id)
	if in_room != '':
		rpc_id(client_id, '_signal_entered_room', false, in_room, Error_client_already_in_room)
		return true
	
	return false

func get_room(room_id : String) -> Room:
	if not room_id in _rooms: return null
	return _rooms[room_id] as Room

func get_room_ids() -> Array:
	return _rooms.keys()

puppetsync func _attempt_enter_room(from_id : int, room_id : String, client_nickname : String) -> void:
	(_rooms[room_id] as Room).add_client(from_id, client_nickname)
	if from_id != get_tree().get_network_unique_id(): return
	_signal_entered_room(true, room_id, Error_none)

puppetsync func _add_room(from_id : int, room_id : String, room_name : String, client_nickname : String) -> void:
	_add_room_node(room_id, room_name, from_id, client_nickname)
	
	if is_network_master():
		_rooms[room_id].connect('just_emptied', self, '_room_just_emptied')

	if from_id != get_tree().get_network_unique_id(): return
	_signal_entered_room(true, room_id, Error_none)

puppetsync func _signal_entered_room(success : bool, room_id : String, reason : int) -> void:
	emit_signal('entered_room_callback', success, room_id, reason)

puppetsync func _remove_room(room_id : String) -> void:
	if not room_id in _rooms: return

	var room := _rooms[room_id] as Room
	if room.clients().size(): return
	
	_rooms.erase(room_id)
	remove_child(room)
	room.queue_free()
	
	emit_signal('room_removed', room_id)

func _add_room_node(room_id : String, nickname : String, creator_id : int, creator_nickname : String) -> void:
	var room = preload('res://src/network/room.tscn').instance()
	room.init(room_id, nickname)
	room.add_client(creator_id, creator_nickname)

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
	_clients[id] = true
	
	_sync(id)

func _sync(id : int) -> void:
	if not is_network_master(): return

	var room_states := {}
	for id in _rooms:
		var r = _rooms[id] as Room
		print("room: ", r._client_2_nickname)
		room_states[id] = {
			nickname = r.nickname(),
			clients = r.clients(),
			client_nicknames = r._client_2_nickname }
	
	rpc_id(id, '_sync_rooms', room_states)

puppet func _sync_rooms(room_states : Dictionary) -> void:
	for id in room_states:
		var clients := room_states[id].clients as Array
		var client_nicknames := room_states[id].client_nicknames as Dictionary
		if not clients.size(): continue
	
		var first := clients[0] as int
		_add_room_node(id, room_states[id].nickname, first, client_nicknames[first])
		_rooms[id]._clients = clients
		_rooms[id]._client_2_nickname = client_nicknames

func _client_left(id : int) -> void:
	_clients.erase(id)
