extends Node2D

class_name Room

signal client_added(id)
signal client_left(id)
signal just_emptied(room_id)
signal game_created

# State
var _id := ''
var _nickname := ''
var _clients := []

onready var _game := preload('res://src/game/game.tscn')

var _game_instance : Game

func _ready() -> void:
	get_tree().connect('network_peer_disconnected', self, '_client_disconnected')

func init(id : String, nickname : String) -> void:
	_id = id
	name = _id
	_nickname = nickname

master func add_game() -> void:
	_add_game(_clients)
	for client in _clients:
		rpc_id(client, '_add_game', _clients)

	_game_instance.start_game()

remotesync func _add_game(clients : Array) -> void:
	if _game_instance: return
	var game := _game.instance() as Game
	game.init({ players = clients })
	add_child(game)
	_game_instance = game
	emit_signal('game_created')

func game() -> Game:
	return _game_instance

func id() -> String:
	return _id;

func nickname() -> String:
	return _nickname

func clients() -> Array:
	return _clients.duplicate()

func add_client(id : int) -> void:
	_clients.append(id)
	emit_signal('client_added', id)

master func _add_client(id : int) -> void:
	_clients.append(id)

func _client_disconnected(id : int) -> void:
	if not id in _clients: return
	
	_clients.erase(id)
	emit_signal('client_left', id)

	if _clients.size(): return
	emit_signal('just_emptied', _id)
