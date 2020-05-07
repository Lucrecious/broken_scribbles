extends TextureRect

signal canvas_changed

var _brush_stamp := [
	Vector2(0, -1),
	Vector2(-1, 0),
	Vector2(0, 0),
	Vector2(1, 0),
	Vector2(0, 1)
]

var _brush_color := Color.red

onready var _size := rect_size

var drawable := true

func set_image(other : Image) -> bool:
	var image := texture.get_data()
	if other.get_size() != image.get_size(): return false
	image.lock()
	image.blit_rect(other, Rect2(Vector2(), image.get_size()), Vector2())
	image.unlock()
	texture.set_data(image)
	return true

func clear() -> void:
	var image := texture.get_data()
	image.lock()
	image.fill(Color.transparent)
	image.unlock()
	texture.set_data(image)

func set_brush_color(color : Color) -> void:
	_brush_color = color

func set_brush_as_eraser() -> void:
	_brush_color = Color.transparent

func set_brush_stamp(stamp : Array) -> void:
	_brush_stamp = stamp

func _ready() -> void:
	var image = Image.new()
	image.create(_size.x, _size.y, false, Image.FORMAT_RGBA8)
	var tex := ImageTexture.new()
	tex.create_from_image(image, 0)
	texture = tex

var _clicked_on_image := false
func _gui_input(event: InputEvent) -> void:
	if not drawable: return
	if not Input.is_action_pressed('ui_draw'):
		_clicked_on_image = false
		return
	
	var mouse_position := get_local_mouse_position()
	if Input.is_action_just_pressed('ui_draw'):
		_clicked_on_image = _has_point(mouse_position)
	
	if not _clicked_on_image: return
	
	var mouse_delta := Vector2()
	if event is InputEventMouseMotion:
		mouse_delta = (event as InputEventMouseMotion).relative
	
	var changed := _add_pixels(mouse_position, mouse_delta)
	
	if not changed: return
	emit_signal('canvas_changed')
	update()

func _add_pixel(image : Image, position : Vector2, color : Color) -> bool:
	var old_color := image.get_pixel(int(position.x), int(position.y))
	image.set_pixel(int(position.x), int(position.y), color)
	return old_color != color

func _add_pixels(mouse_pos : Vector2, delta : Vector2) -> bool:
	var changed := false
	var delta_abs = delta.abs().dot(Vector2(1, 1)) + 1
	var drag := _get_line_points(mouse_pos - delta, mouse_pos, delta_abs) 
	var image := texture.get_data()
	
	image.lock()
	for v in _brush_stamp: for pos in drag:
		var p := (pos + v) as Vector2
		if not _has_point(p): continue
		changed = _add_pixel(image, p, _brush_color) or changed
	
	image.unlock()
	
	texture.set_data(image)
	
	return changed

func _get_line_points(from : Vector2, to : Vector2, num_points : int) -> Array:
	num_points += 1
	
	var v = to - from
	var percent := 1.0 / num_points
	
	var points := []
	for i in range(0, num_points):
		var p := (from + (v * i * percent)) as Vector2
		p.x = int(p.x)
		p.y = int(p.y)
		points.append(p)
	
	return points
	
func _has_point(pos : Vector2) -> bool:
	var rect := Rect2(Vector2(), _size)
	return rect.has_point(pos)
