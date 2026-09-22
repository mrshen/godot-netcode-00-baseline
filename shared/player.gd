extends CharacterBody2D
## No keyboard, networking, or rendering here. Each role supplies its own input.

const SPEED := 240.0
const RADIUS := 14.0
const MAX_SLIDES := 4
var facing := Vector2.RIGHT
var collided_this_tick := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)

func simulate(command: Vector2, delta: float) -> void:
	var direction := command.limit_length(1.0)
	velocity = direction * SPEED
	if not direction.is_zero_approx():
		facing = direction.normalized()
	collided_this_tick = false
	var motion := velocity * delta
	for slide in range(MAX_SLIDES):
		if motion.is_zero_approx():
			break
		var collision := move_and_collide(motion, false, 0.05)
		if collision == null:
			break
		collided_this_tick = true
		motion = collision.get_remainder().slide(collision.get_normal())
		velocity = velocity.slide(collision.get_normal())

func snapshot() -> Dictionary:
	return {
		"position": [position.x, position.y],
		"velocity": [velocity.x, velocity.y],
	}
