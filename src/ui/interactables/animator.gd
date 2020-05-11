extends Control

export(Color) var hover_color := Color.red

export(Array, int) var skip_nexts := []

var _animated_sprite : AnimatedSprite

func _ready() -> void:
	for child in get_children():
		if not child is AnimatedSprite: continue
		_animated_sprite = child
		break

func _on_SwitchFrame_pressed() -> void:
	if not _animated_sprite: return
	var next_frame := (_animated_sprite.frame + 1) % _animated_sprite.frames.get_frame_count('default')
	_animated_sprite.frame = next_frame
	
	if not next_frame in skip_nexts: return
	
	var timer := get_tree().create_timer(.2)
	timer.connect('timeout', self, '_on_SwitchFrame_pressed')





