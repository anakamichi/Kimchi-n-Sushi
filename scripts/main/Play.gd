extends Node2D


@onready var bgm_player = $BGM_Playing

func _ready():
	if bgm_player:
		bgm_player.stream.loop
		bgm_player.play() 


