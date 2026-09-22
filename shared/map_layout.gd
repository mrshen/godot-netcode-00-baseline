extends RefCounted
## Both roles construct collision geometry from this one definition.

const ARENA := Rect2(48, 132, 800, 552)
const SPAWN := Vector2(168, 404)
const WALL_THICKNESS := 24.0
const OBSTACLES: Array[Rect2] = [
	Rect2(352, 232, 64, 256),
	Rect2(528, 460, 192, 48),
	Rect2(592, 200, 96, 96),
]

static func collision_rects() -> Array[Rect2]:
	var p := ARENA.position
	var s := ARENA.size
	var t := WALL_THICKNESS
	var rects: Array[Rect2] = [
		Rect2(p - Vector2(t, t), Vector2(s.x + 2 * t, t)),
		Rect2(Vector2(p.x - t, p.y + s.y), Vector2(s.x + 2 * t, t)),
		Rect2(p - Vector2(t, 0), Vector2(t, s.y)),
		Rect2(Vector2(p.x + s.x, p.y), Vector2(t, s.y)),
	]
	rects.append_array(OBSTACLES)
	return rects
