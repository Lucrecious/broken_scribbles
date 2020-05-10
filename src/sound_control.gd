extends Node

onready var _loop := $Loop as AudioStreamPlayer
onready var _drawing := $Drawing as AudioStreamPlayer
onready var _end_round := $EndRound as AudioStreamPlayer

onready var _fade_out_tween := $FadeOutTween as Tween

func _ready() -> void:
	_fade_out_tween.connect('tween_all_completed', self, '_end_round_play')
	_end_round.connect('finished', _loop, 'play')

func _end_round_play() -> void:
	_drawing.volume_db = 0
	_drawing.stop()
	_end_round.play()

func _input(event: InputEvent) -> void:
	if event.is_action('ui_up'):
		_loop.volume_db = -80
		_drawing.volume_db = -80
		_end_round.volume_db = -80

func on_drawing_just_started() -> void:
	_loop.stop()
	
	var end_time := 30
	var timer := get_tree().create_timer(end_time - .5)
	timer.connect('timeout', self, '_do_fade_out')
	_drawing.play()

func _do_fade_out() -> void:
	_fade_out_tween.remove_all()
	_fade_out_tween.interpolate_property(_drawing, 'volume_db', 0, -80, .5)
	_fade_out_tween.start()


