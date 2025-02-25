extends Area2D

enum AttackType {
	WEAK,
	STRONG,
	SPECIAL
}

var current_attack_type: int = -1

@onready var collision_shape_weak: CollisionShape2D = $CollisionShape_Weak
@onready var collision_shape_strong: CollisionShape2D = $CollisionShape_Strong
@onready var collision_shape_special: CollisionShape2D = $CollisionShape_Special
@onready var attack_area: Area2D = self

func _ready() -> void:
	disable_attack()
	attack_area.body_entered.connect(_on_AttackArea_body_entered)
	print("Attack area ready!")

func enable_attack(attack_type: int) -> void:
	print("Enabling attack:", attack_type)
	current_attack_type = attack_type

	# Disable all shapes first
	collision_shape_weak.disabled = true
	collision_shape_strong.disabled = true
	collision_shape_special.disabled = true

	# Enable the specific shape
	match attack_type:
		AttackType.WEAK:
			collision_shape_weak.disabled = false
		AttackType.STRONG:
			collision_shape_strong.disabled = false
		AttackType.SPECIAL:
			collision_shape_special.disabled = false

	# Use deferred call to avoid flush-query issues
	set_deferred("monitoring", true)
	print("Attack area activated")

func disable_attack() -> void:
	print("Disabling attack area")
	# Disable all shapes
	collision_shape_weak.disabled = true
	collision_shape_strong.disabled = true
	collision_shape_special.disabled = true

	# Turn off monitoring
	set_deferred("monitoring", false)
	current_attack_type = -1

func _on_AttackArea_body_entered(body: Node) -> void:
	var parent_player = get_parent()
	if body == parent_player:
		return

	if current_attack_type == -1:
		return

	if body.has_method("take_damage"):
		var damage = 0
		match current_attack_type:
			AttackType.WEAK:
				damage = 3
			AttackType.STRONG:
				damage = 6
			AttackType.SPECIAL:
				damage = 15

		if damage > 0:
			body.take_damage(damage)

	# Defer the disable call to avoid the flush-query error
	call_deferred("disable_attack")

