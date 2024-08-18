extends CharacterBody2D
class_name Coal

@onready var anim_player = $AnimationPlayer
@onready var burn_anim = $GlowAnimPlayer

func _ready():
	anim_player.play("coal")
	burn_anim.play("burnradius")

func destroy():
	queue_free()
