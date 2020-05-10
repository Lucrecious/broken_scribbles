extends Node

onready var _loop := $Loop as AudioStreamPlayer
onready var _drawing := $Drawing as AudioStreamPlayer
onready var _end_round := $EndRound as AudioStreamPlayer

onready var _fade_out_tween := $FadeOutTween as Tween

var _end_draw_time := Constants.get_draw_seconds(-1) as float

func set_end_draw_sec(end_draw_time : float) -> void:
	if end_draw_time <= 0: return
	_end_draw_time = end_draw_time

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
	
	var timer := get_tree().create_timer(_end_draw_time - .5)
	timer.connect('timeout', self, '_do_fade_out')
	_drawing.play()

func on_draw_sec_index_changed(new_sec : float) -> void:
	_end_draw_time = new_sec

func _do_fade_out() -> void:
	_fade_out_tween.remove_all()
	_fade_out_tween.interpolate_property(_drawing, 'volume_db', 0, -80, .5)
	_fade_out_tween.start()


