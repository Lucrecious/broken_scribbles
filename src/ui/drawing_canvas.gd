extends TextureRect

class_name DrawingCanvas

signal canvas_changed

const ImageInfoTemplate := {
	bytes = PoolByteArray(),
	format = int(),
	uncompressed_size = int(),
	size = Vector2(),
}

export(float, 1, 1000, .1) var pixel_scale_factor := 2.5

var _brush_blit := Image.new()
var _brush_cursor_icon := ImageTexture.new()

var _brush_color := Color.black

onready var _size := Vector2()
onready var _unit_size := Vector2()
var drawable := true

func set_cursor_as_brush() -> void:
	Input.set_custom_mouse_cursor(_brush_cursor_icon)

func set_image_from(image : Image) -> void:
	if not image: return
	clear()
	texture.set_data(image)

func set_image(info : Dictionary) -> bool:
	clear()
	var image := get_image_from(info)
	if not image: return false
		
	texture.set_data(image)
	return true

func get_image_from(info : Dictionary) -> Image:
	if not is_valid_image_info(info): return null

	var size := info.size as Vector2
	var uncompressed_size := info.uncompressed_size as int
	var format := info.format as int
	var bytes := (info.bytes as PoolByteArray).decompress(uncompressed_size, File.COMPRESSION_FASTLZ)

	var image := Image.new()
	image.create_from_data(int(size.x), int(size.y), false, format, bytes)

	return image

static func is_valid_image_info(info : Dictionary) -> bool:
	for key in ImageInfoTemplate:
		if not key in info: return false
		if info[key] is ImageInfoTemplate[key].type: return false
	
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
	
	var size := _brush_blit.get_size()
	
	_brush_blit.lock()
	for x in range(size.x): for y in range(size.y):
		var col := _brush_blit.get_pixel(x, y)
		col = Color(color.r, color.g, color.b, col.a)
		_brush_blit.set_pixel(x, y, col)
	
	_brush_blit.unlock()
	
	var tex_image := _brush_cursor_icon.get_data()
	tex_image.lock()
	for x in range(tex_image.get_width()):
		for y in range(tex_image.get_height()):
			var col := tex_image.get_pixel(x, y)
			col = Color(color.r, color.g, color.b, col.a)
			tex_image.set_pixel(x, y, col)
	
	tex_image.unlock()
	_brush_cursor_icon.set_data(tex_image)

func _add_colors(front : Color, back : Color) -> Color:
	var A := front.a
	return Color(
		front.r * A + back.r * (1 - A),
		front.b * A + back.b * (1 - A),
		front.g * A + back.g * (1 - A),
		A
	)

var _is_brush_eraser := false
func set_brush_as_eraser() -> void:
	_is_brush_eraser = true

func set_brush_as_pencil() -> void:
	_is_brush_eraser = false

func set_brush(image : Image) -> void:
	var new := image.get_rect(image.get_used_rect())
	
	_brush_blit = image.get_rect(image.get_used_rect())
	_brush_blit.convert(texture.get_data().get_format())
	
	var size := new.get_size() * _unit_size
	new.resize(int(size.x), int(size.y), Image.INTERPOLATE_CUBIC)
	new.convert(texture.get_data().get_format())
	
	var tex := ImageTexture.new()
	tex.create_from_image(new)
	_brush_cursor_icon = tex

func _ready() -> void:
	_size.x = rect_size.x / pixel_scale_factor
	_size.y = rect_size.y / pixel_scale_factor
	
	_unit_size.x = pixel_scale_factor
	_unit_size.y = pixel_scale_factor
	
	var image = Image.new()
	image.create(_size.x, _size.y, false, Image.FORMAT_RGBA8)
	var tex := ImageTexture.new()
	tex.create_from_image(image, 0)
	texture = tex
	
	var brush := load('res://assets/brushes/chalk.png') as Image
	
	set_brush(brush)
	set_brush_color(Color.blue)

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
	
	var mask := _brush_blit
	var a := Image.new()
	a.create(
			int(mask.get_size().x), int(mask.get_size().y),
			false, mask.get_format())
	if _is_brush_eraser:
		a.fill(Color.transparent)
	else:
		a.fill(_brush_color)
		
	var use_rect := mask.get_used_rect()
	
	changed = true
	
	image.lock()
	
	for pos in drag:
		var p := pos as Vector2
		if not _has_point(p): continue
		if not _is_brush_eraser:
			image.blend_rect(mask, use_rect, pos)
			continue
		
		image.blit_rect_mask(a, mask, use_rect, pos)
	
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
