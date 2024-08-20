extends CharacterBody2D

@onready var left_arm = $LeftArm
@onready var right_arm = $RightArm
@onready var left_arm_origin = $LeftArmOrigin
var left_arm_sigils: Array[Sprite2D] = []
@onready var right_arm_origin = $RightArmOrigin
var right_arm_sigils: Array[Sprite2D] = []

func _ready():
	# Get the sigils of each arm
	for child in left_arm_origin.get_children():
		left_arm_sigils.append(child)
	for child in right_arm_origin.get_children():
		right_arm_sigils.append(child)

func _process(_delta):
	animate_arms()
	if left_arm.position.x > -100:
		left_arm.position.x = -100
	if right_arm.position.x < 100:
		right_arm.position.x = 100

func animate_arms():
	var left_pos: Vector2 = left_arm.position
	var left_origin: Vector2 = left_arm_origin.position
	var vec_to_arm: Vector2 = left_pos - left_origin
	var l_count: float = 1
	for sigil in left_arm_sigils:
		sigil.position = vec_to_arm * (l_count/6)
		l_count += 1
	
	var right_pos: Vector2 = right_arm.position
	var right_origin: Vector2 = right_arm_origin.position
	vec_to_arm = right_pos - right_origin
	var r_count: float = 1
	for sigil in right_arm_sigils:
		sigil.position = vec_to_arm * (r_count/6)
		r_count += 1
