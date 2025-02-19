extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	disable_attack()
	self.body_entered.connect(_on_AttackArea_body_entered)

func enable_attack() -> void:
	collision_shape.disabled = false
	set_deferred("monitoring", true)

func disable_attack() -> void:
	collision_shape.disabled = true
	set_deferred("monitoring", false)

func _on_AttackArea_body_entered(body: Node) -> void:
	# Prevent attacking itself
	if body == get_parent():
		return
	
	# Only damage the player
	if body is Player:
		body.take_damage(2)
	
	# Disable attack after a successful hit
	disable_attack()

