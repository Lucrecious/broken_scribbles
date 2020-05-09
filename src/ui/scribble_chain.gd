extends ItemList

func init(scribble_chain : Array) -> void:
	_create_scribble_chain(scribble_chain)

func _create_scribble_chain(scribble_chain : Array) -> void:
	for v in scribble_chain:
		if v is String:
			add_item(v)
			continue
		if v is Image:
			var texture := ImageTexture.new()
			texture.create_from_image(v)
			add_item('', texture)
			continue
