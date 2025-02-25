extends CharacterBody2D
class_name Mushroom

# ------------------------------
# Code Comments in English
# ------------------------------
# Movement constants
const SPEED: float = 40.0
const GRAVITY: float = 80.0

# Health parameters
var health: int = 26
var health_max: int = 26

# State flags
var dead: bool = false
var taking_damage: bool = false
var is_attacking: bool = false

# Movement variables
var direction: Vector2 = Vector2(1, 0)
var is_roaming: bool = true
var is_chasing: bool = false

# Attack cooldown
var attack_cooldown: float = 2.0
var attack_timer: float = 0.0

# Chasing ranges
const START_CHASE_RANGE: float = 120.0
const STOP_CHASE_RANGE: float = 200.0

# Child nodes references
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var direction_timer: Timer = $DirectionTimer
@onready var player = get_node("/root/Main/Node2D/CharacterBody2D")

# Audio SFX references (Attack, Death only)
@onready var sfxAttack: AudioStreamPlayer2D = $SFX_Attack
@onready var sfxDeath: AudioStreamPlayer2D = $SFX_Death

func _ready() -> void:
	direction = choose([Vector2.RIGHT, Vector2.LEFT])
	attack_timer = attack_cooldown
	if direction_timer:
		direction_timer.timeout.connect(_on_DirectionTimer_timeout)

func _physics_process(delta: float) -> void:
	if dead:
		velocity.x = 0
	else:
		# Apply gravity
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		else:
			velocity.y = 0

		# Update chase status based on distance to the player
		if player and is_instance_valid(player):
			var distance_to_player = position.distance_to(player.position)
			if is_chasing:
				if distance_to_player > STOP_CHASE_RANGE:
					is_chasing = false
					is_roaming = true
			else:
				if distance_to_player < START_CHASE_RANGE:
					is_chasing = true
					is_roaming = false

		# Set horizontal velocity
		if is_chasing:
			var dx = player.position.x - position.x
			velocity.x = sign(dx) * SPEED
		else:
			velocity.x = direction.x * SPEED

		# If attacking, stop horizontal movement
		if is_attacking:
			velocity.x = 0

		# Attack only when chasing
		if is_chasing and attack_timer <= 0.0 and not is_attacking:
			perform_attack()
			attack_timer = attack_cooldown
		else:
			attack_timer -= delta

	handle_animation()
	move_and_slide()

func handle_animation() -> void:
	if dead:
		if anim_sprite.animation != "death":
			anim_sprite.play("death")
		return

	if is_attacking:
		if anim_sprite.animation != "attack":
			anim_sprite.play("attack")
		return
	elif taking_damage:
		if anim_sprite.animation != "take_hit":
			anim_sprite.play("take_hit")
		return
	else:
		# Idle or run animation
		if velocity.x == 0:
			if anim_sprite.animation != "idle":
				anim_sprite.play("idle")
		else:
			if anim_sprite.animation != "run":
				anim_sprite.play("run")
			anim_sprite.flip_h = (velocity.x < 0)

func perform_attack() -> void:
	is_attacking = true
	_play_sound(sfxAttack)  # Play attack SFX
	if attack_area and attack_area.has_method("enable_attack"):
		attack_area.call_deferred("enable_attack")
	await get_tree().create_timer(0.3).timeout
	if attack_area and attack_area.has_method("disable_attack"):
		attack_area.call_deferred("disable_attack")
	is_attacking = false

func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	taking_damage = true
	await get_tree().create_timer(0.2).timeout
	taking_damage = false
	if health <= 0:
		health = 0
		dead = true
		_play_sound(sfxDeath)  # Play death SFX
		await get_tree().create_timer(1.0).timeout
		queue_free()

func _on_DirectionTimer_timeout() -> void:
	# Flip roaming direction only if not chasing
	if not is_chasing:
		direction.x = -direction.x

func choose(array: Array) -> Variant:
	array.shuffle()
	return array.front()

func _play_sound(audio_player: AudioStreamPlayer2D) -> void:
	if audio_player:
		audio_player.play()

