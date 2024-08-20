extends Node2D

@export var ice_block: PackedScene
@export var fire_block: PackedScene
@onready var anim_player = $AnimationPlayer
@onready var crush_area = $CrushArea

@export var ice: bool = true
@export var base_cooldown_time: float = 5.0
var cooldown_time: float = 5.0
var cooldown_timer: float = 0.0
@export var cooldown_range: float = 3.0
var offset: Vector2 = Vector2.ZERO
var offset_range: float = 300.0

@export var size: int = 3
var player: CharacterBody2D
const rumble_dist: float = 800.0

var rng = RandomNumberGenerator.new()

# Audio
@onready var audio_blockfall = $Blockfall

# Called when the node enters the scene tree for the first time.
func _ready():
	cooldown_time = base_cooldown_time + rng.randf_range(-cooldown_range, cooldown_range)
	player = get_tree().get_first_node_in_group("Player")
	crush_area.monitoring = false
	anim_player.play("fallingblock")

func _process(delta):
	# Block size scaling
	match size:
		0:
			scale = Vector2(0.15,0.15)
			pass
		1:
			scale = Vector2(0.3,0.3)
			pass
		2:
			scale = Vector2(0.5,0.5)
			pass
		3:
			scale = Vector2(1,1)
			pass
		4:
			scale = Vector2(1.5,1.5)
			pass
	
	cooldown_timer += delta
	if cooldown_timer >= cooldown_time:
		anim_player.play("fallingblock")

func drop():
	if ice:
		drop_ice()
	else:
		drop_fire()
	rumble()
	audio_blockfall.play()
	cooldown_timer = 0.0
	cooldown_time = base_cooldown_time + randf_range(-cooldown_range, cooldown_range)
	offset = Vector2(randf_range(-offset_range, offset_range), randf_range(-offset_range, offset_range))
	position += offset
	
	# Random
	if randi_range(0,1) == 0:
		ice = !ice
	
	if player.size > 0 and player.size < 4:
		size = randi_range(player.size - 1, player.size + 1)
	elif player.size == 0:
		size = randi_range(0,1)
	elif player.size == 4:
		size = randi_range(3,4)

func drop_ice():
	var block = ice_block.instantiate()
	block.size = size
	block.position = position
	get_tree().root.add_child(block)
	crush_area.monitoring = false

func drop_fire():
	var block = fire_block.instantiate()
	block.size = size
	block.position = position
	get_tree().root.add_child(block)
	crush_area.monitoring = false

func rumble():
	if player.position.distance_to(position) <= rumble_dist:
		if player.size == size:
			player.camera.apply_noise_shake(0.75)
		elif player.size > size:
			player.camera.apply_noise_shake(0.3)
		elif player.size < size:
			player.camera.apply_noise_shake()

# Instantly destroy any enemy or other block
# Damage Player and knock back
func _on_crush_area_body_entered(body):
	if body is Player:
		body.set_coal(body.coal - 1)
		body.set_invuln(true)
		body.rebounding = true
		body.rebound_dir = (body.position - position).normalized()
	
	elif body is Enemy:
		body.init_die()
		body.audio_death.play()
	
	elif body is IceWall:
		body.call_deferred("shatter")
	
	elif body is LavaBlock:
		body.explode_anim()
