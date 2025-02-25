extends CharacterBody2D
class_name Player

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

var state: int = PlayerState.IDLE
var hp: int = 100

var invincible: bool = false
var invincible_timer: float = 0.0
const INVINCIBLE_DURATION: float = 1.0

const WALK_SPEED: float = 100.0
const RUN_SPEED: float = 200.0
const GRAVITY: float = 800.0
const JUMP_FORCE: float = -400.0

var weak_attack_cooldown: float = 0.0
var strong_attack_cooldown: float = 0.0
var special_attack_cooldown: float = 0.0

const WEAK_ATTACK_COOLDOWN: float = 0.3
const STRONG_ATTACK_COOLDOWN: float = 0.6
const SPECIAL_ATTACK_COOLDOWN: float = 1.0

var was_on_floor: bool = false
var last_direction: int = 1  # 1 = facing right, -1 = facing left

const HP_BAR_PATH = "/root/Main/HUD/HPBar"

func _ready() -> void:
	$AnimatedSprite2D.play("idle")
	$AttackArea.disable_attack()
	was_on_floor = is_on_floor()

	# Shadow setup
	$Shadow.texture = $AnimatedSprite2D.sprite_frames.get_frame_texture("idle", 0)
	$Shadow.modulate = Color(0, 0, 0, 0.196)
	$Shadow.self_modulate = Color(0, 0, 0)
	$Shadow.z_index = -1

	$AnimatedSprite2D.frame_changed.connect(_update_shadow)
	_update_shadow()

	$AnimatedSprite2D.sprite_frames.set_animation_loop("hurt", false)
	$AnimatedSprite2D.sprite_frames.set_animation_loop("jump", false)
	$AnimatedSprite2D.sprite_frames.set_animation_loop("land", false)
	$AnimatedSprite2D.sprite_frames.set_animation_loop("strongAttack", false)
	$AnimatedSprite2D.sprite_frames.set_animation_loop("weakAttack", false)
	$AnimatedSprite2D.sprite_frames.set_animation_loop("specialAttack", false)
	$AnimatedSprite2D.sprite_frames.set_animation_loop("death", false)

	$AnimatedSprite2D.animation_finished.connect(_on_AnimatedSprite2D_animation_finished)
	print("Player Ready! Position:", position)

	if has_node(HP_BAR_PATH):
		var hp_bar = get_node(HP_BAR_PATH) as ProgressBar
		hp_bar.max_value = 100
		hp_bar.value = hp

