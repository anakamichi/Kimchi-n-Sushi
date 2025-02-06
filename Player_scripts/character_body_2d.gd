extends CharacterBody2D

# Define player states.
enum PlayerState {
	IDLE,
	WALK,
	RUN,
	JUMP,
	FALL,
	LAND,
	WEAK_ATTACK,
	STRONG_ATTACK,
	SPECIAL_ATTACK,
	HURT,
	DEATH
}

# --- Player variables ---
var state: int = PlayerState.IDLE
var hp: int = 100

# Invincibility (after being hurt).
var invincible: bool = false
var invincible_timer: float = 0.0
const INVINCIBLE_DURATION: float = 1.0

# --- Movement constants ---
const WALK_SPEED: float = 100.0
const RUN_SPEED: float = 200.0
const GRAVITY: float = 5000.0
const JUMP_FORCE: float = -400.0

# --- Attack cooldowns (in seconds) ---
var weak_attack_cooldown: float = 0.0
var strong_attack_cooldown: float = 0.0
var special_attack_cooldown: float = 0.0
const WEAK_ATTACK_COOLDOWN: float = 0.3
const STRONG_ATTACK_COOLDOWN: float = 0.6
const SPECIAL_ATTACK_COOLDOWN: float = 1.0

# Used to detect landing (transition from air to floor).
var was_on_floor: bool = false
var last_direction: int = 1  # 1 = right, -1 = left

func _ready() -> void:
	# Play the idle animation on start.
	$AnimatedSprite2D.play("idle")
	# Disable the attack area initially using its own method.
	$AttackArea.disable_attack()
	was_on_floor = is_on_floor()
	
	# Connect the animation_finished signal.
	$AnimatedSprite2D.animation_finished.connect(_on_AnimatedSprite2D_animation_finished)
	
	# Debugging print to confirm _ready() is running
	print("Player Ready! Position:", position)

func _physics_process(delta: float) -> void:
	# Debugging print to check physics process is running
	print("Physics running - Velocity:", velocity)

	if state == PlayerState.DEATH:
		return

	# Update attack cooldown timers.
	weak_attack_cooldown = max(0.0, weak_attack_cooldown - delta)
	strong_attack_cooldown = max(0.0, strong_attack_cooldown - delta)
	special_attack_cooldown = max(0.0, special_attack_cooldown - delta)

	# Update invincibility timer.
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0.0:
			invincible = false

	# Prevent movement input during certain animations.
	if state in [PlayerState.WEAK_ATTACK, PlayerState.STRONG_ATTACK, PlayerState.SPECIAL_ATTACK, PlayerState.HURT, PlayerState.LAND]:
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		return

	# Process movement input.
	var input_direction: int = 0
	if Input.is_action_pressed("ui_left"):
		input_direction -= 1
	if Input.is_action_pressed("ui_right"):
		input_direction += 1

	# Debugging movement input
	print("Input direction:", input_direction)

	var running: bool = Input.is_action_pressed("ui_select")  # Shift for running
	if input_direction != 0:
		last_direction = input_direction
		if running:
			velocity.x = input_direction * RUN_SPEED
			if state != PlayerState.RUN:
				state = PlayerState.RUN
				$AnimatedSprite2D.play("run")
		else:
			velocity.x = input_direction * WALK_SPEED
			if state != PlayerState.WALK:
				state = PlayerState.WALK
				$AnimatedSprite2D.play("walk")

		# Flip sprite based on movement direction
		$AnimatedSprite2D.flip_h = (input_direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, 10)
		if state != PlayerState.IDLE:
			state = PlayerState.IDLE
			$AnimatedSprite2D.play("idle")

	# Process jumping.
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_FORCE
		state = PlayerState.JUMP
		$AnimatedSprite2D.play("jump")

	# Apply gravity.
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		if velocity.y > 0 and state != PlayerState.FALL:
			state = PlayerState.FALL
			$AnimatedSprite2D.play("fall")
	else:
		if not was_on_floor:
			state = PlayerState.LAND
			$AnimatedSprite2D.play("land")
			velocity.y = 0
			was_on_floor = true
			move_and_slide()
			return

	was_on_floor = is_on_floor()

	# Process attack inputs.
	if Input.is_action_just_pressed("attack_weak") and weak_attack_cooldown <= 0.0:
		state = PlayerState.WEAK_ATTACK
		weak_attack_cooldown = WEAK_ATTACK_COOLDOWN
		$AnimatedSprite2D.play("weakAttack")
		$AttackArea.enable_attack($AttackArea.AttackType.WEAK)
		return
	elif Input.is_action_just_pressed("attack_strong") and strong_attack_cooldown <= 0.0:
		state = PlayerState.STRONG_ATTACK
		strong_attack_cooldown = STRONG_ATTACK_COOLDOWN
		$AnimatedSprite2D.play("strongAttack")
		$AttackArea.enable_attack($AttackArea.AttackType.STRONG)
		return
	elif Input.is_action_just_pressed("attack_special") and special_attack_cooldown <= 0.0:
		state = PlayerState.SPECIAL_ATTACK
		special_attack_cooldown = SPECIAL_ATTACK_COOLDOWN
		$AnimatedSprite2D.play("specialAttack")
		$AttackArea.enable_attack($AttackArea.AttackType.SPECIAL)
		return

	# Finally, move the character.
	move_and_slide()

func _on_AnimatedSprite2D_animation_finished() -> void:
	if state in [PlayerState.WEAK_ATTACK, PlayerState.STRONG_ATTACK, PlayerState.SPECIAL_ATTACK]:
		$AttackArea.disable_attack()
		state = PlayerState.IDLE
		$AnimatedSprite2D.play("idle")
	elif state == PlayerState.LAND or state == PlayerState.HURT:
		state = PlayerState.IDLE
		$AnimatedSprite2D.play("idle")

func take_damage(amount: int) -> void:
	if invincible or state == PlayerState.DEATH:
		return
	hp -= amount
	if hp <= 0:
		hp = 0
		die()
	else:
		state = PlayerState.HURT
		invincible = true
		invincible_timer = INVINCIBLE_DURATION
		$AnimatedSprite2D.play("hurt")

func die() -> void:
	state = PlayerState.DEATH
	$AnimatedSprite2D.play("death")
