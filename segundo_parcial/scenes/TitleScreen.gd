extends Control

onready var audio_player = $Music
onready var button_play = $Main/Options/Button/Play
onready var button_exit = $Main/Options/Button/Exit

func _ready():
	button_play.connect("pressed", self, "on_play_button_pressed", [button_play.scene])
	button_exit.connect("pressed", self, "on_exit_button_pressed")
	
		
func on_play_button_pressed(scene):
	get_tree().change_scene(scene)

func on_exit_button_pressed():
	get_tree().quit()
	
	
			

