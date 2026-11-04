class_name CoopWire
extends RefCounted

static func encode(value):
	if value is Vector2:
		return [snappedf(value.x, 0.1), snappedf(value.y, 0.1)]
	if value is Dictionary:
		var result := {}
		for key in value:
			result[str(key)] = encode(value[key])
		return result
	if value is Array or value is PackedVector2Array:
		var result: Array = []
		for item in value:
			result.append(encode(item))
		return result
	return value

static func vector(value) -> Vector2:
	return Vector2(float(value[0]), float(value[1])) if value is Array and value.size() == 2 else Vector2.ZERO

static func decode(value, key: String = ""):
	if value is Array and key in ["at", "position", "velocity", "origin", "direction", "charge_direction", "sprite_position", "ambush_at", "source", "end", "size", "ring_center"]:
		return vector(value)
	if value is Dictionary:
		var result := {}
		for name in value:
			result[name] = decode(value[name], name)
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(vector(item) if key in ["orbit_positions","points","blade_points"] else decode(item))
		return result
	return value
