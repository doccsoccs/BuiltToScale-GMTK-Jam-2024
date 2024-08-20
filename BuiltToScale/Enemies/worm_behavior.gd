extends Node

@onready var enemy = $".."
@export var seek_mod : float = 1.0
@export var wander_time: float = 5.0
@export var wander_min_dist: float = 500.0
@export var wander_max_dist: float = 1000.0

@onready var anim_player = $"../AnimationPlayer"

var current_state : State = State.Chasing
enum State {
	Chasing,
	Wandering
}

func _ready():
	anim_player.play("move")

func _process(_delta):
	# Alive
	if enemy.alive:
		# Coal
		match enemy.player_ref.size:
			0:
				enemy.has_coal = true
				pass
			1,2,3,4:
				enemy.has_coal = false
				pass
		
		if enemy.health <= 0:
			enemy.init_die()
		else:
			anim_player.play("move")
	else:
		enemy.rotation = 0

func _physics_process(delta):
	match current_state:
		State.Chasing:
			enemy.seek(enemy.player_ref.position)
			enemy.rotation = (enemy.player_ref.position - enemy.position).normalized().angle()
			if enemy.player_ref.size > 0:
				current_state = State.Wandering
		State.Wandering:
			enemy.wander(wander_min_dist, wander_max_dist, delta)
			enemy.rotation = enemy.velocity.normalized().angle()
			if enemy.player_ref.size == 0:
				current_state = State.Chasing
