extends CharacterBody2D
class_name IceWall

@export var size : int = 2

var sliding : bool = false

var dir : Vector2 = Vector2.ZERO
const base_speed : float = 1500.0
var speed : float = 0.0
const friction : float = 15.0

@onready var sliding_hitbox = $ProjectileModeHitbox

func _physics_process(delta):
	if sliding:
		slide(delta)
		sliding_hitbox.monitoring = true
	else:
		sliding_hitbox.monitoring = false
	
	# Reset Movement Variables
	velocity = Vector2.ZERO

# Called when player kick area2d detects ice wall
func kicked_by_player(kicked_direction : Vector2):
	speed = base_speed
	sliding = true
	dir = kicked_direction

# Movement for when kicked by a player
func slide(delta):
	velocity = dir.normalized() * speed * delta
	position += velocity
	 
	# Reduce Ice Wall Speed over time
	if speed > 0 and speed - friction >= 0:
		speed -= friction
	elif speed - friction < 0:
		speed = 0
		sliding = false
		dir = Vector2.ZERO

# Called when the Ice Wall Collides with a body while sliding
func _on_kicked_icewall_enter_body(body):
	if body is Enemy:
		body.health -= 1
		body.hit_dir = dir
		body.knockbacking = true
		speed /= 2
