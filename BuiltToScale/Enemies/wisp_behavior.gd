extends Node

@onready var enemy = $".."
@export var seek_mod : float = 1.0
@export var wander_time: float = 5.0
@export var wander_min_dist: float = 400.0
@export var wander_max_dist: float = 800.0
@export var line_of_sight: float = 600.0
var locked_on: bool = false

@onready var anim_player = $"../AnimationPlayer"

var current_state : State = State.Chasing
enum State {
	Chasing,
	Wandering
}

func _ready():
	current_state = State.Wandering
	anim_player.play("floating")

func _process(_delta):
	# Alive 
	if enemy.alive:
		# Coal
		match enemy.player_ref.size:
			0,1,2,3:
				enemy.has_coal = true
				pass
			4:
				enemy.has_coal = false
				pass
		
		if !locked_on:
			if enemy.player_ref.position.distance_to(enemy.position) < line_of_sight:
				locked_on = true
		
		if enemy.health <= 0:
			enemy.init_die()
			
		elif enemy.health < enemy.max_health:
			anim_player.play("floating_damaged")
			
		else:
			anim_player.play("floating")

func _physics_process(delta):
	match current_state:
		State.Chasing:
			enemy.seek(enemy.player_ref.position)
			if enemy.player_ref.size == 4 or enemy.player_ref.size == 0:
				current_state = State.Wandering
				locked_on = false
		State.Wandering:
			enemy.wander(wander_min_dist, wander_max_dist, delta)
			if enemy.player_ref.size < 4 and enemy.player_ref.size > 0 and locked_on:
				current_state = State.Chasing
