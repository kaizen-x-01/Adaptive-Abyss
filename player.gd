extends CharacterBody2D

const SPEED = 180.0
@onready var anim = $AnimatedSprite2D

var current_dir = "down"
var is_attacking = false
var health = 5 # PLAYER HEALTH
var is_dead = false

func _physics_process(_delta):
	if is_attacking:
		return 

	if Input.is_action_just_pressed("attack"):
		attack()
		return

	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction:
		velocity = direction * SPEED
		if abs(direction.x) > abs(direction.y):
			current_dir = "right" if direction.x > 0 else "left"
		else:
			current_dir = "down" if direction.y > 0 else "up"
			
		anim.play("run_" + current_dir)
	else:
		velocity = Vector2.ZERO
		anim.play("idle_" + current_dir)

	move_and_slide()

func attack():
	is_attacking = true
	velocity = Vector2.ZERO
	anim.play("attack_" + current_dir)
	$SwordSound.play()
	Global.attacks_used += 1
	
	var bodies_in_range = $AttackArea.get_overlapping_bodies()
	for body in bodies_in_range:
		if body.has_method("take_damage") and body != self:
			# Find the direction of the enemy relative to the player
			var diff = body.global_position - global_position
			var valid_hit = false
			
			# Check if the enemy is in the direction we are facing
			if current_dir == "right" and diff.x > 0:
				valid_hit = true
			elif current_dir == "left" and diff.x < 0:
				valid_hit = true
			elif current_dir == "down" and diff.y > 0:
				valid_hit = true
			elif current_dir == "up" and diff.y < 0:
				valid_hit = true
				
			if valid_hit:
				body.take_damage(1) 
			
	await anim.animation_finished
	is_attacking = false

# --- NEW: PLAYER TAKES DAMAGE ---
# --- NEW: PLAYER TAKES DAMAGE ---
func take_damage(amount):
	if is_dead:
		return # Stop right here if the player is already dead!
		
	health -= amount
	print("Player Health: ", health)
	
	# Hurt effect: Flash red for 0.2 seconds
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.2).timeout
	modulate = Color(1, 1, 1)
	
	if health <= 0:
		is_dead = true # Mark the player as dead so this code doesn't repeat
		print("GAME OVER!")
		
		$DeathSound.play()
		hide() 
		set_physics_process(false) 
		
		# Turn off the player's hitbox so the enemy stops attacking
		$CollisionShape2D.set_deferred("disabled", true)
		
		# Wait for the game over sound to finish before restarting
		await $DeathSound.finished 
		
		get_tree().reload_current_scene()
