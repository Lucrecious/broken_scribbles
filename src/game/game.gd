extends Node2D

class_name Game

const Phase_None := 0
const Phase_ChooseWord := 1
const Phase_Pass := 2
const Phase_Draw := 3
const Phase_Guess := 4
const Phase_End := 5
const Phase_ShowWord := 6

signal phase_changed(old_phase, new_phase)

var _room_id := ''

var _players := []
var _drawing_books := {}
var _words := {}

var _phases := []
var _phase := 0

func init(room_settings : Dictionary) -> void:
	for id in room_settings.players:
		_players.push_back(id)

func _ready():
	#_phases = _build_phases()
	_phases = _test_phases()

func local_word_choices() -> PoolStringArray:
	return 'choice1 choice2 choice3 choice4'.split(' ')

remotesync func start_game() -> void:
	_reset_game()
	_next_phase()

mastersync func pick_word(index : int) -> void:
	if not _valid_phase(): return
	if _phases[_phase] != Phase_ChooseWord: return
	prints(index, get_parent().get_child_count())

func _valid_phase():
	return _phase >= 0 && _phase < _phases.size()

func _reset_game() -> void:
	_phase = 0

func _next_phase() -> void:
	_phase += 1
	emit_signal('phase_changed', _phases[_phase - 1], _phases[_phase])
	
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
