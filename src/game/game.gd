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
signal phase_timeout
signal phase_timer_started

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

var _draw_round := 0
var _guess_round := 0

onready var _phase_timer := $PhaseTimer as Timer

var _draw_sec_index := Constants.DEFAULT_DRAW_SECOND_INDEX

func init(room_settings : Dictionary) -> void:
	for i in range(room_settings.players.size()):
		var id := room_settings.players[i] as int
		_players.push_back(id)

		_drawings[id] = []
		_guesses[id] = []

		_holding_map[id] = id
	
	_draw_sec_index = room_settings.get('draw_sec_index', -1)

func _ready():
	get_tree().connect('network_peer_disconnected', self, '_player_left')

	_phase_timer.connect('timeout', self, '_phase_timeout')
	connect('phase_changed', self, '_on_phase_changed')

	_phases = _build_phases()

func phase_timer_time_left() -> float:
	if _phase_timer.is_stopped(): return 0.0
	return _phase_timer.time_left

func phase_timer_time_wait() -> float:
	return _phase_timer.wait_time

func is_phase_timer_ticking() -> bool:
	return not _phase_timer.is_stopped()

func _phase_timeout() -> void:
	emit_signal('phase_timeout')

	if not is_network_master(): return

	if get_phase() == Phase_Draw:
		_finish_drawing_phase()
	
	if get_phase() == Phase_Guess:
		_finish_guessing_phase()
	
	if get_phase() == Phase_ChooseWord:
		_finish_pick_word_phase()
	
	rpc_players('_next_phase')

func _on_phase_changed(old_phase : int, new_phase : int) -> void:
	_phase_timer.stop()

	_phase_timer.wait_time = _get_wait_time(30)

	if new_phase == Phase_ChooseWord: _phase_timer.wait_time = _get_wait_time(10)
	if new_phase == Phase_Draw: _phase_timer.wait_time = _get_wait_time(Constants.get_draw_seconds(_draw_sec_index))
	if new_phase == Phase_Guess: _phase_timer.wait_time = _get_wait_time(30)

	var phases := int(_players.size() / 2.0)
	var show_scribble_time := Constants.ShowGuessSec * (phases + 1) + Constants.ShowGuessSec * phases
	if new_phase == Phase_ShowScribbleChain: _phase_timer.wait_time = _get_wait_time(show_scribble_time)
		
	_phase_timer.start()
	emit_signal('phase_timer_started')

	if not is_network_master(): return

	if new_phase == Phase_ShowScribbleChain:
		_send_one_scribble_chain_in_parts()

# The server waits an extra X seconds before switching phases...
# This gives the client time to send in their data before the phase ends
# It also ensures that the player feels like the timer and audio align perfectly
func _get_wait_time(sec : float) -> float:
	return sec if not is_network_master() else sec + 5

func _send_one_scribble_chain_in_parts() -> void:
	var player_id := _players[_scribble_chains.size()] as int
	print(player_id)

	var parts := _interlace_guesses_and_drawings(player_id)

	for i in range(parts.size()):
		rpc_players('_add_scribble_chain_part', [parts[i], player_id, i >= parts.size() - 1])

remotesync func _add_scribble_chain_part(guess_or_drawing, player_id : int, is_end : bool) -> void:
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

	for _i in range(_drawings[player_id].size() + _guesses[player_id].size()):
		use_drawing = not use_drawing

		if (not use_drawing && guesses_index < _guesses.size()) || drawings_index >= _drawings.size():
			parts.append(_guesses[player_id][guesses_index])
			guesses_index += 1
			continue

		if (use_drawing && drawings_index < _drawings.size()) || guesses_index >= _guesses.size():
			parts.append(_drawings[player_id][drawings_index])
			drawings_index += 1
			continue
	
	return parts

func _player_left(id : int) -> void:
	if not id in _players: return
	_disconnected[id] = true
	emit_signal('player_left', id)

func get_phase() -> int:
	if not _valid_phase(): return Phase_None
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
	if not is_network_master(): return

	if not _is_valid_request(from_id, Phase_ChooseWord): return
	if from_id in _words: return

	rpc_players('_set_word_choice', [from_id, _word_choices[from_id][index]])

	if _words.size() < _players.size(): return
	_finish_pick_word_phase()

	rpc_players('_next_phase')

func _finish_pick_word_phase() -> void:
	if not is_network_master(): return
		
	for id in _players:
		if id in _words: continue
		var forced_choice := _word_choices[id][0] as String
		rpc_players('_set_word_choice', [id, forced_choice])

	rpc_players('_init_guesses')

	if _players.size() % 2 != 0:
		rpc_players('_pass')

master func update_current_drawing(image_info : Dictionary) -> void:
	var sender_id := get_tree().get_rpc_sender_id()
	if not _is_valid_request(sender_id, Phase_Draw): return

	var holding_id := _holding_map[sender_id] as int
	if _drawings[holding_id].size() <= _draw_round:
		_drawings[holding_id].append(image_info)
	else:
		_drawings[holding_id][_draw_round] = image_info

func _finish_drawing_phase() -> void:
	if not is_network_master(): return

	rpc_players('_pass')
	
	for id in _players:
		var holding_id := _holding_map[id] as int

		if _drawings[holding_id].size() <= _draw_round:
			_drawings[holding_id].append({})

		rpc_id(id, '_on_done_drawing', _drawings[holding_id][-1])

master func done_guess(guess : String) -> void:
	var sender_id := get_tree().get_rpc_sender_id()
	if not _is_valid_request(sender_id, Phase_Guess): return
	
	var holding_id := _holding_map[sender_id] as int
	if _guesses[holding_id].size() <= _guess_round:
		_guesses[holding_id].append(guess)
	else:
		_guesses[holding_id][_guess_round] = guess

	if not _players_all_guessed(): return

	_finish_guessing_phase()

func _players_all_guessed() -> bool:
	for id in _players:
		var holding_id := _holding_map[id] as int
		if _guesses[holding_id].size() <= _guess_round:
			return false
	
	return true

func _finish_guessing_phase() -> void:
	if not is_network_master(): return

	rpc_players('_pass')

	for id in _players:
		var holding_id := _holding_map[id] as int

		if _guesses[holding_id].size() <= _guess_round:
			_guesses[holding_id].append('<missed the guess>')

		rpc_id(id, '_on_done_guessing', _guesses[holding_id][-1])
	
master func done_show_scribble_chain() -> void:
	var sender_id := get_tree().get_rpc_sender_id()
	if not _is_valid_request(sender_id, Phase_ShowScribbleChain): return

func _players_done() -> bool:
	return _phase_done.size() == _players.size()

remotesync func _init_guesses() -> void:
	for id in _words: _guesses[id].append(_words[id])
	_guess_round = 1

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
	if get_phase() == Phase_Guess:
		_guess_round += 1
	elif get_phase() == Phase_Draw:
		_draw_round += 1

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
