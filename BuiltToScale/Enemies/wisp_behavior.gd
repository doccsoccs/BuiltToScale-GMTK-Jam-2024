extends Node

@onready var enemy = $".."
@export var seek_mod : float = 1.0

func _physics_process(_delta):
	enemy.seek(enemy.player_ref.position)
