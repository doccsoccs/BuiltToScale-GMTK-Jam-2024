extends CanvasLayer

@onready var MUSIC_BUS_ID = AudioServer.get_bus_index("Music")
@onready var SFX_BUS_ID = AudioServer.get_bus_index("SFX")
@onready var menu = $"."
@onready var music_slider = $Menu/MarginContainer/VBoxContainer/GridContainer/MusicSlider
@onready var sfx_slider = $Menu/MarginContainer/VBoxContainer/GridContainer/SFXSlider

func _ready():
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(1)) - 0.2
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(2)) - 0.2

func _input(event):
	if event.is_action_pressed("ESC"):
		toggle()

func toggle():
	menu.visible = !menu.visible

func _on_music_slider_value_changed(value):
	AudioServer.set_bus_volume_db(MUSIC_BUS_ID, linear_to_db(value))
	AudioServer.set_bus_mute(MUSIC_BUS_ID, value < 0.05)

func _on_sfx_slider_value_changed(value):
	AudioServer.set_bus_volume_db(SFX_BUS_ID, linear_to_db(value))
	AudioServer.set_bus_mute(SFX_BUS_ID, value < 0.05)
