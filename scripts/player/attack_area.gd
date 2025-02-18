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
	
	# Connect the "body_entered" signal to detect collisions.
	attack_area.body_entered.connect(_on_AttackArea_body_entered)
	print("Attack area ready!")

# Enables the attack area for a specific attack type.
# 'attack_type' should be one of the AttackType enum values.
func enable_attack(attack_type: int) -> void:
	print("Enabling attack:", attack_type)  # Debugging output

	# Set the current attack type.
	current_attack_type = attack_type

	# Disable all collision shapes first.
	collision_shape_weak.disabled = true
	collision_shape_strong.disabled = true
	collision_shape_special.disabled = true

	# Enable the correct attack shape based on attack type.
	match attack_type:
		AttackType.WEAK:
			collision_shape_weak.disabled = false
		AttackType.STRONG:
			collision_shape_strong.disabled = false
		AttackType.SPECIAL:
			collision_shape_special.disabled = false

	# Enable monitoring so collisions register.
	set_deferred("monitoring", true)
	print("Attack area activated")

# Disables the attack area and resets the current attack type.
func disable_attack() -> void:
	print("Disabling attack area")  # Debugging output

	# Disable all collision shapes.
	collision_shape_weak.disabled = true
	collision_shape_strong.disabled = true
	collision_shape_special.disabled = true

	# Disable monitoring to prevent unnecessary calculations.
	set_deferred("monitoring", false)
	
	# Reset attack type.
	current_attack_type = -1

# Called when a body enters the attack area.
func _on_AttackArea_body_entered(body: Node) -> void:
	# Get the parent player (the entity controlling this attack area).
	var parent_player = get_parent()
	
	# If the collision body is the parent (player itself), ignore it.
	if body == parent_player:
		return

	# If no attack type is set, do nothing.
	if current_attack_type == -1:
		return
	
	# Check if the collided body has a "take_damage" method.
	if body.has_method("take_damage"):
		var damage = 0

		# Assign damage values based on attack type.
		match current_attack_type:
			AttackType.WEAK:
				damage = 1
			AttackType.STRONG:
				damage = 3
			AttackType.SPECIAL:
				damage = 15

		# Ensure damage is applied only if greater than 0.
		if damage > 0:
			body.take_damage(damage)
	
	# Disable attack after dealing damage.
	disable_attack()



