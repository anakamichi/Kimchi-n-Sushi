extends Area2D

# Define attack types.
enum AttackType {
	WEAK,
	STRONG,
	SPECIAL
}

# Stores the current active attack type.
var current_attack_type: int = -1

# Get references to the collision shape nodes.
@onready var collision_shape_weak: CollisionShape2D = $CollisionShape_Weak
@onready var collision_shape_strong: CollisionShape2D = $CollisionShape_Strong
@onready var collision_shape_special: CollisionShape2D = $CollisionShape_Special
@onready var attack_area: Area2D = self

func _ready() -> void:
	# Disable all collision shapes initially.
	disable_attack()
	# Connect the "body_entered" signal using modern syntax.
	attack_area.body_entered.connect(_on_AttackArea_body_entered)

# Enables the attack area for a specific attack type.
# 'attack_type' should be one of the AttackType enum values.
func enable_attack(attack_type: int) -> void:
	# Set the current attack type.
	current_attack_type = attack_type
	
	# First, disable all collision shapes.
	collision_shape_weak.disabled = true
	collision_shape_strong.disabled = true
	collision_shape_special.disabled = true
	
	# Enable the collision shape corresponding to the given attack type.
	match attack_type:
		AttackType.WEAK:
			collision_shape_weak.disabled = false
		AttackType.STRONG:
			collision_shape_strong.disabled = false
		AttackType.SPECIAL:
			collision_shape_special.disabled = false
	
	# Enable monitoring safely.
	set_deferred("monitoring", true)

# Disables the attack area and resets the current attack type.
func disable_attack() -> void:
	collision_shape_weak.disabled = true
	collision_shape_strong.disabled = true
	collision_shape_special.disabled = true
	monitoring = false
	current_attack_type = -1

# Called when a body enters the attack area.
func _on_AttackArea_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		var damage = 0  # Initialize damage variable

		# Determine the damage amount based on the attack type.
		match current_attack_type:
			AttackType.WEAK:
				damage = 1
			AttackType.STRONG:
				damage = 3
			AttackType.SPECIAL:
				damage = 15

		# Apply damage if it is greater than 0.
		if damage > 0:
			body.take_damage(damage)
