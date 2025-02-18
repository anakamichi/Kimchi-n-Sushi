extends Sprite2D

@export var float_amplitude := 10.0  # Vertical movement range
@export var float_speed := 2.0       # Speed of movement

var original_position: Vector2
var time := 0.0

func _ready():
	var viewport_size = get_viewport_rect().size
	var texture_size = texture.get_size()

	# Scale proportionally to fill the entire screen
	var scale_factor = max(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	scale = Vector2(scale_factor, scale_factor)

	# Center the sprite properly
	original_position = viewport_size / 2
	position = original_position

func _process(delta):
	time += delta * float_speed
	position.y = original_position.y + sin(time) * float_amplitude
