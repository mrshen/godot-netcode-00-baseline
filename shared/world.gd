extends Node2D

const Layout = preload("res://shared/map_layout.gd")
const Player = preload("res://shared/player.gd")
var player: CharacterBody2D
var tick := 0

func _ready() -> void:
	for rect in Layout.collision_rects():
		var body := StaticBody2D.new()
		body.position = rect.get_center()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var collider := CollisionShape2D.new()
		collider.shape = shape
		body.add_child(collider)
		add_child(body)
	player = Player.new()
	player.name = "Player"
	player.position = Layout.SPAWN
	add_child(player)

func step(command: Vector2, delta: float) -> void:
	player.simulate(command, delta)
	tick += 1

func reset() -> void:
	player.position = Layout.SPAWN
	player.velocity = Vector2.ZERO
	player.facing = Vector2.RIGHT
	player.collided_this_tick = false
	tick = 0
