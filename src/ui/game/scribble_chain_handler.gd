extends Node

signal show_chain_part(part)

export(float) var sec_per_words := 10
export(float) var sec_per_picture := 10

var _scribble_chain := []

var _started := false
var _index_part := 0


onready var _word_timer := $ShowWordTimer as Timer
onready var _draw_timer := $ShowDrawingTimer as Timer

func start() -> void:
	if _started: return
	_started = true
	_index_part = -1
	
	_finished_show()

func stop() -> void:
	_word_timer.stop()
	_draw_timer.stop()

func set_chain(scribble_chain : Array) -> void:
	_started = false
	for e in scribble_chain:
		if not e is String && not e is Image: return
		_scribble_chain.append(e)

func total_time() -> float:
	if _scribble_chain.empty(): return 0.0
	
	var count := 0.0
	for e in _scribble_chain:
		if e is String: count += sec_per_words
		if e is Image: count += sec_per_picture
	
	return count
func _ready() -> void:
	_word_timer.connect('timeout', self, '_finished_show')
	_draw_timer.connect('timeout', self, '_finished_show')

func _finished_show() -> bool:
	_index_part += 1
	
	if not _signal_next_chain(_index_part): return false
	
	if _scribble_chain[_index_part] is Image:
		_draw_timer.start()
	else:
		_word_timer.start()
	
	return true


func _signal_next_chain(index : int) -> bool:
	if index >= _scribble_chain.size():
		emit_signal('show_chain_part', null)
		return false
	
	emit_signal('show_chain_part', _scribble_chain[index])
	return true



