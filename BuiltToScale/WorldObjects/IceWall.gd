extends CharacterBody2D
class_name IceWall

@export var size : int = 3
const scales_array : Array[Vector2] = [Vector2(0.125, 0.125), Vector2(0.25,0.25), \
									   Vector2(0.5,0.5), Vector2(1,1), Vector2(2,2)]
var is_min_size : bool = false
var alive : bool = true

var sliding : bool = false
var kicked : bool = false

var dir : Vector2 = Vector2.ZERO
const base_speed : float = 1600.0
var speed : float = 0.0
const friction : float = 15.0

const melt_time : float = 1.0
var melt_timer : float = 0.0
var melting : bool = false
var melt_speed : float = 0.02

@onready var collision_component = $CollisionComponent
@onready var sliding_hitbox = $ProjectileModeHitbox
@onready var melt_particles = $MeltParticles
@onready var shatter_particles = $IceShards
@onready var melt_sprite = $PuddleSprite
@onready var ice_sprite = $SpriteComponent
@onready var anim_player = $AnimationPlayer

func _ready():
	scale = scales_array[size]

func _physics_process(delta):
	if alive:
		if sliding:
			slide(delta)
			sliding_hitbox.monitoring = true
			if kicked:
				melt_particles.emitting = true
		else:
			sliding_hitbox.monitoring = false
		
		if melting:
			melt()
		
		collision_checks(delta)
		
		# Reset Movement Variables
		velocity = Vector2.ZERO
	
	# Death Clause
	elif !shatter_particles.emitting:
		#destroy()
		pass

# Called when player kick area2d detects ice wall
func kicked_by_player(kicked_direction : Vector2, player_size : int):
	if player_size <= 2:
		if player_size == size or player_size == size - 1 or player_size == size + 1:
			speed = base_speed
			sliding = true
			kicked = true
			dir = kicked_direction
	
	elif player_size == 3:
		if size >= 1:
			speed = base_speed
			sliding = true
			kicked = true
			dir = kicked_direction
	
	elif player_size == 4:
		if size >= 2:
			speed = base_speed
			sliding = true
			kicked = true
			dir = kicked_direction
	
	else:
		alive = false
		melt_anim()

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
		
		if kicked:
			melting = true

# Melts the ice block
func melt():
	kicked = false
	if size == 0:
		melt_particles.emitting = false
		melt_anim()
	elif scale > scales_array[size - 1] and scale - Vector2(melt_speed, melt_speed) >= scales_array[size - 1]:
		scale.x -= melt_speed
		scale.y -= melt_speed
	elif scale - Vector2(melt_speed, melt_speed) <= scales_array[size - 1]:
		scale = scales_array[size - 1]
		melting = false
		set_size(size - 1)
		melt_particles.emitting = false
	else:
		melting = false
		set_size(size - 1)
		melt_particles.emitting = false

func melt_anim():
	ice_sprite.visible = false
	anim_player.play("puddle")

func set_size(new_size : int):
	if new_size >= 0 and new_size <= 4:
		size = new_size

func shatter():
	shatter_particles.emitting = true
	collision_component.disabled = true
	ice_sprite.visible = false
	alive = false

func destroy():
	queue_free()

func collision_checks(delta):
	# Collision Checks
	var collision : KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		var body = collision.get_collider()
		
		# Enemy Collisions
		if body is Enemy and sliding:
			
			# Damage based on sizes
			if body.size == size - 1:
				body.health -= 2
				speed /= 1.5
			elif body.size <= size - 2:
				body.init_die()
				speed /= 1.2
			else:
				body.health -= 1
				speed /= 1.75
			
			# FOR ALL ENEMIES
			body.hit_dir = dir
			body.knockbacking = true
			
		
		# Other Ice Block Collisions
		if body is IceWall:
			# Change speed based on size of colliding block
			# Same size, both bounce
			if body.size == size:
				dir = collision.get_normal() - (dir * -1)/2  # update direction (BOUNCE)
				speed /= 1.5
				# Slide collided block
				body.sliding = true
				body.dir = -dir
				body.speed = speed
			
			# 2 Sizes Smaller --> Destroy
			elif body.size <= size - 2:
				body.shatter()
			
			# 1 Size Smaller --> Bounce small fast, Bounce big back slow
			elif body.size == size - 1:
				dir = collision.get_normal() - (dir * -1)/2  # update direction (BOUNCE)
				
				# Slide collided block
				body.sliding = true
				body.dir = -dir
				body.speed = speed / 1.2
				speed /= 1.8
			
			else:
				dir = collision.get_normal() - (dir * -1)/2  # update direction (BOUNCE)
