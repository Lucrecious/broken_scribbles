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
var _drawings := {}
var _guesses := {}
var _words := {}

var _phase_done := {}

var _holding_map := {}

var _word_choices := {}

var _phases := []
var _phase := 0

func init(room_settings : Dictionary) -> void:
	for i in range(room_settings.players.size()):
		var id := room_settings.players[i] as int
		_players.push_back(id)

		_drawings[id] = []
		_guesses[id] = []

		_holding_map[id] = id

func _ready():
	get_tree().connect('network_peer_disconnected', self, '_player_left')
	#_phases = _build_phases()
	_phases = _test_phases()

func _player_left(id : int) -> void:
	if not id in _players: return
	_disconnected[id] = true
	emit_signal('player_left', id)

func get_phase() -> int:
	if not _valid_phase(): Phase_None
	return _phases[_phase]

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

func _is_valid_request(sender_id : int, valid_phase : int) -> bool:
	if not _valid_phase(): return false
	if _phases[_phase] != valid_phase: return false
	if not sender_id in _players: return false
	return true

mastersync func pick_word(from_id : int, index : int) -> void:
	if not _is_valid_request(from_id, Phase_ChooseWord): return
	if from_id in _words: return
	rpc_players('_set_word_choice', [from_id, _word_choices[from_id][index]])

	if _words.size() < _players.size(): return
	rpc_players('_init_guesses')
	rpc_players('_next_phase')

mastersync func done_drawing(image_info : Dictionary) -> void:
	var sender_id := get_tree().get_rpc_sender_id()
	if not _is_valid_request(sender_id, Phase_Draw): return

	var holding_id := _holding_map[sender_id] as int
	_drawings[holding_id].append(image_info)
	
	_phase_done[sender_id] = true
	if not _players_done(): return
	rpc_players('_pass')
	
	for id in _players:
		holding_id = _holding_map[id] as int
		rpc_id(id, '_on_done_drawing', _drawings[holding_id][-1])
	
	rpc_players('_next_phase')


mastersync func done_guess(guess : String) -> void:
	var sender_id := get_tree().get_rpc_sender_id()
	if not _is_valid_request(sender_id, Phase_Guess): return
	
	var holding_id := _holding_map[sender_id] as int
	_guesses[holding_id].append(guess)

	_phase_done[sender_id] = true
	if not _players_done(): return
	rpc_players('_pass')

	for id in _players:
		holding_id = _holding_map[id] as int
		rpc_id(id, '_on_done_guessing', _guesses[holding_id][-1])
	
	rpc_players('_next_phase')

func _players_done() -> bool:
	return _phase_done.size() == _players.size()

remotesync func _init_guesses() -> void:
	for id in _words: _guesses[id].append(_words[id])

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
# warning-ignore:integer_division
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

remotesync func _pass() -> void:
	if not _valid_phase(): return

	var ids := _holding_map.keys()
	var vs := []
	for id in ids:
		vs.append(_holding_map[id])
	
	var back := vs.pop_back() as int
	vs.push_front(back)

	_phase_done.clear()

	for i in range(ids.size()):
		_holding_map[ids[i]] = vs[i]

remotesync func _on_done_drawing(image_info : Dictionary) -> void:
	var id := get_tree().get_network_unique_id()
	var holding_id := _holding_map[id] as int
	_drawings[holding_id].append(image_info)

func get_local_image() -> Image:
	var image := Image.new()
	var holding_id := _holding_map[get_tree().get_network_unique_id()] as int
	if _drawings[holding_id].empty(): return image

	var info := _drawings[holding_id][-1] as Dictionary

	var size := info.size as Vector2
	var uncompressed_size := info.uncompressed_size as int
	var format := info.format as int
	var bytes := (info.bytes as PoolByteArray).decompress(uncompressed_size, File.COMPRESSION_FASTLZ)

	image.create_from_data(int(size.x), int(size.y), false, format, bytes)

	return image

remotesync func _on_done_guessing(guess : String) -> void:
	var id := get_tree().get_network_unique_id()
	var holding_id := _holding_map[id] as int
	_guesses[holding_id].append(guess)

func get_local_guess() -> String:
	var holding_id := _holding_map[get_tree().get_network_unique_id()] as int
	if _guesses[holding_id].empty(): return ''
	return _guesses[holding_id][-1]

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
	var phases := [ Phase_None, Phase_ChooseWord]
	for _i in range(5):
		phases += [Phase_Draw, Phase_Guess]
	
	phases += [Phase_End]
	return phases
