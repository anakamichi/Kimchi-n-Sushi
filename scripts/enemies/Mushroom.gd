extends CharacterBody2D

class_name Mushroom

const speed = 10
var is_chase: bool = false

var health = 2
var health_max = 2
var health_min = 0

var dead: bool = false
var taking_damage: bool = false
var damage_to_deal = 1
var is_dealing_damage: bool = false

var dir: Vector2
const gravity = 100
var knockback_force = 200
var is_roaming: bool = true

var goblin: CharacterBody2D
var goblin_in_area = false

func _process(delta):
	if !is_on_floor():
		velocity.y += gravity * delta
		velocity.x = 0
		
	
	move(delta)
	handle_animation()
	move_and_slide()

func move(delta):
	if !dead:
		if !is_chase:
			velocity += dir * speed * delta
		elif is_chase and !taking_damage:
			var dir_to_player = position.direction_to(goblin.position) * speed
			velocity.x = dir_to_player.x
			dir.x = abs(velocity.x) / velocity.x
		elif taking_damage:
			var knockback_dir = position.direction_to(goblin.position) * knockback_force
			velocity.x = knockback_dir.x
		is_roaming = true
	elif dead:
		velocity.x = 0	

func handle_animation():
	var anim_sprite = $AnimatedSprite2D
	if !dead and !taking_damage and !is_dealing_damage:
		anim_sprite.play("run")
		if dir.x == -1:
			anim_sprite.flip_h = true
		elif dir.x == 1:
			anim_sprite.flip_h = false
	elif !dead and taking_damage and !is_dealing_damage:
		anim_sprite.play("take_hit")
		await get_tree().create_timer(.8).timeout
		taking_damage = false
	elif dead and is_roaming:
		is_roaming = false
		anim_sprite.play("death")
		await get_tree().create_timer(1.0).timeout
		handle_death()
		
func handle_death():
	self.queue_free()

func _on_direction_timer_timeout():
	$DirectionTimer.wait_time = choose([1.5,2.0,2.5])
	if !is_chase:
		dir = choose([Vector2.RIGHT, Vector2.LEFT])
		velocity.x = 0
	
func choose(array):
	array.shuffle()
	return array.front()
	
func _on_area_entered(area):
	if area.is_in_group("player_detection_area"): # Use a dedicated area for detection
		is_chase = true

func _on_area_exited(area):
	if area.is_in_group("player_detection_area"):
		is_chase = false
		is_roaming = true
		_on_direction_timer_timeout()

