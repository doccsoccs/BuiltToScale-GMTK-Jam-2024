extends CharacterBody2D
class_name LavaBlock

var player: CharacterBody2D

@export var size : int = 3
const scales_array : Array[Vector2] = [Vector2(0.15, 0.15), Vector2(0.3,0.3), \
									   Vector2(0.5,0.5), Vector2(1,1), Vector2(1.5,1.5)]
var is_max_size : bool = false
var alive : bool = true

var sliding : bool = false
var kicked : bool = false

var dir : Vector2 = Vector2.ZERO
const speed_size_array : Array[float] = [800.0,1400.0,1600.0,1800.0,3200.0]
var speed : float = 0.0
const friction : float = 15.0

const grow_time : float = 1.0
var grow_timer : float = 0.0
var growing : bool = false
var grow_speed : float = 0.02

@onready var collision_component = $CollisionComponent
@onready var sliding_hitbox = $ProjectileModeHitbox
@onready var hit_particles = $HitParticles
@onready var sprite = $SpriteComponent
@onready var anim_player = $AnimationPlayer

# Audio
@onready var audio_hit = $Hit
@onready var audio_sliding = $Sliding
@onready var audio_explode = $Explode

func _ready():
	scale = scales_array[size]
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta):
	if alive:
		if sliding:
			anim_player.play("glowing")
			slide(delta)
			sliding_hitbox.monitoring = true
		else:
			sliding_hitbox.monitoring = false
		
		if growing:
			grow()
		
		collision_checks(delta)
		
		# Reset Movement Variables
		velocity = Vector2.ZERO

# Called when player kick area2d detects
func kicked_by_player(kicked_direction : Vector2, player_size : int):
	audio_hit.play()
	
	if player_size <= 2:
		if player_size >= size or player_size + 1 == size:
			audio_sliding.play()
			speed = speed_size_array[player.size]
			sliding = true
			kicked = true
			dir = kicked_direction
	
	elif player_size >= 3:
		audio_sliding.play()
		speed = speed_size_array[player.size]
		sliding = true
		kicked = true
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
		
		if kicked:
			growing = true

# grows the ice block
func grow():
	kicked = false
	if size == 4:
		hit_particles.emitting = false
		explode_anim()
	elif scale < scales_array[size + 1] and scale + Vector2(grow_speed, grow_speed) <= scales_array[size + 1]:
		scale.x += grow_speed
		scale.y += grow_speed
	elif scale + Vector2(grow_speed, grow_speed) <= scales_array[size + 1]:
		scale = scales_array[size + 1]
		growing = false
		set_size(size + 1)
		hit_particles.emitting = false
	else:
		growing = false
		set_size(size + 1)
		hit_particles.emitting = false

func explode_anim():
	audio_explode.play()
	anim_player.play("explode")

func set_size(new_size : int):
	if new_size >= 0 and new_size <= 4:
		size = new_size

func shatter():
	hit_particles.emitting = false
	collision_component.disabled = true
	sprite.visible = false
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
			if body.size == size or body.size - 1== size: # Same size OR 1 Size less --> 1 damage
				if body.can_be_damaged:
					body.health -= 1
					body.can_be_damaged = false
				
				if body.health <= 0:
					speed /= 1.75
				else:
					dir = collision.get_normal() - (dir * -1)/2
				
			elif body.size + 1 == size: # 1 Size Bigger --> 2 damage
				if body.can_be_damaged:
					body.health -= 2
					body.can_be_damaged = false
				
				if body.health <= 0:
					speed /= 1.5
				else:
					dir = collision.get_normal() - (dir * -1)/2
				
			elif body.size + 2 <= size: # 2 Sizes Bigger --> Instant Death
				body.init_die()
				speed /= 1.2
			else: # 2 Sizes Smaller
				dir = collision.get_normal() - (dir * -1)/2
			
			# FOR ALL ENEMIES
			body.hit_dir = dir
			body.knockbacking = true
		
		# Other Ice Block Collisions
		elif body is LavaBlock or body is IceWall:
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
				if body is LavaBlock:
					body.explode_anim()
				elif body is IceWall:
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
		
		elif body is TileMap:
			dir = collision.get_normal() - (dir * -1)/2
