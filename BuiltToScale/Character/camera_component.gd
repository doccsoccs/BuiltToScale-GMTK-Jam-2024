extends Camera2D

@onready var empty_sprite : Texture2D = load("res://Sprites/coal_ui_empty.png")
@onready var filled_sprite : Texture2D = load("res://Sprites/coal_ui_filled.png")
@onready var canvas = $CanvasLayer
@onready var particle_canvas = $ParticleCanvas
var ui_array : Array[Sprite2D]

# Screen Shake
@export var noise_shake_speed: float = 30.0 # How quickly to move through the noise
@export var noise_sway_speed: float = 1.0
@export var noise_shake_strength: float = 60.0 # Noise returns values -1 to 1
@export var noise_sway_strength: float = 10.0 # Multiply the returned value by these strengths
@export var random_shake_strength: float = 20.0 # Starting range of possible noise offsets
@export var shake_decay_rate: float = 5.0 # Multiplier for lerping shake strength to 0

enum ShakeType {
	Random,
	Noise,
	Sway
}

@onready var noise = FastNoiseLite.new()

# Track location in the noise
var noise_i : float = 0.0
@onready var rand = RandomNumberGenerator.new()
var shake_type : int = ShakeType.Random
var shake_strength : float = 0.0

func _ready():
	for child in canvas.get_children():
		ui_array.append(child)
	
	# Noise Controls
	rand.randomize()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = rand.randi()
	noise.frequency = 2

func _process(delta):
	# Fade out screenshake
	shake_strength = lerp(shake_strength, 0.0, shake_decay_rate * delta)
	
	var shake_offset : Vector2
	
	match shake_type:
		ShakeType.Random:
			shake_offset = get_random_offset()
		ShakeType.Noise:
			shake_offset = get_noise_offset(delta, noise_shake_speed, shake_strength)
		ShakeType.Sway:
			shake_offset = get_noise_offset(delta, noise_sway_speed, noise_sway_strength)
	
	# Does the actual shaking
	offset = shake_offset

func display_coal(coal_count : int):
	var count : int = 1
	for child in canvas.get_children():
		if coal_count >= count and coal_count != 0:
			child.texture = filled_sprite
		else:
			child.texture = empty_sprite
		count += 1
	
	if coal_count == 4:
		for child in particle_canvas.get_children():
			child.emitting = true

func apply_random_shake(mod: float = 1.0) -> void:
	shake_strength = random_shake_strength * mod
	shake_type = ShakeType.Random

func apply_noise_shake(mod: float = 1.0) -> void:
	shake_strength = noise_shake_strength * mod
	shake_type = ShakeType.Noise

func apply_noise_sway() -> void:
	shake_type = ShakeType.Sway

func get_noise_offset(delta: float, speed: float, strength: float) -> Vector2:
	noise_i += delta * speed
	return Vector2(
		noise.get_noise_2d(1, noise_i) * strength,
		noise.get_noise_2d(100, noise_i) * strength
	)

func get_random_offset() -> Vector2:
	return Vector2(
		rand.randf_range(-shake_strength, shake_strength),
		rand.randf_range(-shake_strength, shake_strength)
	)
