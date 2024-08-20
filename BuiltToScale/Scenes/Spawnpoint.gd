extends Node2D

@export var spawn_type: PackedScene
@export var max_spawn_count: int = 5

@export var spawn_pos: Vector2
@export var spawn_radius: float = 100.0
var alive_enemies_count: int = 0
var valid: bool = true
var invalidator_count: int = 0

@onready var area = $Area2D
@onready var collision_component = $Area2D/CollisionShape2D
@onready var enemies = $Enemies
var player: CharacterBody2D
const acceptable_player_dist: float = 2500.0

func _ready():
	collision_component.shape.radius = spawn_radius
	area.position = spawn_pos
	initial_spawn()
	
	player = get_tree().get_first_node_in_group("Player")

func _process(_delta):
	if spawn_pos.distance_to(player.position) <= acceptable_player_dist:
		valid = false
	else:
		if invalidator_count > 0:
			valid = false
		else:
			valid = true
	
	if valid:
		spawn()

func get_spawn_pos() -> Vector2:
	return spawn_pos + ((Vector2(randf(), randf())).normalized() * randf_range(-spawn_radius, spawn_radius))

func initial_spawn():
	for i in max_spawn_count:
		var entity = spawn_type.instantiate()
		enemies.add_child(entity)
		entity.position = get_spawn_pos()

func spawn():
	for child in enemies.get_children():
		if !child.alive:
			child.revive(get_spawn_pos())

func _on_area_2d_body_entered(body):
	if !(body is Enemy):
		invalidator_count += 1
func _on_area_2d_body_exited(body):
	if !(body is Enemy) and invalidator_count - 1 >= 0:
		invalidator_count -= 1
