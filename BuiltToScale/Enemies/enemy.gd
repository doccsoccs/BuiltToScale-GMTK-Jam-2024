extends CharacterBody2D
class_name Enemy

@export var max_health : int = 3
var health : int
var prev_health : int
var alive : bool = true
@export var size : int = 2

var can_damage_player : bool = true
const damage_time : float = 1.0
var damage_timer : float = 0.0

var dir : Vector2 = Vector2.ZERO
@export var speed : float = 6.0
var hit_dir : Vector2 = Vector2.ZERO
@export var base_knockback_speed : float = 1280.0
var knockback_speed : float = 0.0
const knockback_slow : float = 20.0
var knockbacking : bool = false

var player_ref : CharacterBody2D
var steering_force : Vector2 = Vector2.ZERO
var directional_array : Array[Vector2]
var interest_array : Array[float]
var danger_array : Array[float]
var context_map : Array[float]
var raycast_array : Array
var desired_vel : Vector2 = Vector2.ZERO

# Animation
@onready var puddle_sprite = $PuddleSprite
@onready var puddle_anim = $PuddleAnimator
@onready var anim_player = $AnimationPlayer
@onready var death_particles = $DeathParticles
@onready var hit_particles = $HitParticles

@onready var sprite = $SpriteComponent
@onready var collision_component = $CollisionComponent
@onready var raycasts = $ContextMap

# Drops
@export var coal_scene : PackedScene

func _ready():
	player_ref = get_tree().get_first_node_in_group("Player")
	
	# Initialize Pathfinding Arrays
	raycast_array = raycasts.get_children()
	directional_array = [Vector2(1,0), Vector2(1,-1).normalized(), Vector2(0,-1), Vector2(-1,-1).normalized(),
						Vector2(-1,0), Vector2(-1,1).normalized(), Vector2(0,1), Vector2(1,1).normalized()]
	
	health = max_health
	prev_health = health
	knockback_speed = base_knockback_speed

func _process(delta):
	# Can Only Damage Player by colliding with them every X seconds
	if !can_damage_player:
		damage_timer += delta
		if damage_timer >= damage_time:
			can_damage_player = true
			damage_timer = 0.0
	
	# Hit Particles
	if health != prev_health:
		hit_particles.emitting = true
	prev_health = health

func _physics_process(delta):
	if alive:
		# Knockback Logic
		if knockbacking:
			knockback(delta)
		else:
			knockback_speed = base_knockback_speed
		
		# Steering
		if !knockbacking:
			steering_force = desired_vel - velocity
			velocity = velocity + (steering_force * delta)
			position += velocity * speed
		
		move_and_slide()
		check_collisions(delta)

func knockback(delta):
	velocity = hit_dir * knockback_speed * delta
	position += velocity
	
	# Decelleration
	if knockback_speed > 0 and knockback_speed - knockback_slow > 0:
		knockback_speed -= knockback_slow
	elif knockback_speed - knockback_slow <= 0:
		knockback_speed = 0
		knockbacking = false

func melt_anim():
	init_die()
	puddle_anim.play("puddle")

func init_die():
	health = 0
	alive = false
	death_particles.emitting = true
	anim_player.play("death")

func die():
	death_particles.emitting = false
	sprite.visible = false
	
	var coal = coal_scene.instantiate()
	add_child(coal)
	coal.z_index -= 1

## Steering Functions
func seek(target_pos : Vector2):
	var increase_danger_of_next : bool = false
	for i in 8:
		# initialize interest array
		interest_array.append(directional_array[i].dot((target_pos - position).normalized()))
		
		# get danger array
		if raycast_array[i].is_colliding():
			danger_array.append(5.0)
			if i - 1 >= 0:
				danger_array[i-1] += 3.0
			if i + 1 <= 7:
				increase_danger_of_next = true
			if i + 1 > 7:
				danger_array[0] += 3.0
		else:
			if increase_danger_of_next:
				danger_array.append(3.0)
			else:
				danger_array.append(0.0)
			increase_danger_of_next = false
		
		# calculate context map
		context_map.append(interest_array[i] - danger_array[i])
	
	# Get the index of the highest value in the context map
	var highest_val : float = context_map.max()
	var dir_index : int = context_map.find(highest_val)
	desired_vel = directional_array[dir_index]
	
	interest_array.clear()
	danger_array.clear()
	context_map.clear()

func check_collisions(delta):
	var collision : KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		var body = collision.get_collider()
		if body is Player and can_damage_player and !body.invulnerable:
			body.set_coal(body.coal - 1)
			body.set_invuln(true)
			can_damage_player = false
			body.rebounding = true
			body.rebound_dir = (body.position - position).normalized()
