extends Button

signal start_pressed

@export var fade_duration := 1.0

func _ready():
	animate_glow()
	# Connect OUR button's pressed -> _on_pressed
	pressed.connect(_on_pressed)

func animate_glow():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.5, fade_duration)
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	tween.tween_callback(animate_glow)

func _on_pressed():
	# Play the SE only if it's present and not looping
	if $StartButtonSE and $StartButtonSE is AudioStreamPlayer:
		$StartButtonSE.play()
		await $StartButtonSE.finished  # Wait for one-shot SE to end

	# After the SE is done, tell the TitleScreen to move on
	emit_signal("start_pressed")
