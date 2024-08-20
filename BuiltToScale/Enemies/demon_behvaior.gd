extends Node

@onready var enemy = $".."
@export var wander_time: float = 5.0
@export var wander_min_dist: float = 700.0
@export var wander_max_dist: float = 1000.0

@onready var sword_node = $"../Sword"
@onready var sword_area = $"../Sword/SwordArea"
@onready var sword_collision = $"../Sword/SwordArea/SwordCollision"
const rotate_speed: float = 2
var clockwise: bool = true

@onready var anim_player = $"../AnimationPlayer"

var current_state : State = State.Chasing
enum State {
	Chasing,
	Wandering
}

func _ready():
	anim_player.play("floating")

func _process(delta):
	# Alive 
	if enemy.alive:
		sword_node.visible = true
		sword_area.monitoring = true
		
		# Coal
		match enemy.player_ref.size:
			0:
				enemy.has_coal = false
				pass
			1,2,3,4:
				enemy.has_coal = true
				pass
		
		if enemy.health <= 0:
			enemy.init_die()
		elif enemy.health < enemy.max_health:
			anim_player.play("damaged")
		else:
			anim_player.play("floating")
		
		
		# Rotate Sword
		if clockwise:
			sword_node.rotation += rotate_speed * delta
		else:
			sword_node.rotation -= rotate_speed * delta
		
	else:
		sword_node.visible = false
		sword_area.monitoring = false

func _physics_process(delta):
	match current_state:
		State.Chasing:
			enemy.seek(enemy.player_ref.position)
			if enemy.player_ref.size <= 2 and !(enemy.health < enemy.max_health):
				current_state = State.Wandering
		State.Wandering:
			enemy.wander(wander_min_dist, wander_max_dist, delta)
			if enemy.player_ref.size >= 3 or enemy.health < enemy.max_health:
				current_state = State.Chasing

func _on_sword_area_body_entered(body):
	if body is Player:
		if enemy.can_damage_player and !body.invulnerable:
			body.set_coal(body.coal - 1)
			body.set_invuln(true)
			enemy.can_damage_player = false
			body.rebounding = true
			body.rebound_dir = (body.position - enemy.position).normalized()
			clockwise = !clockwise
	
	elif body is IceWall or body is LavaBlock:
		if body.size < enemy.size:
			if body is IceWall:
				body.call_deferred("shatter")
			else:
				body.explode_anim()
			clockwise = !clockwise
		else:
			if body.size == 3:
				body.sliding = true
				body.dir = ((body.position - sword_collision.position).normalized() + (body.position - enemy.position).normalized()).normalized()
				body.speed = body.speed_size_array[enemy.size]/2
			clockwise = !clockwise
