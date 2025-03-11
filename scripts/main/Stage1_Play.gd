extends Node2D


const NEXT_SCENE_PATH = "res://scenes/main/Stage2_Play.tscn"

@onready var bgm_player = $Stage_BGM

func _ready() -> void:

	$NextStageTrigger.body_entered.connect(_on_NextStageTrigger_body_entered)

	# BGM
	if bgm_player and bgm_player.stream:
		bgm_player.stream.loop = true
		bgm_player.play()

func _on_NextStageTrigger_body_entered(body: Node) -> void:
	
	if body.name == "CharacterBody2D":
		
		if bgm_player and bgm_player.playing:
			bgm_player.stop()

		# 次のステージへ切り替え
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)
