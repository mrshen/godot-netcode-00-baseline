extends RefCounted
## A short input recording checks observable movement and collision behavior.
## It is run through BOTH runtime entry points; it is not a network test.

const Layout = preload("res://shared/map_layout.gd")
const Player = preload("res://shared/player.gd")
const TOTAL_TICKS := 360
var failures: Array[String] = []
var samples: Array[Dictionary] = []
var idle_start := Vector2.ZERO

func command_for_tick(tick: int) -> Vector2:
	if tick < 60:
		return Vector2.RIGHT
	if tick < 120:
		return Vector2.UP
	if tick < 180:
		return Vector2(-1, -1)
	if tick < 240:
		return Vector2.LEFT
	if tick < 300:
		return Vector2.DOWN
	return Vector2.ZERO

func observe(world: Node2D, delta: float) -> void:
	var p: Vector2 = world.player.position
	check(absf(delta - 1.0 / 60.0) < 0.00001, "Physics step must remain 1/60 second")
	check(p.x >= Layout.ARENA.position.x + Player.RADIUS - 0.2, "Player crossed left boundary")
	check(p.y >= Layout.ARENA.position.y + Player.RADIUS - 0.2, "Player crossed top boundary")
	check(p.x <= Layout.ARENA.end.x - Player.RADIUS + 0.2, "Player crossed right boundary")
	check(p.y <= Layout.ARENA.end.y - Player.RADIUS + 0.2, "Player crossed bottom boundary")
	if world.tick == 60:
		check(absf(p.x - 338.0) < 0.3 and absf(p.y - 404.0) < 0.1, "Rightward movement must stop at the interior wall")
	if world.tick == 120:
		check(absf(p.y - 164.0) < 0.3, "Movement along the wall must cover 240 units in one second")
	if world.tick == 180:
		check(absf(p.x - (338.0 - 240.0 / sqrt(2.0))) < 0.4, "Diagonal input must be normalized")
		check(absf(p.y - 146.0) < 0.3, "Diagonal motion must stop at the top boundary")
	if world.tick == 240:
		check(absf(p.x - 62.0) < 0.3, "Leftward movement must stop at the arena boundary")
	if world.tick == 300:
		idle_start = p
	if world.tick == TOTAL_TICKS:
		check(p.distance_to(idle_start) < 0.01, "No input must leave the player stationary")
		check(world.player.velocity.is_zero_approx(), "Idle velocity must be zero")
	if world.tick % 60 == 0:
		var sample: Dictionary = world.player.snapshot()
		sample["tick"] = world.tick
		samples.append(sample)

func check(condition: bool, message: String) -> void:
	if not condition and message not in failures:
		failures.append(message)

func finish(role: String, report_path: String) -> bool:
	var result := {
		"role": role,
		"passed": failures.is_empty(),
		"physics_hz": Engine.physics_ticks_per_second,
		"total_ticks": TOTAL_TICKS,
		"samples": samples,
		"failures": failures,
	}
	if not report_path.is_empty():
		var file := FileAccess.open(report_path, FileAccess.WRITE)
		if file == null:
			push_error("Cannot write verification report: " + report_path)
			return false
		file.store_string(JSON.stringify(result, "\t") + "\n")
	for failure in failures:
		push_error(failure)
	print("VERIFY role=%s passed=%s ticks=%d samples=%d" % [role, failures.is_empty(), TOTAL_TICKS, samples.size()])
	return failures.is_empty()
