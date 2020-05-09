extends Node2D

class_name Game

const Phase_None := 0
const Phase_ChooseWord := 1
const Phase_Draw := 2
const Phase_Guess := 3
const Phase_End := 4
const Phase_ShowScribbleChain := 5

signal player_left(id)
signal phase_changed(old_phase, new_phase)
signal received_scribble_chain(player_id)

var _room_id := ''

var _disconnected := {}

var _players := []
var _scribble_chains := {}

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

	if is_network_master():
		connect('phase_changed', self, '_on_phase_changed')

	_phases = _build_phases()

func _on_phase_changed(old_phase : int, new_phase : int) -> void:
	if new_phase == Phase_ShowScribbleChain:
		_send_one_scribble_chain_in_parts()

func _send_one_scribble_chain_in_parts() -> void:
	var player_id := _players[_scribble_chains.size()] as int

	var parts := _interlace_guesses_and_drawings(player_id)

	for i in range(parts.size()):
		rpc_players('_add_scribble_chain_part', [parts[i], player_id, i >= parts.size() - 1])
		printt('in loop', parts[i])
	

remotesync func _add_scribble_chain_part(guess_or_drawing, player_id : int, is_end : bool) -> void:
	print('_add_scribble_chain_part')
	if not player_id in _scribble_chains:
		_scribble_chains[player_id] = []
	
	_scribble_chains[player_id].append(guess_or_drawing)

	if not is_end: return

	emit_signal('received_scribble_chain', player_id)
	
func _interlace_guesses_and_drawings(player_id : int) -> Array:
	if not player_id in _guesses: return []
	if not player_id in _drawings: return []

	var drawings_index := 0
	var guesses_index := 0
	var use_drawing := true

	var parts := []

	printt(_guesses, _drawings)
	for _i in range(_drawings[player_id].size() + _guesses[player_id].size()):
		use_drawing = not use_drawing

		if (not use_drawing && guesses_index < _guesses.size()) || drawings_index >= _drawings.size():
			parts.append(_guesses[guesses_index])
			guesses_index += 1
			continue

		if (use_drawing && drawings_index < _drawings.size()) || guesses_index >= _guesses.size():
			parts.append(_drawings[drawings_index])
			drawings_index += 1
			continue
	
	return parts

func _player_left(id : int) -> void:
	if not id in _players: return
	_disconnected[id] = true
	emit_signal('player_left', id)

func get_phase() -> int:
	if not _valid_phase(): Phase_None
	return _phases[_phase]

func rpc_players(method : String, args := []) -> void:
	if not is_network_master(): return
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

master func pick_word(from_id : int, index : int) -> void:
	if not _is_valid_request(from_id, Phase_ChooseWord): return
	if from_id in _words: return
	rpc_players('_set_word_choice', [from_id, _word_choices[from_id][index]])

	if _words.size() < _players.size(): return
	rpc_players('_init_guesses')

	if _players.size() % 2 != 0:
		rpc_players('_pass')

	rpc_players('_next_phase')

master func done_drawing(image_info : Dictionary) -> void:
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


master func done_guess(guess : String) -> void:
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

master func done_show_scribble_chain() -> void:
	var sender_id := get_tree().get_rpc_sender_id()
	if not _is_valid_request(sender_id, Phase_ShowScribbleChain): return

	_phase_done[sender_id] = true
	if not _players_done(): return

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

	for i in range(ids.size()):
		_holding_map[ids[i]] = vs[i]

remotesync func _on_done_drawing(image_info : Dictionary) -> void:
	var id := get_tree().get_network_unique_id()
	var holding_id := _holding_map[id] as int
	_drawings[holding_id].append(image_info)

func get_local_image() -> Dictionary:
	var holding_id := _holding_map[get_tree().get_network_unique_id()] as int
	if _drawings[holding_id].empty(): return {}

	var info := _drawings[holding_id][-1] as Dictionary
	return info

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
	_phase_done.clear()
	_phase += 1
	emit_signal('phase_changed', _phases[_phase - 1], _phases[_phase])

remotesync func _set_word_choices(word_choices : Dictionary) -> void:
	_word_choices = word_choices
	
func _build_phases() -> Array:
	var phases := []

	phases.push_back(Phase_None)
	phases.push_back(Phase_ChooseWord)

	for _i in range(int(_players.size() / 2.0)):
		phases.push_back(Phase_Draw)
		phases.push_back(Phase_Guess)
	
	for _i in range(_players.size()):
		phases.push_back(Phase_ShowScribbleChain)

	phases.push_back(Phase_End)

	return phases
