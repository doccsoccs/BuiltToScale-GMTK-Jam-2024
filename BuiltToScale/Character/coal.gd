extends CharacterBody2D
class_name Coal

@onready var anim_player = $AnimationPlayer
@onready var burn_anim = $GlowAnimPlayer
@onready var destroy_particles = $DestroyParticles
@onready var collision_component = $CollisionComponent
@onready var sprite_component = $SpriteComponent

const coal_time: float = 5.0
var coal_timer: float = 0.0

const time: float = 1.0
var timer: float = 0.0
var destroyed: bool = false

@onready var audio_pickup = $CoalPickup

func _ready():
	anim_player.play("coal")
	burn_anim.play("burnradius")

func _process(delta):
	if !destroyed:
		coal_timer += delta
		if coal_timer >= coal_time:
			destroy()
	
	elif destroyed:
		collision_component.disabled = true
		timer += delta
		if timer >= time:
			queue_free()

func destroy():
	destroy_particles.emitting = true
	sprite_component.visible = false
	destroyed = true
