extends CharacterBody2D
class_name Enemy

@export var max_health : int = 3
var health : int
var prev_health : int
var alive : bool = true
var can_revive: bool = false
@export var size : int = 2

const damaged_cooldown_time: float = 0.3
var damaged_cooldown_timer: float = 0.0
var can_be_damaged: bool = true
@onready var recovery_anim = $HitRecoverAnim

var can_damage_player : bool = true
const damage_time : float = 0.5
var damage_timer : float = 0.0
var has_coal: bool = true

var dir : Vector2 = Vector2.ZERO
@export var speed : float = 6.0
var hit_dir : Vector2 = Vector2.ZERO
@export var kbspeed_size_array : Array[float] = [320.0,1080.0,1280.0,1380.0,1480.0]
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
var wander_timer: float = 0.0
var wander_time: float = 5.0
var wander_target: Vector2 = Vector2.ZERO
var spawn_point: Vector2 = Vector2.ZERO
var rng = RandomNumberGenerator.new()
@export var min_wander_dist: float = 50.0

# Animation
@onready var puddle_sprite = $PuddleSprite
@onready var puddle_anim = $PuddleAnimator
@onready var anim_player = $AnimationPlayer
@onready var death_particles = $DeathParticles
@onready var hit_particles = $HitParticles

@onready var sprite = $SpriteComponent
@onready var collision_component = $CollisionComponent
@onready var damage_area = $DamageArea
@onready var raycasts = $ContextMap

# Audio
@onready var audio_damaged = $Damaged
@onready var audio_no_damage = $HitNoDamage
@onready var audio_melt = $Melt
@onready var audio_death = $Death

# Drops
@export var coal_scene : PackedScene

@export var boss: bool = false

func _ready():
	player_ref = get_tree().get_first_node_in_group("Player")
	
	# Initialize Pathfinding Arrays
	raycast_array = raycasts.get_children()
	directional_array = [Vector2(1,0), Vector2(1,-1).normalized(), Vector2(0,-1), Vector2(-1,-1).normalized(),
						Vector2(-1,0), Vector2(-1,1).normalized(), Vector2(0,1), Vector2(1,1).normalized()]
	
	health = max_health
	prev_health = health
	knockback_speed = kbspeed_size_array[player_ref.size]
	
	if !boss:
		spawn_point = get_parent().get_parent().spawn_pos

func _process(delta):
	# Can Only Damage Player by colliding with them every X seconds
	if !can_damage_player:
		damage_timer += delta
		if damage_timer >= damage_time:
			can_damage_player = true
			damage_timer = 0.0
	
	# Enemy Damaged Cooldown
	if !can_be_damaged:
		recovery_anim.play("hitrecover")
		damaged_cooldown_timer += delta
		if damaged_cooldown_timer >= damaged_cooldown_time:
			can_be_damaged = true
			damaged_cooldown_timer = 0.0
	
	# Hit Particles
	if health != prev_health:
		if health == 0:
			audio_death.play()
		else:
			audio_damaged.play()
		hit_particles.emitting = true
	prev_health = health

func _physics_process(delta):
	if alive:
		# Knockback Logic
		if knockbacking:
			knockback(delta)
		else:
			knockback_speed = kbspeed_size_array[player_ref.size]
		
		# Steering
		if !knockbacking:
			steering_force = desired_vel - velocity
			velocity = velocity + (steering_force * delta)
			position += velocity * speed
		
		move_and_slide()
		check_collisions(delta)

func toggle_contextmap():
	for ray in raycasts.get_children():
		ray.enabled = !ray.enabled

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
	if player_ref.size <= size + 2 or player_ref.size == 3:
		audio_melt.play()
	
	init_die()
	puddle_anim.play("puddle")

func init_die():
	if alive:
		health = 0
		prev_health = 0
		alive = false
		death_particles.emitting = true
		anim_player.play("death")

func die():
	death_particles.emitting = false
	sprite.visible = false
	puddle_sprite.visible = false
	toggle_contextmap()
	
	if has_coal:
		has_coal = false
		var coal = coal_scene.instantiate()
		coal.position = position
		get_tree().root.add_child(coal)
		coal.z_index -= 1
	
	can_revive = true

func revive(revive_pos: Vector2):
	if can_revive:
		can_revive = false
		alive = true
		health = max_health
		prev_health = health
		position = revive_pos
		velocity = Vector2.ZERO
		dir = Vector2.ZERO
		hit_dir = Vector2.ZERO
		steering_force = Vector2.ZERO
		knockback_speed = 0.0
		knockbacking = false
		can_be_damaged = true
		sprite.visible = true
		collision_component.disabled = false
		damage_area.monitoring = true
		toggle_contextmap()

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

func wander(seek_dist_min: float, seek_dist_max: float, delta: float):
	wander_timer += delta
	if wander_timer >= wander_time or position.distance_to(wander_target) <= min_wander_dist \
	or wander_target == Vector2.ZERO or wander_time == 5.0: # get new wander target
		wander_timer = 0.0
		wander_time = rng.randf_range(1.0, 4.99)
		wander_target = spawn_point + (rng.randi_range(-1,1) * Vector2(
			rng.randf_range(seek_dist_min, seek_dist_max), 
			rng.randf_range(seek_dist_min, seek_dist_max)
		))
	seek(wander_target)

func check_collisions(delta):
	var collision : KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		var body = collision.get_collider()
		if body is Enemy:
			body.knockbacking = true
			knockbacking = true
			body.hit_dir = (body.position - position).normalized()
			hit_dir = -(body.position - position).normalized()
			body.knockback_speed = body.knockback_speed/1.5
			
			if body.size >= size:
				knockback_speed = knockback_speed/1.5
			else:
				knockback_speed = knockback_speed/4
		
		# Destroy small ice blocks the enemy collides with
		if body is IceWall:
			if body.size <= size - 2:
				body.shatter()
		elif body is LavaBlock:
			if body.size <= size - 2:
				body.explode_anim()

func _on_damage_area_body_entered(body):
	if body is Player:
		if can_damage_player and !body.invulnerable:
			body.set_coal(body.coal - 1)
			body.set_invuln(true)
			can_damage_player = false
			body.rebounding = true
			body.rebound_dir = (body.position - position).normalized()
