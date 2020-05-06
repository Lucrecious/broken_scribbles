extends Node2D

class_name Game

const Phase_None := 0
const Phase_ChooseWord := 1
const Phase_Pass := 2
const Phase_Draw := 3
const Phase_Guess := 4
const Phase_End := 5
const Phase_ShowWord := 6

signal player_left(id)
signal phase_changed(old_phase, new_phase)

var _room_id := ''

var _disconnected := {}
var _players := []
var _drawing_books := {}
var _words := {}

var _word_choices := {}

var _phases := []
var _phase := 0

func init(room_settings : Dictionary) -> void:
	for i in range(room_settings.players.size()):
		var id := room_settings.players[i] as int
		_players.push_back(id)

func _ready():
	get_tree().connect('network_peer_disconnected', self, '_player_left')
	#_phases = _build_phases()
	_phases = _test_phases()

func _player_left(id : int) -> void:
	if not id in _players: return
	_disconnected[id] = true
	emit_signal('player_left', id)

func rpc_players(method : String, args := []) -> void:
	if not is_network_master(): return
	if not get_tree().get_network_unique_id() in _players:
		callv(method, args)

	for id in _players:
		callv('rpc_id', [id, method] + args)

func local_word_choices() -> Array:
	return _word_choices.get(get_tree().get_network_unique_id(), ['default'])

master func start_game() -> void:
	rpc_players('_set_word_choices', [_get_word_choices()])
	rpc_players('_reset_game')
	rpc_players('_next_phase')

mastersync func pick_word(from_id : int, index : int) -> void:
	if not _valid_phase(): return
	if _phases[_phase] != Phase_ChooseWord: return
	if not from_id in _players: return
	if from_id in _words: return
	rpc_players('_set_word_choice', [from_id, _word_choices[from_id][index]])

	if _words.size() < _players.size(): return
	rpc_players('_next_phase')

remotesync func _set_word_choice(id : int, word : String) -> void:
	_words[id] = word

func _get_word_choices(words_per_player := 3) -> Dictionary:
	var choices := Constants.Words.duplicate().keys()
	var words := []

	var total_word_num := words_per_player * _players.size()

	# Only a safe guard if there not enough words
	while choices.size() < total_word_num:
		choices += choices
	
	# Try to never repeat words
	var step := choices.size() / total_word_num
	assert(step >= 1)

	for i in range(0, choices.size(), step):
		words.append(choices[min(i + randi() % step, choices.size() - 1)])
	
	words.shuffle()
	
	var word_choices := {}
	for id in _players:
		word_choices[id] = []
		for _i in range(words_per_player):
			word_choices[id].append(words.pop_back())

	return word_choices


func _valid_phase():
	return _phase >= 0 && _phase < _phases.size()

remotesync func _reset_game() -> void:
	_phase = 0

remotesync func _next_phase() -> void:
	_phase += 1
	emit_signal('phase_changed', _phases[_phase - 1], _phases[_phase])

remotesync func _set_word_choices(word_choices : Dictionary) -> void:
	_word_choices = word_choices
	
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
	var phases := [ Phase_None, Phase_ChooseWord, Phase_ShowWord ]
	return phases
