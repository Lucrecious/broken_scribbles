extends HBoxContainer

func init(scribble_chain : Array) -> void:
	_create_scribble_chain(scribble_chain)

func _create_scribble_chain(scribble_chain : Array) -> void:
	for v in scribble_chain:
		if v is String:
			var label := Label.new()
			add_child(label)
			label.text = v
			continue
		if v is Image:
			var rect := TextureRect.new()
			add_child(rect)
			var texture := ImageTexture.new()
			v.resize(50, 50)
			texture.create_from_image(v)
			rect.texture = texture
			continue
