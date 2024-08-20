extends Node

@onready var audio_stream_player = $AudioStreamPlayer
@onready var goblin_town = $GoblinTown

func main_menu_music():
	audio_stream_player.stop()
	goblin_town.play()

func game_music():
	goblin_town.stop()
	audio_stream_player.play()
