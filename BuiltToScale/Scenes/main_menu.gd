extends Node2D

@onready var anim_player = $AnimationPlayer
@onready var anim_player_2 = $AnimationPlayer2
@onready var options_ui = $OptionsUI

# Called when the node enters the scene tree for the first time.
func _ready():
	anim_player.play("walk")
	anim_player_2.play("walk")
	GlobalMusic.main_menu_music()

# Play the game
func _on_play_button_pressed():
	get_tree().change_scene_to_file.call_deferred("res://Scenes/main.tscn")

func _on_options_button_pressed():
	options_ui.toggle()
