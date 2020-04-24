extends Node2D

const DEFAULT_IP := '127.0.0.1'
const DEFAULT_PORT := 31400
const MAX_PLAYERS := 2

var _players := { }

var _self := { name = '' }


func _ready():
# warning-ignore:return_value_discarded
	get_tree().connect('network_peer_connected', self, '_player_entered')
# warning-ignore:return_value_discarded
	get_tree().connect('network_peer_disconnected', self, '_player_left')

func get_players() -> Array:
	return _players.keys()
	
func enter_lobby(name : String) -> bool:
	return _create_client(name, false)

func create_room(name : String) -> bool:
	return _create_client(name, true)

func _create_client(name : String, server : bool) -> bool:
	_self.name = name
	var peer = NetworkedMultiplayerENet.new()

	if server:
		if peer.create_server(DEFAULT_PORT, MAX_PLAYERS) != OK: return false
	else:
		if peer.create_client(DEFAULT_IP, DEFAULT_PORT) != OK: return false

	get_tree().set_network_peer(peer)
	
	_players[get_tree().get_network_unique_id()] = _self
	return true

func _player_entered(id : int) -> void:
	rpc_id(id, '_add_new_player', _self)

func _player_left(id : int) -> void:
	_players.erase(id)

remote func _add_new_player(data : Dictionary) -> void:
	_players[get_tree().get_rpc_sender_id()] = data
	
