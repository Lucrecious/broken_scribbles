extends Reference

class_name UUID

static func _random_int(max_value) -> int:
	randomize()
	return randi() % max_value

static func _random_bytes(n) -> Array:
	var r = []
	
	for _i in range(0, n):
		r.append(_random_int(256))
	
	return r

static func _uuidbin() -> Array:
	var b = _random_bytes(16)
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return b

static func v4() -> String:
	var b = _uuidbin()
	
	var low = '%02x%02x%02x%02x' % [b[0], b[1], b[2], b[3]]
	var mid = '%02x%02x' % [b[4], b[5]]
	var hi = '%02x%02x' % [b[6], b[7]]
	var clock = '%02x%02x' % [b[8], b[9]]
	var node = '%02x%02x%02x%02x%02x%02x' % [b[10], b[11], b[12], b[13], b[14], b[15]]
	
	return '%s-%s-%s-%s-%s' % [low, mid, hi, clock, node]





