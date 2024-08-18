extends Node

@onready var enemy = $".."
@export var seek_mod : float = 1.0

@onready var anim_player = $"../AnimationPlayer"

func _ready():
	anim_player.play("floating")

func _process(_delta):
	if enemy.alive:
		if enemy.health <= 0:
			enemy.init_die()
			
		elif enemy.health < enemy.max_health:
			anim_player.play("floating_damaged")

func _physics_process(_delta):
	enemy.seek(enemy.player_ref.position)
