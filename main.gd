extends Node

const World = preload("res://shared/world.gd")
const Presentation = preload("res://client/presentation.gd")
const Verification = preload("res://verification/scenario.gd")
var world: Node2D
var role := "client"
var tick_limit := 0
var verification: RefCounted
var report_path := ""
var verify_mode := false
var capture_path := ""
var capture_started := false

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--role="):
			role = argument.trim_prefix("--role=")
		elif argument.begins_with("--ticks="):
			tick_limit = argument.trim_prefix("--ticks=").to_int()
		elif argument == "--verify":
			verify_mode = true
		elif argument.begins_with("--report="):
			report_path = argument.trim_prefix("--report=")
		elif argument.begins_with("--capture="):
			capture_path = argument.trim_prefix("--capture=")
	if role not in ["client", "server"]:
		push_error("Unknown role: " + role)
		get_tree().quit(2)
		return
	if not capture_path.is_empty() and DisplayServer.get_name() == "headless":
		push_error("Screenshot capture requires a rendering display.")
		get_tree().quit(2)
		return
	world = World.new()
	world.name = "SharedWorld"
	add_child(world)
	if verify_mode:
		verification = Verification.new()
		tick_limit = Verification.TOTAL_TICKS
	if role == "client":
		configure_input()
		var presentation := Presentation.new()
		presentation.world = world
		add_child(presentation)
	print("BASELINE role=%s physics_hz=%d network=none" % [role, Engine.physics_ticks_per_second])

func _physics_process(delta: float) -> void:
	if world == null:
		return
	var command := Vector2.ZERO
	if verify_mode:
		command = verification.command_for_tick(world.tick)
	elif role == "client":
		command = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if Input.is_action_just_pressed("reset_world"):
			world.reset()
	world.step(command, delta)
	if verify_mode:
		verification.observe(world, delta)
	elif role == "server" and world.tick % 120 == 0:
		print("SERVER tick=%d position=%s (idle; networking begins in chapter 01)" % [world.tick, world.player.position])
	if not capture_path.is_empty() and world.tick >= 90 and not capture_started:
		capture_started = true
		capture_frame.call_deferred()
	if tick_limit > 0 and world.tick >= tick_limit:
		set_physics_process(false)
		if verify_mode:
			var passed: bool = verification.finish(role, report_path)
			get_tree().quit(0 if passed else 1)
		else:
			get_tree().quit(0)

func configure_input() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"reset_world": [KEY_R],
	}
	for action in bindings:
		InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func capture_frame() -> void:
	await RenderingServer.frame_post_draw
	var capture := get_viewport().get_texture().get_image()
	var error := capture.save_png(capture_path)
	if error != OK:
		push_error("Could not write screenshot: " + capture_path)
	get_tree().quit(0 if error == OK else 1)
