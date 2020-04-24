extends Node2D

const Phase_ChooseWord := 1
const Phase_Pass = 2
const Phase_Draw = 3
const Phase_Guess = 4
const Phase_End = 5
const Phase_ShowWord := 6

signal game_began

var _players := []
var _drawing_books := {}
var _words := {}

var _phases := []
var _phase := -1


remote func set_word(id_from : int, word : String) -> bool:
	if _phase == -1 || _phase >= _phases.size(): return false
	if _phases[_phase] != Phase_ChooseWord: return false
	_words[id_from] = word;
	return true

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
		passes += 2
	
	phases.push_back(Phase_End)

	return phases

func _test_phases() -> Array:
	var phases := [ Phase_ChooseWord, Phase_ShowWord ]
	return phases

func _ready():
	#_phases = _build_phases()
	_phases = _test_phases()
	emit_signal("game_began")
