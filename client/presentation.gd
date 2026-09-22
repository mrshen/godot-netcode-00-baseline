extends Node2D
## Presentation reads the simulated world; it never moves collision bodies.

const Layout = preload("res://shared/map_layout.gd")
const INK := Color("e6edf6")
const MUTED := Color("8291a9")
const TEAL := Color("61edc4")
const BLUE := Color("78a7ff")
var world: Node2D
var elapsed := 0.0
var trail: Array[Vector2] = []
var trail_tick := -1

func _process(delta: float) -> void:
	elapsed += delta
	if world.tick < trail_tick:
		trail.clear()
	if world.tick != trail_tick:
		trail_tick = world.tick
		trail.append(world.player.position)
		if trail.size() > 90:
			trail.pop_front()
	queue_redraw()

func _draw() -> void:
	text_at("N / L", Vector2(48, 47), 22, TEAL)
	text_at("NETCODE LAB", Vector2(128, 45), 18, INK)
	text_at("A PLAYABLE GUIDE TO AUTHORITATIVE MULTIPLAYER", Vector2(128, 68), 11, MUTED)
	text_at("CHAPTER 00", Vector2(952, 44), 14, TEAL)
	text_at("SHARED WORLD", Vector2(952, 66), 12, MUTED)
	draw_line(Vector2(48, 91), Vector2(1132, 91), Color("243147"))
	text_at("01  /  SIMULATION SPACE", Vector2(48, 115), 12, MUTED)
	text_at("LOCAL SIMULATION", Vector2(704, 115), 11, TEAL)
	draw_arena()
	draw_player()
	draw_panel()
	text_at("W A S D  /  ARROWS", Vector2(48, 720), 13, INK)
	text_at("MOVE", Vector2(232, 720), 11, MUTED)
	text_at("R", Vector2(320, 720), 13, INK)
	text_at("RESET WORLD", Vector2(344, 720), 11, MUTED)
	text_at("Walk into a wall. The shared physics world decides where you stop.", Vector2(48, 743), 12, MUTED)

func draw_arena() -> void:
	draw_rect(Layout.ARENA, Color("0e1724"))
	for x in range(48, 849, 32):
		draw_line(Vector2(x, 132), Vector2(x, 684), Color("192536"))
	for y in range(132, 685, 32):
		draw_line(Vector2(48, y), Vector2(848, y), Color("192536"))
	draw_rect(Layout.ARENA, Color("34475f"), false, 2)
	for rect in Layout.OBSTACLES:
		draw_rect(Rect2(rect.position + Vector2(6, 6), rect.size), Color("080e18"))
		draw_rect(rect, Color("27394e"))
		draw_rect(rect, Color("4c6c8b"), false, 1)
		draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), BLUE, 2)
	text_at("STATIC / 01", Vector2(333, 514), 11, MUTED)
	text_at("STATIC / 02", Vector2(560, 534), 11, MUTED)
	text_at("STATIC / 03", Vector2(600, 320), 11, MUTED)
	draw_arc(Layout.SPAWN, 27, 0, TAU, 40, Color("31564f"), 1.0, true)
	text_at("SPAWN", Layout.SPAWN + Vector2(-20, 47), 10, MUTED)

func draw_player() -> void:
	for index in range(1, trail.size()):
		var alpha := float(index) / float(trail.size()) * 0.24
		draw_line(trail[index - 1], trail[index], Color(TEAL, alpha), 3.0, true)
	var p: Vector2 = world.player.position
	var facing: Vector2 = world.player.facing
	var color := Color("ffca80") if world.player.collided_this_tick else TEAL
	draw_circle(p + Vector2(0, 5), 17, Color(0, 0, 0, 0.3))
	draw_arc(p, 22 + sin(elapsed * 3) * 1.5, 0, TAU, 48, Color(color, 0.25), 1.5, true)
	draw_circle(p, 14, color)
	draw_line(p + facing * 5, p + facing * 12, Color("0c352d"), 3, true)
	text_at("P1", p + Vector2(-8, -33), 12, INK)

func draw_panel() -> void:
	var card := StyleBoxFlat.new()
	card.bg_color = Color("111c2b")
	card.border_color = Color("26374d")
	card.set_border_width_all(1)
	card.set_corner_radius_all(12)
	draw_style_box(card, Rect2(880, 132, 252, 552))
	text_at("THE BASELINE", Vector2(900, 167), 18, INK)
	text_at("One world. Two runtime roles.", Vector2(900, 192), 12, MUTED)
	draw_line(Vector2(900, 211), Vector2(1112, 211), Color("293950"))
	metric("RUNTIME", "CLIENT", 244, TEAL)
	metric("PHYSICS", "%d Hz" % Engine.physics_ticks_per_second, 291, INK)
	metric("RENDER", "%d FPS" % Engine.get_frames_per_second(), 338, INK)
	metric("SIMULATION TICK", str(world.tick), 385, INK)
	var p: Vector2 = world.player.position
	metric("POSITION", "%06.1f / %06.1f" % [p.x, p.y], 432, INK)
	var contact: bool = world.player.collided_this_tick
	metric("CONTACT", "BLOCKED / SLIDING" if contact else "FREE", 479, Color("ffca80") if contact else TEAL)
	draw_line(Vector2(900, 507), Vector2(1112, 507), Color("293950"))
	text_at("NETWORK   /   NOT CONNECTED", Vector2(900, 534), 11, MUTED)
	text_at("This chapter runs locally.", Vector2(900, 560), 12, INK)
	text_at("The server loads the same map", Vector2(900, 581), 11, MUTED)
	text_at("and movement rules, headless.", Vector2(900, 599), 11, MUTED)
	text_at("NEXT   01 / TCP CONNECTION", Vector2(900, 657), 11, BLUE)

func metric(label: String, value: String, y: float, color: Color) -> void:
	text_at(label, Vector2(900, y - 10), 10, MUTED)
	text_at(value, Vector2(900, y + 10), 17, color)

func text_at(value: String, point: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
