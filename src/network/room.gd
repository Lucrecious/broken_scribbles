extends Node2D

class_name Room

signal client_added(id)
signal client_left(id)
signal just_emptied(room_id)
signal received_message(id, message)
signal draw_sec_index_changed(new_sec)
signal game_created

# State
var _id := ''
var _nickname := ''
var _clients := []

var _draw_sec_index := Constants.DEFAULT_DRAW_SECOND_INDEX as int

onready var _game := preload('res://src/game/game.tscn')

var _game_instance : Game

func _ready() -> void:
	get_tree().connect('network_peer_disconnected', self, '_client_disconnected')

func init(id : String, nickname : String) -> void:
	_id = id
	name = _id
	_nickname = nickname

master func change_drawing_time(index : int) -> void:
	if _clients.empty(): return
	var sender_id := get_tree().get_rpc_sender_id()
	if sender_id != _clients[0]: return

	_change_drawing_time(index)

func _change_drawing_time(index : int) -> void:
	if not is_network_master(): return

	_set_draw_sec_index(index)

	for id in _clients:
		rpc_id(id, '_set_draw_sec_index', index)

remotesync func _set_draw_sec_index(index : int) -> void:
	_draw_sec_index = index
	emit_signal('draw_sec_index_changed', index)

master func play_game() -> void:
	if _clients.empty(): return
	var sender_id := get_tree().get_rpc_sender_id()
	if _clients[0] != sender_id: return
	_add_game()

master func leave_room() -> void:
	var sender_id := get_tree().get_rpc_sender_id()
	if not sender_id in _clients: return
	
	Network.leave_room(sender_id, _id)

master func send_chat_message(message : String) -> void:
	var sender_id := get_tree().get_rpc_sender_id()
	if not sender_id in _clients: return

	for id in _clients:
		rpc_id(id, '_receive_message', sender_id, message)

puppet func _receive_message(from_id : int, message : String) -> void:
	emit_signal('received_message', from_id, message)

func remove_client(id : int) -> void:
	_clients.erase(id)
	emit_signal('client_left', id)

	if not _clients.empty(): return
	emit_signal('just_emptied', _id)

func _add_game() -> void:
	_add_game_node(_clients, _draw_sec_index)
	for client in _clients:
		rpc_id(client, '_add_game_node', _clients, _draw_sec_index)

	_game_instance.start_game()

remotesync func _add_game_node(clients : Array, draw_sec_index : float) -> void:
	if _game_instance: return
	var game := _game.instance() as Game
	game.init({ players = clients, draw_sec_index = draw_sec_index })
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
