extends CharacterBody2D
class_name Player

const base_size : int = 2
var size : int
const coal_size_increase : int = 4
var coal : int = 0

var size_change_completed : bool = true
const scale_rate_array : Array[Vector2] = [Vector2(0.02, 0.02), Vector2(0.05, 0.05), Vector2(0.09, 0.09), Vector2(0.1,0.1), Vector2(0.2, 0.2)]
const scale_vec_array : Array[Vector2] = [Vector2(0.5,0.5), Vector2(0.667,0.667), Vector2(1.0,1.0), Vector2(2,2), Vector2(4,4)]
var desired_scale : Vector2 = Vector2(1,1)

@export var speed : float = 680.0
@export var dash_speed : float = 1780.0
var dir : Vector2 = Vector2.ZERO
var action_dir : Vector2 = Vector2.ZERO
var dashing : bool = false
var can_dash : bool = true
const dash_time : float = 0.3
var dash_timer : float = 0.0
var dash_dir : Vector2 = Vector2.ZERO

var rebounding: bool = false
const base_rebound_speed: float = 1500
var rebound_speed: float = 0
var rebound_dir: Vector2 = Vector2.ZERO
const rebound_decay: float = 40.0

var facing_up : bool = false
var facing_down : bool = true
var facing_left : bool = false
var facing_right : bool = false

const kick_time : float = 0.5
var kick_timer : float = 0.0
var kicking : bool = false
var kick_completed : bool = false

const burn_radius : float = 100.0
var entities_in_radius : Array
var invulnerable : bool = false

# Animation
@onready var anim_player = $AnimationPlayer
@onready var burn_anim = $BurnSpriteAnimPlayer
@onready var kick_anim =  $ExplosionAnimPlayer
@onready var invuln_anim = $InvulnAnimPlayer
@onready var sprite = $SpriteComponent

# MISC Preloads
@onready var camera = $CameraComponent
@onready var kick_component = $Kick
@onready var kick_hitbox = $Kick/KickHitbox
@onready var burn_collision_component = $BurnRadius/BurnRadiusHitbox/BurnCollision

func _ready():
	size = base_size
	rebound_speed = base_rebound_speed
	anim_player.play("idlefacingdown")
	burn_anim.play("burnradius")
	kick_hitbox.monitoring = false
	burn_collision_component.shape.radius = burn_radius

func _process(delta):
	## TESTING
	if Input.is_action_just_pressed("TestShrink"):
		set_coal(coal - 1)
	elif Input.is_action_just_pressed("TestGrow"):
		set_coal(coal + 1)
	
	if coal == 0 and size == 0:
		get_tree().quit()
	
	if invulnerable:
		invuln_anim.play("invulnframes")
	
	# Kick Timer
	if kicking:
		kick_timer += delta
		if kick_timer >= kick_time:
			kick_completed = true
	
	# Rebound Timer
	if rebounding:
		if rebound_speed - rebound_decay > 0:
			rebound_speed -= rebound_decay
		else:
			rebounding = false
			rebound_speed = base_rebound_speed
	
	# Dash Timer
	if dashing:
		dash_timer += delta
		anim_player.play("dash")
		if dash_timer >= dash_time:
			dash_timer = 0.0
			dashing = false
			dash_dir = Vector2.ZERO
	
	if !size_change_completed:
		scaling()
	
	# Ends a hanging kick
	if kick_completed:
		end_kick()
	
	# Destroy any entities in the burn radius that are or become of a destructable size
	var i_count : int = 0
	var remove_list : Array[int] = []
	for e in entities_in_radius:
		if e is IceWall:
			if e.size <= size - 3 or e.size == 0 and size == 2:
				e.melt_anim()
				remove_list.append(i_count)
		
		elif e is Enemy:
			if e.size <= size - 2:
				e.melt_anim()
				remove_list.append(i_count)
		
		i_count += 1
	
	# Remove tagged entities
	for i in remove_list.size():
		entities_in_radius[remove_list[i]] = null

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
	var walking : bool = false
	if Input.is_action_pressed("Up") and facing_up:
		dir += Vector2(0,-1)
		walking = true
	if Input.is_action_pressed("Down") and facing_down:
		dir += Vector2(0,1)
		walking = true
	if Input.is_action_pressed("Left") and facing_left:
		dir += Vector2(-1,0)
		walking = true
	if Input.is_action_pressed("Right") and facing_right:
		dir += Vector2(1,0)
		walking = true
	
	# Revoke priority when key is released
	if Input.is_action_just_released("Up"):
		facing_up = false
		if Input.is_action_pressed("Down"):
			facing_down = true
	elif Input.is_action_just_released("Down"):
		facing_down = false
		if Input.is_action_pressed("Up"):
			facing_up = true
	if Input.is_action_just_released("Left"):
		facing_left = false
		if Input.is_action_pressed("Right"):
			facing_right = true
	elif Input.is_action_just_released("Right"):
		facing_right = false
		if Input.is_action_pressed("Left"):
			facing_left = true
	
	# Animation Logic
	if walking and !dashing:
		if facing_down or action_dir.y > 0:
			anim_player.play("walkfacingdown")
		elif facing_up or action_dir.y < 0:
			anim_player.play("walkfacingup")
		else:
			anim_player.play("walkfacingdown")
	elif !dashing:
		if facing_down or action_dir.y > 0:
			anim_player.play("idlefacingdown")
		elif facing_up or action_dir.y < 0:
			anim_player.play("idlefacingup")
		else:
			anim_player.play("idlefacingdown")
	
	# Dash Controls
	if Input.is_action_just_pressed("Dash") and !dashing and !rebounding and can_dash:
		dashing = true
		dash_dir = action_dir
		
		# Cancel Kick
		end_kick()
		kicking = false
		kick_anim.stop()
		$Kick/KickSprite.visible = false
	
	# Movement Logic
	if dashing:
		velocity = dash_dir.normalized() * dash_speed * delta
		sprite.rotation = dash_dir.angle()
	elif rebounding:
		velocity += rebound_dir * rebound_speed * delta
		rebound_speed -= rebound_decay
		sprite.rotation = 0.0
	else:
		velocity = dir.normalized() * speed * delta
		sprite.rotation = 0.0
	position += velocity
	
	# Save Direction
	if dir != Vector2.ZERO:
		action_dir = dir
	
	# Kicking
	if !kicking:
		kick_component.rotation = action_dir.angle()
	if Input.is_action_just_pressed("Kick") and !kicking and !rebounding:
		kick()
		
		# Cancel Dash
		dashing = false
		dash_timer = 0.0
		dashing = false
		dash_dir = Vector2.ZERO
	
	# Reset Move Variables
	dir = Vector2.ZERO
	velocity = Vector2.ZERO
	
	move_and_slide()

