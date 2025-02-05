# Description of Player scripts

1. **Player Script** (extends `CharacterBody2D`)
2. **Attack Area Script** (extends `Area2D`)

They work together to create a player character who can move, jump, attack, and take damage.

---

## 1. Player Script

### Player States
```gdscript
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
```
- These are the different actions or "states" the player can be in (e.g. standing still, walking, running, jumping, etc.).

### Player Variables
```gdscript
var state: int = PlayerState.IDLE
var hp: int = 100
var invincible: bool = false
var invincible_timer: float = 0.0
const INVINCIBLE_DURATION: float = 1.0
```
- `state` tracks the current player state (e.g., `IDLE`, `JUMP`, `ATTACK`).
- `hp` is the player’s health.
- `invincible` and `invincible_timer` control whether the player can take damage again after being hit. The player will not be hurt during invincibility.

### Movement Constants
```gdscript
const WALK_SPEED: float = 100.0
const RUN_SPEED: float = 200.0
const GRAVITY: float = 1000.0
const JUMP_FORCE: float = -400.0
```
- These are the speeds and forces for the player when walking, running, falling, and jumping.

### Attack Cooldowns
```gdscript
var weak_attack_cooldown: float = 0.0
var strong_attack_cooldown: float = 0.0
var special_attack_cooldown: float = 0.0
const WEAK_ATTACK_COOLDOWN: float = 0.3
const STRONG_ATTACK_COOLDOWN: float = 0.6
const SPECIAL_ATTACK_COOLDOWN: float = 1.0
```
- Each attack type (weak, strong, special) has a timer. After the player attacks, a cooldown prevents immediately attacking again.

### Ready Function
```gdscript
func _ready() -> void:
    $AnimatedSprite2D.play("idle")
    $AttackArea.disable_attack()
    was_on_floor = is_on_floor()

    $AnimatedSprite2D.animation_finished.connect(_on_AnimatedSprite2D_animation_finished)
```
- Runs when the game starts.
- Sets the initial animation to "idle".
- Disables the attack area so the player doesn’t constantly deal damage.
- Connects a signal to detect when animations finish.

### Physics Process
```gdscript
func _physics_process(delta: float) -> void:
    if state == PlayerState.DEATH:
        return
```
- This function is called every frame to handle movement, jumping, gravity, and attacks.
- If the player is dead, we skip the rest.

#### Cooldowns and Invincibility
```gdscript
weak_attack_cooldown = max(0.0, weak_attack_cooldown - delta)
strong_attack_cooldown = max(0.0, strong_attack_cooldown - delta)
special_attack_cooldown = max(0.0, special_attack_cooldown - delta)

if invincible:
    invincible_timer -= delta
    if invincible_timer <= 0.0:
        invincible = false
```
- We reduce each attack cooldown over time.
- If the player is invincible, reduce the timer until they can be hurt again.

#### Prevent Movement in Certain States
```gdscript
if state in [PlayerState.WEAK_ATTACK, PlayerState.STRONG_ATTACK, PlayerState.SPECIAL_ATTACK,
             PlayerState.HURT, PlayerState.LAND]:
    # Gravity still applies if player is in air, but no movement input is processed.
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    move_and_slide()
    return
```
- When the player is attacking or hurt, they cannot move (but can still fall due to gravity).

#### Moving Left or Right
```gdscript
var input_direction: int = 0
if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
    input_direction -= 1
if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
    input_direction += 1
```
- Checks input to see if the player is moving left (`-1`) or right (`+1`).

#### Walking vs. Running
```gdscript
var running: bool = Input.is_key_pressed(KEY_SHIFT)
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
    $AnimatedSprite2D.flip_h = (input_direction < 0)
else:
    velocity.x = move_toward(velocity.x, 0, 10)
    if state != PlayerState.IDLE:
        state = PlayerState.IDLE
        $AnimatedSprite2D.play("idle")
```
- If the player is holding Shift, move faster (`RUN_SPEED`).
- Otherwise, use `WALK_SPEED`.
- If no key is pressed, slow down to 0 and switch to `IDLE` state.

#### Jumping
```gdscript
if Input.is_action_just_pressed("ui_jump") and is_on_floor():
    velocity.y = JUMP_FORCE
    state = PlayerState.JUMP
    $AnimatedSprite2D.play("jump")
```
- If jump is pressed and the player is on the floor, make them jump.

#### Gravity and Falling
```gdscript
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
```
- Adds gravity if the player is not on the floor.
- If they just landed, switch to the `LAND` animation.
- Update `was_on_floor` so we know if the player was previously on the ground.

