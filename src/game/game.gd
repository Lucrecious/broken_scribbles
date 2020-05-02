extends Node2D

const Phase_ChooseWord := 1
const Phase_Pass := 2
const Phase_Draw := 3
const Phase_Guess := 4
const Phase_End := 5
const Phase_ShowWord := 6

signal game_began

remotesync var _leader : int

var _players := []
var _drawing_books := {}
var _words := {}

var _phases := []
var _phase := -1

onready var header := $Header

func init(id : int) -> void:
	_leader = id
	_players.push_back(id)
	connect('game_began', self, '_game_began')

func _ready():
	#_phases = _build_phases()
	_phases = _test_phases()
	emit_signal("game_began")

	if not get_tree().is_network_server(): return

	get_tree().connect('network_peer_disconnected', self, 'remove_player')

master func remove_player(id : int) -> void:
	rpc('_remove_player', id)
	if id != _leader: return
	rset('_leader', _players[0])

master func add_player(id : int) -> void:
	rpc('_add_player', id)

remotesync func _remove_player(id : int) -> void:
	_players.erase(id)
	
remotesync func _add_player(id : int) -> void:
	if id in _players: return
	_players.push_back(id)

func _picked_word(word : String) -> void:
	rpc('set_word', get_tree().get_network_unique_id(), word)

remotesync func set_word(id_from : int, word : String) -> bool:
	if not _valid_phase(): return false
	if _phases[_phase] != Phase_ChooseWord: return false
	_words[id_from] = word;
	rpc_id(id_from, '_set_header', word)
	return true

remote func _set_header(word : String) -> void:
	header.text = word

func _valid_phase():
	return _phase >= 0 && _phase < _phases.size()

func _game_began() -> void:
	_reset_game()
	_next_phase()

func _reset_game() -> void:
	_phase = -1

func _next_phase() -> void:
	_phase += 1

func _build_phases() -> Array:
	var phases := []

	var passes := 0
	phases.push_back(Phase_ChooseWord)
	if _players.size() % 2 != 0:
		phases.push_back(Phase_Pass)
		passes += 1

# warning-ignore:unused_variable
	for i in range(passes, _players.size()):
		phases.push_back(Phase_Draw)
		phases.push_back(Phase_Pass)
		phases.push_back(Phase_Guess)
		phases.push_back(Phase_Pass)
	
	phases.push_back(Phase_End)

	return phases

func _test_phases() -> Array:
	var phases := [ Phase_ChooseWord, Phase_ShowWord ]
	return phases
