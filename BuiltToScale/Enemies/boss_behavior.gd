extends Node

@onready var enemy = $".."
@onready var anim_player = $"../AnimationPlayer"
@export var wander_time: float = 5.0
@export var wander_min_dist: float = 100.0
@export var wander_max_dist: float = 300.0

var current_state : State = State.Aggro
enum State {
	Aggro,
	Wandering
}

func _process(_delta):
	# Alive 
	if enemy.alive:
		if enemy.health <= 0:
			enemy.init_die()

func _physics_process(delta):
	match current_state:
		State.Aggro:
			enemy.seek(enemy.player_ref.position)
			if enemy.player_ref.size < 4:
				current_state = State.Wandering
		State.Wandering:
			enemy.wander(wander_min_dist, wander_max_dist, delta)
			if enemy.player_ref.size == 4:
				current_state = State.Aggro