# Initiates the Kick Ability of the Player
func kick():
	kick_hitbox.monitoring = true
	kicking = true
	kick_completed = false
	kick_anim.play("kick")

func end_kick():
	kick_hitbox.monitoring = false
	kicking = false
	kick_timer = 0.0
	#kick_anim.stop()
	#$Kick/KickSprite.visible = false

# Sets the player's variables responsible for changing size display and determining behavior
func set_size_to(new_size : int):
	if new_size <= 4 and new_size >= 0:
		desired_scale = scale_vec_array[new_size]
		size = new_size
		size_change_completed = false

func set_coal(new_coal : int):
	if new_coal > coal or !invulnerable:
		if new_coal >= 0 and new_coal <= 4:
			coal = new_coal
			camera.display_coal(coal)
			if coal == coal_size_increase: # Growth Clause
				set_size_to(size + 1)
				if size != 4:
					coal = 0
		
		elif new_coal > coal_size_increase and size != 4: # Overflow clause
			set_size_to(size + 1)
			coal = 0
			camera.display_coal(coal)
		
		# Shrink Clause
		elif new_coal < 0:
			coal = coal_size_increase
			camera.display_coal(coal)
			set_size_to(size - 1)

# Scaling Logic, called every frame when needed
func scaling():
	if scale != desired_scale:
		if desired_scale > scale: # GROWING
			if scale + scale_rate_array[size] < desired_scale:
				scale += scale_rate_array[size]
			elif scale + scale_rate_array[size] >= desired_scale:
				scale = desired_scale
				size_change_completed = true
		elif desired_scale < scale: # SHRINKING
			if scale - scale_rate_array[size] > desired_scale:
				scale -= scale_rate_array[size]
			elif scale - scale_rate_array[size] <= desired_scale:
				scale = desired_scale
				size_change_completed = true

func set_invuln(invuln : bool):
	invulnerable = invuln
func set_can_dash(permission : bool):
	can_dash = permission

# Kick Hitbox Detects a Collision
func _on_kick_hitbox_body_entered(body):
	if body is IceWall:
		#if !body.sliding: # don't kick if already in motion
		body.kicked_by_player((action_dir + (body.position - position).normalized()).normalized(), size)
		kick_completed = true
		
		# Camera Shake
		match size:
			3,4: # Large Size
				if body.size >= size:
					camera.apply_noise_shake()
				elif body.size < size:
					camera.apply_noise_shake(0.75)
			_: # Default Case
				if body.size > size:
					camera.apply_noise_shake()
				elif body.size == size:
					camera.apply_noise_shake(0.5)
				elif body.size < size:
					camera.apply_noise_shake(0.2)
		
		# rebound
		rebounding = true
		rebound_dir = -(action_dir + (body.position - position).normalized()).normalized()
	
	elif body is Enemy:
		#set_coal(coal - 1)
		body.health -= 1
		body.knockbacking = true
		body.hit_dir = action_dir
		body.knockback_speed = body.base_knockback_speed/1.25
		kick_completed = true
		
		# rebound
		rebounding = true
		rebound_dir = -(action_dir + (body.position - position).normalized()).normalized()

# Called whenever the burn radius detects a collision
# Adds a body to the list of bodies in the radius
func _on_burn_radius_hitbox_body_entered(body):
	if body is IceWall:
		if body.size <= size - 3 or body.size == 0 and size == 2:
			body.melt_anim()
		else:
			entities_in_radius.append(body)
	
	elif body is Enemy:
		if body.size <= size - 2:
			body.melt_anim()
		else:
			entities_in_radius.append(body)

# Called whenever a body leaves the burn radius
# Removes a body from the list of bodies in the radius
func _on_burn_radius_hitbox_body_exited(body):
	if body is IceWall or body is Enemy:
		if entities_in_radius.find(body) > -1:
			entities_in_radius.remove_at(entities_in_radius.find(body))

# Called when the player collides with a piece of coal
func _on_item_pickup_area_body_entered(body):
	if body is Coal:
		set_coal(coal + 1)
		body.destroy()
