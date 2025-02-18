extends Node2D

const GAME_SCENE_PATH = "res://scenes/main/Play.tscn"

func _ready():
	# Play BGM (make sure this AudioStreamPlayer is set to loop in the Inspector if desired)
	if $TitleScreenBGM and $TitleScreenBGM is AudioStreamPlayer:
		$TitleScreenBGM.play()

	# Connect the button's CUSTOM "start_pressed" signal, not the built-in pressed
	if $StartButton:
		$StartButton.start_pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed():
	# Stop BGM
	if $TitleScreenBGM and $TitleScreenBGM is AudioStreamPlayer:
		$TitleScreenBGM.stop()
	
	# Now change the scene
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