#### Attacks
```gdscript
if Input.is_key_pressed(KEY_Z) and weak_attack_cooldown <= 0.0:
    state = PlayerState.WEAK_ATTACK
    weak_attack_cooldown = WEAK_ATTACK_COOLDOWN
    $AnimatedSprite2D.play("weakAttack")
    $AttackArea.enable_attack($AttackArea.AttackType.WEAK)
    return
elif Input.is_key_pressed(KEY_X) and strong_attack_cooldown <= 0.0:
    ...
elif Input.is_key_pressed(KEY_C) and special_attack_cooldown <= 0.0:
    ...
```
- Press Z, X, or C to attack (weak, strong, or special).
- Each sets a specific animation and cooldown, and enables the corresponding attack area.

#### Final Move
```gdscript
move_and_slide()
```
- Moves the player based on the velocity and checks collisions.

### Animation Finished Signal
```gdscript
func _on_AnimatedSprite2D_animation_finished() -> void:
    if state in [PlayerState.WEAK_ATTACK, PlayerState.STRONG_ATTACK, PlayerState.SPECIAL_ATTACK]:
        $AttackArea.disable_attack()
        state = PlayerState.IDLE
        $AnimatedSprite2D.play("idle")
    elif state == PlayerState.LAND:
        state = PlayerState.IDLE
        $AnimatedSprite2D.play("idle")
    elif state == PlayerState.HURT:
        state = PlayerState.IDLE
        $AnimatedSprite2D.play("idle")
```
- When an attack or landing animation ends, go back to the `IDLE` state.
- Disable the attack area so we don’t keep damaging enemies.

### Taking Damage
```gdscript
func take_damage(amount: int) -> void:
    if invincible or state == PlayerState.DEATH:
        return
    hp -= amount
    if hp <= 0:
        die()
    else:
        state = PlayerState.HURT
        invincible = true
        invincible_timer = INVINCIBLE_DURATION
        $AnimatedSprite2D.play("hurt")
```
- Decreases player HP.
- If HP drops to 0, call `die()`.
- Else, set the state to `HURT` and enable invincibility to avoid immediate extra damage.

### Dying
```gdscript
func die() -> void:
    state = PlayerState.DEATH
    $AnimatedSprite2D.play("death")
```
- Changes the state to `DEATH` and plays the death animation.

---

## 2. Attack Area Script

This script is attached to an `Area2D` node that contains three `CollisionShape2D` nodes for different attacks (weak, strong, special).

### Attack Types
```gdscript
enum AttackType {
    WEAK,
    STRONG,
    SPECIAL
}
```
- Defines which attack is happening.

### Variables
```gdscript
var current_attack_type: int = -1
@onready var collision_shape_weak: CollisionShape2D = $CollisionShape_Weak
@onready var collision_shape_strong: CollisionShape2D = $CollisionShape_Strong
@onready var collision_shape_special: CollisionShape2D = $CollisionShape_Special
```
- We store the active attack type in `current_attack_type`.
- We also have references to each collision shape for different attacks.

### Ready Function
```gdscript
func _ready() -> void:
    disable_attack()
    attack_area.body_entered.connect(_on_AttackArea_body_entered)
```
- Disables attacks at first.
- Connects a signal to detect when a body (enemy or player) enters this `Area2D`.

### Enable Attack
```gdscript
func enable_attack(attack_type: int) -> void:
    current_attack_type = attack_type
    collision_shape_weak.disabled = true
    collision_shape_strong.disabled = true
    collision_shape_special.disabled = true

    match attack_type:
        AttackType.WEAK:
            collision_shape_weak.disabled = false
        AttackType.STRONG:
            collision_shape_strong.disabled = false
        AttackType.SPECIAL:
            collision_shape_special.disabled = false
    
    set_deferred("monitoring", true)
```
- Turns off all collision shapes, then turns on just the one we need (weak, strong, or special).
- Enables `monitoring` so the `Area2D` can detect collisions.

### Disable Attack
```gdscript
func disable_attack() -> void:
    collision_shape_weak.disabled = true
    collision_shape_strong.disabled = true
    collision_shape_special.disabled = true
    monitoring = false
    current_attack_type = -1
```
- Resets everything, turning off collision shapes and collision detection.

### Body Entered Signal
```gdscript
func _on_AttackArea_body_entered(body: Node) -> void:
    if body.has_method("take_damage"):
        var damage = 0
        match current_attack_type:
            AttackType.WEAK:
                damage = 1
            AttackType.STRONG:
                damage = 3
            AttackType.SPECIAL:
                damage = 15
        
        if damage > 0:
            body.take_damage(damage)
```
- When something enters the attack area, we check if it has a `take_damage` method.
- If it does, we apply damage based on the current attack type (weak, strong, or special).

---
