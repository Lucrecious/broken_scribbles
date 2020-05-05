extends Node2D

class_name Room

signal client_added(id)

# State
var _id := ''
var _nickname := ''
var _clients := []

func _ready() -> void:
	get_tree().connect('network_peer_disconnected', self, '_client_disconnected')

func init(id : String, nickname : String) -> void:
	_id = id
	name = _id
	_nickname = nickname

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
