extends CharacterBody2D
class_name Enemy

@export var max_health : int = 2
var health : int
var alive : bool = true

var dir : Vector2 = Vector2.ZERO
@export var speed : float = 6.0
var hit_dir : Vector2 = Vector2.ZERO
@export var base_knockback_speed : float = 700.0
var knockback_speed : float = 0.0
const knockback_slow : float = 10.0
var knockbacking : bool = false

var player_ref : CharacterBody2D
var steering_force : Vector2 = Vector2.ZERO
var directional_array : Array[Vector2]
var interest_array : Array[float]
var danger_array : Array[float]
var context_map : Array[float]
var raycast_array : Array
var desired_vel : Vector2 = Vector2.ZERO

@onready var collision_component = $CollisionComponent
@onready var raycasts = $ContextMap

func _ready():
	player_ref = get_tree().get_first_node_in_group("Player")
	
	# Initialize Pathfinding Arrays
	raycast_array = raycasts.get_children()
	directional_array = [Vector2(1,0), Vector2(1,-1).normalized(), Vector2(0,-1), Vector2(-1,-1).normalized(),
						Vector2(-1,0), Vector2(-1,1).normalized(), Vector2(0,1), Vector2(1,1).normalized()]
	
	health = max_health
	knockback_speed = base_knockback_speed

func _process(_delta):
	if health <= 0:
		die()

func _physics_process(delta):
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

func knockback(delta):
	velocity = hit_dir * knockback_speed * delta
	position += velocity
	
	# Decelleration
	if knockback_speed > 0 and knockback_speed - knockback_slow > 0:
		knockback_speed -= knockback_slow
	elif knockback_speed - knockback_slow <= 0:
		knockback_speed = 0
		knockbacking = false

func die():
	alive = false
	visible = false
	collision_component.disabled = true

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
