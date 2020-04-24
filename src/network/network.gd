extends Node2D

const DEFAULT_IP := '127.0.0.1'
const DEFAULT_PORT := 31400
const MAX_PLAYERS := 2

var _rooms := {}

var _players := { }

var _self := { name = '' }

func query_player_name(id : int) -> String:
	return _players.get(id, '');

func _ready():
# warning-ignore:return_value_discarded
	get_tree().connect('network_peer_connected', self, '_player_entered')
# warning-ignore:return_value_discarded
	get_tree().connect('network_peer_disconnected', self, '_player_left')
	
func enter_lobby(name : String) -> bool:
	var peer = NetworkedMultiplayerENet.new()
	_self.name = name
	if peer.create_client(DEFAULT_IP, DEFAULT_PORT) != OK: return false
	get_tree().set_network_peer(peer)

	_players[get_tree().get_network_unique_id()] = _self
	return true

func create_room(_room_name : String, name : String) -> bool:
	_self.name = name
	var peer = NetworkedMultiplayerENet.new()
	if peer.create_server(DEFAULT_PORT, MAX_PLAYERS) != OK: return false
	get_tree().set_network_peer(peer)

	_players[get_tree().get_network_unique_id()] = _self
	return true

func _input(_event):
	if Input.is_action_just_pressed('ui_accept'):
		print(_players)


func _player_entered(id : int):
	rpc_id(id, '_add_new_player', _self)

remote func _add_new_player(data : Dictionary) -> void:
	_players[get_tree().get_rpc_sender_id()] = data
	
