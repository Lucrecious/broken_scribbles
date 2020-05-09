extends TextureRect

signal canvas_changed

export(int, 2, 1000) var pixel_length := 50

var _brush_stamp := Image.new()

var _brush_color := Color.black

onready var _brush := $Brush as TextureRect

onready var _size := Vector2()
onready var _unit_size := Vector2()

var drawable := true

func set_image(info : Dictionary) -> bool:
	var image := texture.get_data()

	if not info.get('size') is Vector2: return false
	if not info.get('uncompressed_size') is int: return false
	if not info.get('format') is int: return false
	if not info.get('bytes') is PoolByteArray: return false

	var size := info.size as Vector2
	var uncompressed_size := info.uncompressed_size as int
	var format := info.format as int
	var bytes := (info.bytes as PoolByteArray).decompress(uncompressed_size, File.COMPRESSION_FASTLZ)

	var other := Image.new()
	other.create_from_data(int(size.x), int(size.y), false, format, bytes)

	if other.get_size() != image.get_size(): return false
	image.lock()
	image.blit_rect(other, Rect2(Vector2(), image.get_size()), Vector2())
	image.unlock()
	texture.set_data(image)
	return true

func get_image_info() -> Dictionary:
	var image := texture.get_data() as Image
	
	image.lock()
	var image_info := {
		uncompressed_size = image.get_data().size(),
		bytes = image.get_data().compress(File.COMPRESSION_FASTLZ),
		size = image.get_size(),
		format = image.get_format()
	}
	image.unlock()

	return image_info

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

func set_brush(image : Image) -> void:
	_brush_stamp = image

func _ready() -> void:
	
	var aspect_ratio = rect_size.x / rect_size.y
	_size.x = pixel_length
	_size.y = pixel_length / aspect_ratio
	
	_unit_size.x = rect_size.x / _size.x
	_unit_size.y = rect_size.y / _size.y
	
	var image = Image.new()
	image.create(_size.x, _size.y, false, Image.FORMAT_RGBA8)
	var tex := ImageTexture.new()
	tex.create_from_image(image, 0)
	texture = tex
	
	_brush_stamp.copy_from(_brush.texture.get_data())
	_brush_stamp.convert(image.get_format())

var _clicked_on_image := false
func _gui_input(event: InputEvent) -> void:
	if not drawable: return
	if not Input.is_action_pressed('ui_draw'):
		_clicked_on_image = false
		return
	
	var mouse_position := get_local_mouse_position()
	mouse_position.x = int(mouse_position.x / _unit_size.x)
	mouse_position.y = int(mouse_position.y / _unit_size.y)
	if Input.is_action_just_pressed('ui_draw'):
		_clicked_on_image = _has_point(mouse_position)
	
	if not _clicked_on_image: return
	
	var mouse_delta := Vector2()
	if event is InputEventMouseMotion:
		mouse_delta = (event as InputEventMouseMotion).relative
		mouse_delta.x = int(mouse_delta.x / _unit_size.x)
		mouse_delta.y = int(mouse_delta.y / _unit_size.y)
	
	var changed := _add_pixels(mouse_position, mouse_delta)
	
	if not changed: return
	emit_signal('canvas_changed')
	update()

func _add_pixels(mouse_pos : Vector2, delta : Vector2) -> bool:
	var changed := false
	var delta_abs = delta.abs().dot(Vector2(1, 1)) + 1
	var drag := _get_line_points(mouse_pos - delta, mouse_pos, delta_abs * 20) 
	var image := texture.get_data()
	
	var offset := (_brush_stamp.get_size() / 2.0)
	
	image.lock()
	for pos in drag:
		var p := pos as Vector2
		if not _has_point(p): continue
		image.blend_rect(
			_brush_stamp,
			_brush_stamp.get_used_rect(),
			pos - offset)
		changed = true
	
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
