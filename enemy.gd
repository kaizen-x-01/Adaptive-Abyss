extends CharacterBody2D
var speed = 150.0 
const ATTACK_RANGE = 30.0
@onready var nav_agent = $NavigationAgent2D
@onready var anim = $AnimatedSprite2D

var player_node = null
var health = 3
var is_dead = false
var is_attacking = false
var is_hurt = false
var has_dealt_damage = false # Tracks if damage was already dealt this swing
var base_color = Color(1,1,1)

func apply_adaptive_stats(factor: float):
	# Base values
	var base_speed = 110.0
	var base_health = 3
	
	# Scale stats dynamically by adaptive factor
	speed = base_speed * factor
	health = int(round(base_health * factor))
	
	# Visual indication of scaled threat (darker red = higher difficulty)
	var tint = clamp(1.0 - (factor - 1.0) * 0.5, 0.2, 1.0)
	modulate = Color(1.0, tint, tint)
	
	
func _ready():
	
	# Apply stats and colors based on the current wave
	if Global.current_wave == 1:
		base_color = Color(1.0, 1.0, 1.0) # Normal
		speed = 80.0
		health = 3
	elif Global.current_wave == 2:
		base_color = Color(1.0, 0.6, 0.6) # Light Red
		speed = 90.0
		health = 4
	elif Global.current_wave >= 3:
		base_color = Color(1.0, 0.2, 0.2) # Dark Red
		speed = 100.0
		health = 5
		
	modulate = base_color
	
	
func _physics_process(_delta):
	if is_dead or is_hurt or not player_node:
		return
		
	if is_attacking:
		if anim.animation == "attack" and anim.frame >= 13 and anim.frame <= 19 and not has_dealt_damage:
			# Check if the player is on the side the skeleton is facing
			var player_is_left = player_node.global_position.x < global_position.x
			var skeleton_facing_left = anim.flip_h
			
			if player_is_left == skeleton_facing_left:
				if global_position.distance_to(player_node.global_position) <= ATTACK_RANGE + 15:
					if player_node.has_method("take_damage"):
						player_node.take_damage(1)
						$PlayerHitSound.play()
			
			has_dealt_damage = true 
		return
		
	var distance = global_position.distance_to(player_node.global_position)
	if distance <= ATTACK_RANGE:
		attack_player()
		return
		
	nav_agent.target_position = player_node.global_position
	var current_pos = global_position
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = current_pos.direction_to(next_path_pos)
	
	velocity = direction * speed
	
	if velocity.length() > 0:
		anim.play("move")
		if velocity.x != 0:
			anim.flip_h = velocity.x < 0
	else:
		anim.play("idle")
		
	move_and_slide()

func attack_player():
	is_attacking = true
	has_dealt_damage = false 
	velocity = Vector2.ZERO
	
	# Face the player before swinging
	if player_node:
		anim.flip_h = player_node.global_position.x < global_position.x
		
	anim.play("attack")
	await anim.animation_finished 
	is_attacking = false

func take_damage(amount):
	if is_dead:
		return
		
	health -= amount
	
	Engine.time_scale = 0.2
	await get_tree().create_timer(0.02 * Engine.time_scale).timeout
	Engine.time_scale = 1.0
	
	if health <= 0:
		die()
	else:
		is_attacking = false
		is_hurt = true
		
		if player_node:
			var knockback_dir = player_node.global_position.direction_to(global_position)
			velocity = knockback_dir * 300
			move_and_slide() # Instantly apply the push
		else:
			velocity = Vector2.ZERO
		
		anim.play("hurt")
		modulate = Color(1, 0, 0)
		
		#var original_scale = anim.scale
		#anim.scale = Vector2(1.4, 0.7) 
		
		
		var original_pos = anim.position
		for i in range(3):
			anim.position.x = original_pos.x + 4
			await get_tree().create_timer(0.05).timeout
			anim.position.x = original_pos.x - 4
			await get_tree().create_timer(0.05).timeout
			
		# Reset position, scale, and color
		anim.position = original_pos
		#anim.scale = original_scale 
		modulate = base_color
		
		await get_tree().create_timer(0.5).timeout
		is_hurt = false

func die():
	is_dead = true
	Global.enemies_defeated += 1
	velocity = Vector2.ZERO
	$Death.play()
	
	$ScoreSound.play()
	# --- CREATE THE FLOATING +100 POPUP ---
	var popup = Label.new()
	popup.text = "+100"
	
	popup.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0)) 
	popup.add_theme_font_size_override("font_size", 12)
	
	popup.global_position = global_position + Vector2(-10, -20) 
	
	get_tree().current_scene.add_child(popup)
	
	var tween = get_tree().create_tween()
	tween.tween_property(popup, "position", popup.global_position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 1.0)
	
	tween.tween_callback(popup.queue_free)
	
	anim.play("die")
	await anim.animation_finished
	queue_free()