func _physics_process(delta: float) -> void:
	if state == PlayerState.DEATH:
		return
	
	weak_attack_cooldown = max(0.0, weak_attack_cooldown - delta)
	strong_attack_cooldown = max(0.0, strong_attack_cooldown - delta)
	special_attack_cooldown = max(0.0, special_attack_cooldown - delta)
	
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0.0:
			invincible = false

	if state in [PlayerState.WEAK_ATTACK, PlayerState.STRONG_ATTACK, PlayerState.SPECIAL_ATTACK, PlayerState.HURT]:
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		return

	var input_direction: int = 0
	if Input.is_action_pressed("ui_left"):
		input_direction -= 1
	if Input.is_action_pressed("ui_right"):
		input_direction += 1
	
	var running: bool = Input.is_action_pressed("ui_select") # SHIFT or something

	if input_direction != 0:
		last_direction = input_direction
		velocity.x = input_direction * (RUN_SPEED if running else WALK_SPEED)
		state = PlayerState.RUN if running else PlayerState.WALK
		$AnimatedSprite2D.play("run" if running else "walk")
		$AnimatedSprite2D.flip_h = (input_direction < 0)
		_update_shadow()
	else:
		velocity.x = move_toward(velocity.x, 0, 10)
		if state != PlayerState.IDLE and is_on_floor():
			state = PlayerState.IDLE
			$AnimatedSprite2D.play("idle")
			_update_shadow()

	# ★★ Flip AttackArea based on last_direction ★★
	$AttackArea.scale.x = float(last_direction)
	#  ↑ これにより、CollisionShape_Weak / Strong / Special が左右反転される

	# Jumping
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_FORCE
		state = PlayerState.JUMP
		$AnimatedSprite2D.play("jump")
		_update_shadow()

	# Gravity & fall
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		if velocity.y > 0 and state != PlayerState.FALL:
			state = PlayerState.FALL
			$AnimatedSprite2D.play("fall")
			_update_shadow()
	else:
		if not was_on_floor:
			state = PlayerState.IDLE
			$AnimatedSprite2D.play("idle")
			_update_shadow()
			velocity.y = 0
			was_on_floor = true

	was_on_floor = is_on_floor()

	# Attacks
	if Input.is_action_just_pressed("weakAttack") and weak_attack_cooldown <= 0.0:
		state = PlayerState.WEAK_ATTACK
		weak_attack_cooldown = WEAK_ATTACK_COOLDOWN
		$AnimatedSprite2D.play("weakAttack")
		$AttackArea.enable_attack($AttackArea.AttackType.WEAK)
		_play_attack_sound(PlayerState.WEAK_ATTACK)
		_update_shadow()
		move_and_slide()
		return
	
	if Input.is_action_just_pressed("strongAttack") and strong_attack_cooldown <= 0.0:
		state = PlayerState.STRONG_ATTACK
		strong_attack_cooldown = STRONG_ATTACK_COOLDOWN
		$AnimatedSprite2D.play("strongAttack")
		$AttackArea.enable_attack($AttackArea.AttackType.STRONG)
		_play_attack_sound(PlayerState.STRONG_ATTACK)
		_update_shadow()
		move_and_slide()
		return
	
	if Input.is_action_just_pressed("specialAttack") and special_attack_cooldown <= 0.0:
		state = PlayerState.SPECIAL_ATTACK
		special_attack_cooldown = SPECIAL_ATTACK_COOLDOWN
		$AnimatedSprite2D.play("specialAttack")
		$AttackArea.enable_attack($AttackArea.AttackType.SPECIAL)
		_play_attack_sound(PlayerState.SPECIAL_ATTACK)
		_update_shadow()
		move_and_slide()
		return

	move_and_slide()

func _on_AnimatedSprite2D_animation_finished() -> void:
	if state in [PlayerState.WEAK_ATTACK, PlayerState.STRONG_ATTACK, PlayerState.SPECIAL_ATTACK]:
		$AttackArea.disable_attack()
		state = PlayerState.IDLE
		$AnimatedSprite2D.play("idle")
	elif state == PlayerState.HURT:
		state = PlayerState.IDLE
		$AnimatedSprite2D.play("idle")
	_update_shadow()

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
		invincible_timer = 1.0
		$AnimatedSprite2D.play("hurt")

	if has_node(HP_BAR_PATH):
		var hp_bar = get_node(HP_BAR_PATH) as ProgressBar
		hp_bar.value = hp

	_update_shadow()

func die() -> void:
	state = PlayerState.DEATH
	$AnimatedSprite2D.play("death")
	_update_shadow()

# Double Jump Variables and Functions
var double_jump_used: bool = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up") and not is_on_floor() and not double_jump_used and state != PlayerState.DEATH:
		double_jump()

func double_jump() -> void:
	velocity.y = JUMP_FORCE
	state = PlayerState.JUMP
	$AnimatedSprite2D.play("jump")
	_update_shadow()
	double_jump_used = true

func _process(delta: float) -> void:
	if is_on_floor():
		double_jump_used = false

func _update_shadow() -> void:
	$Shadow.texture = $AnimatedSprite2D.sprite_frames.get_frame_texture($AnimatedSprite2D.animation, $AnimatedSprite2D.frame)
	$Shadow.flip_h = $AnimatedSprite2D.flip_h
	$Shadow.scale = Vector2(1.3, 1.3)

	if is_on_floor():
		$Shadow.position = Vector2($AnimatedSprite2D.position.x, $AnimatedSprite2D.position.y + 7)
		$Shadow.modulate = Color(0, 0, 0, 0.5)
	else:
		$Shadow.position = Vector2($AnimatedSprite2D.position.x, $AnimatedSprite2D.position.y + 7)
		$Shadow.modulate = Color(0, 0, 0, 0.5)

func _play_attack_sound(attack_type: int) -> void:
	match attack_type:
		PlayerState.WEAK_ATTACK:
			$weakAttack.play()
		PlayerState.STRONG_ATTACK:
			$strongAttack.play()
		PlayerState.SPECIAL_ATTACK:
			$specialAttack.play()
