extends CharacterBody2D

@export var speed : float = 680.0
var dir : Vector2 = Vector2.ZERO
var action_dir : Vector2 = Vector2.ZERO

var facing_up : bool = false
var facing_down : bool = true
var facing_left : bool = false
var facing_right : bool = false

const kick_time : float = 0.5
var kick_timer : float = 0.0
var kicking : bool = false
var kick_completed : bool = false

const burn_radius : float = 240.0

@onready var kick_component = $Kick
@onready var kick_hitbox = $Kick/KickHitbox
@onready var burn_collision_component = $BurnRadius/BurnRadiusHitbox/BurnCollision

func _ready():
	kick_hitbox.monitoring = false
	burn_collision_component.shape.radius = burn_radius

func _process(delta):
	# Kick Timer
	if kicking:
		kick_timer += delta
		if kick_timer >= kick_time:
			kick_completed = true
	
	# Ends a hanging kick
	if kick_completed:
		end_kick()

func _physics_process(delta):
	# Determine Priority Directions when a key is pressed
	if Input.is_action_just_pressed("Up"):
		facing_up = true
		facing_down = false
	elif Input.is_action_just_pressed("Down"):
		facing_up = false
		facing_down = true
	if Input.is_action_just_pressed("Left"):
		facing_left = true
		facing_right = false
	elif Input.is_action_just_pressed("Right"):
		facing_left = false
		facing_right = true
	
	# Get Move Inputs
	if Input.is_action_pressed("Up") and facing_up:
		dir += Vector2(0,-1)
	if Input.is_action_pressed("Down") and facing_down:
		dir += Vector2(0,1)
	if Input.is_action_pressed("Left") and facing_left:
		dir += Vector2(-1,0)
	if Input.is_action_pressed("Right") and facing_right:
		dir += Vector2(1,0)
	
	# Revoke priority when key is released
	if Input.is_action_just_released("Up"):
		facing_up = false
	elif Input.is_action_just_released("Down"):
		facing_down = false
	if Input.is_action_just_released("Left"):
		facing_left = false
	elif Input.is_action_just_released("Right"):
		facing_right = false
	
	# Movement Logic
	velocity = dir.normalized() * speed * delta
	position += velocity
	
	# Save Direction
	if dir != Vector2.ZERO:
		action_dir = dir
	
	# Kicking
	kick_component.rotation = action_dir.angle()
	if Input.is_action_just_pressed("Kick") and !kicking:
		kick()
	
	# Reset Move Variables
	dir = Vector2.ZERO
	velocity = Vector2.ZERO
	
	move_and_slide()

# Initiates the Kick Ability of the Player
func kick():
	kick_component.visible = true
	kick_hitbox.monitoring = true
	kicking = true
	kick_completed = false

func end_kick():
	kick_component.visible = false
	kick_hitbox.monitoring = false
	kicking = false
	kick_timer = 0.0

# Kick Hitbox Detects a Collision
func _on_kick_hitbox_body_entered(body):
	if body is IceWall:
		if !body.sliding: # don't kick if already in motion
			body.kicked_by_player(action_dir.normalized())
			kick_completed = true
