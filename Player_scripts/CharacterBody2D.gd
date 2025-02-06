extends CharacterBody2D

# Define player states
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

# Invincibility (after being hurt)
var invincible: bool = false
var invincible_timer: float = 0.0
const INVINCIBLE_DURATION: float = 1.0

# --- Movement constants ---
const WALK_SPEED: float = 100.0
const RUN_SPEED: float = 200.0
const GRAVITY: float = 800.0
const JUMP_FORCE: float = -400.0

# --- Attack cooldowns (in seconds) ---
var weak_attack_cooldown: float = 0.0
var strong_attack_cooldown: float = 0.0
var special_attack_cooldown: float = 0.0
const WEAK_ATTACK_COOLDOWN: float = 0.3
const STRONG_ATTACK_COOLDOWN: float = 0.6
const SPECIAL_ATTACK_COOLDOWN: float = 1.0

# Used to detect landing transitions
var was_on_floor: bool = false
var last_direction: int = 1  # 1 = facing right, -1 = facing left

func _ready() -> void:
	# Play the idle animation on start
	$AnimatedSprite2D.play("idle")

	# Disable the attack area initially
	$AttackArea.disable_attack()

	was_on_floor = is_on_floor()

	# Connect the animation_finished signal
	$AnimatedSprite2D.animation_finished.connect(_on_AnimatedSprite2D_animation_finished)

	print("Player Ready! Position:", position)

func _physics_process(delta: float) -> void:
	# Debugging
	print("Physics running - Velocity:", velocity)

	# If the player is dead, skip further processing
	if state == PlayerState.DEATH:
		return

	# Update attack cooldown timers
	weak_attack_cooldown = max(0.0, weak_attack_cooldown - delta)
	strong_attack_cooldown = max(0.0, strong_attack_cooldown - delta)
	special_attack_cooldown = max(0.0, special_attack_cooldown - delta)

	# Update invincibility timer
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0.0:
			invincible = false

	# Prevent movement input during certain animations
	if state in [
		PlayerState.WEAK_ATTACK,
		PlayerState.STRONG_ATTACK,
		PlayerState.SPECIAL_ATTACK,
		PlayerState.HURT
	]:
		# Still apply gravity if in the air
		if not is_on_floor():
			velocity.y += GRAVITY * delta

		move_and_slide()
		return

	# ---------------------------
	#     Movement / Input
	# ---------------------------
	var input_direction: int = 0
	if Input.is_action_pressed("ui_left"):
		input_direction -= 1
	if Input.is_action_pressed("ui_right"):
		input_direction += 1

	print("Input direction:", input_direction)

	var running: bool = Input.is_action_pressed("ui_select")  # e.g., SHIFT for running

	# Horizontal movement
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

		# Flip sprite based on direction
		$AnimatedSprite2D.flip_h = (input_direction < 0)
	else:
		# Slow down to 0 if no input
		velocity.x = move_toward(velocity.x, 0, 10)
		if state != PlayerState.IDLE:
			state = PlayerState.IDLE
			$AnimatedSprite2D.play("idle")

	# Jump
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_FORCE
		state = PlayerState.JUMP
		$AnimatedSprite2D.play("jump")

	# Gravity / Falling
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		if velocity.y > 0 and state != PlayerState.FALL:
			state = PlayerState.FALL
			$AnimatedSprite2D.play("fall")
	else:
		# Normally we would do:
		#   if not was_on_floor:
		#       state = PlayerState.LAND
		#       $AnimatedSprite2D.play("land")
		#       velocity.y = 0
		#       was_on_floor = true
		#       move_and_slide()
		#       return
		# But we skip it for now to avoid repeated land animations
		if not was_on_floor:
			state = PlayerState.IDLE
			$AnimatedSprite2D.play("idle")
			velocity.y = 0
			was_on_floor = true
			move_and_slide()
			# return

	was_on_floor = is_on_floor()

	# ---------------------------
	#        Attacks
	# ---------------------------
	# Check if the user has mapped these actions; otherwise skip silently to avoid errors
	if InputMap.has_action("weakAttack"):
		if Input.is_action_just_pressed("weakAttack") and weak_attack_cooldown <= 0.0:
			state = PlayerState.WEAK_ATTACK
			weak_attack_cooldown = WEAK_ATTACK_COOLDOWN
			$AnimatedSprite2D.play("weakAttack")
			$AttackArea.enable_attack($AttackArea.AttackType.WEAK)
			move_and_slide()  # Slight safety to ensure no partial skip
			return

	if InputMap.has_action("strongAttack"):
		if Input.is_action_just_pressed("strongAttack") and strong_attack_cooldown <= 0.0:
			state = PlayerState.STRONG_ATTACK
			strong_attack_cooldown = STRONG_ATTACK_COOLDOWN
			$AnimatedSprite2D.play("strongAttack")
			$AttackArea.enable_attack($AttackArea.AttackType.STRONG)
			move_and_slide()
			return

	if InputMap.has_action("specialAttack"):
		if Input.is_action_just_pressed("specialAttack") and special_attack_cooldown <= 0.0:
			state = PlayerState.SPECIAL_ATTACK
			special_attack_cooldown = SPECIAL_ATTACK_COOLDOWN
			$AnimatedSprite2D.play("specialAttack")
			$AttackArea.enable_attack($AttackArea.AttackType.SPECIAL)
			move_and_slide()
			return

	# Final movement
	move_and_slide()

func _on_AnimatedSprite2D_animation_finished() -> void:
	# When an attack animation finishes, disable the attack and go idle
	if state in [PlayerState.WEAK_ATTACK, PlayerState.STRONG_ATTACK, PlayerState.SPECIAL_ATTACK]:
		$AttackArea.disable_attack()
		state = PlayerState.IDLE
		$AnimatedSprite2D.play("idle")
	elif state == PlayerState.HURT:
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
