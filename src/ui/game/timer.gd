extends Control

class_name TimeLeftControl

const FRAMES := 5

var _total_time := 10.0
var _time_left := 10.0

onready var _icon := $Icon
onready var _display := $Display

func clear() -> void:
	_display.text = ''
	_icon.frame = FRAMES - 1

func update_time(time_left : float, time_total : float) -> void:
	var time_left_percent := time_left / time_total
	_icon.frame = int((1.0 - time_left_percent) * FRAMES)
	_display.text = '%.1f' % time_left
