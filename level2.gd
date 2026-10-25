extends Node2D

@export var enemy_scene: PackedScene = preload("res://enemy.tscn")

var target_kills = 0
var wave_in_progress = false

# --- ADAPTIVE AI VARIABLES ---
var wave_start_time = 0.0
var adaptive_difficulty_factor = 1.0 # 1.0 is baseline

func _ready():
	# Reset wave/score variables on fresh level load (lives persist until Game Over)
	Global.current_wave = 1
	Global.enemies_defeated = 0
	Global.all_waves_cleared = false
	start_wave()

func evaluate_player_performance():
	# Measure wave completion time in seconds
	var time_taken = (Time.get_ticks_msec() - wave_start_time) / 1000.0
	
	# Speed-based adaptive scaling since player dies in 1 hit per life
	if time_taken < 10.0:
		adaptive_difficulty_factor += 0.3 # Fast clear: increase enemy stats
		print("Adaptive AI: Player cleared wave quickly! Difficulty factor set to: ", adaptive_difficulty_factor)
	elif time_taken > 25.0:
		adaptive_difficulty_factor = max(0.7, adaptive_difficulty_factor - 0.2) # Slow clear: ease up slightly
		print("Adaptive AI: Player taking longer. Difficulty factor set to: ", adaptive_difficulty_factor)
	else:
		adaptive_difficulty_factor += 0.1 # Steady progression

func start_wave():
	wave_in_progress = true
	wave_start_time = Time.get_ticks_msec()
	
	var display_wave = min(Global.current_wave, 3)
	
	# Show wave announcement banner
	var center_label = $UI/CenterWaveLabel
	center_label.text = "WAVE " + str(display_wave) + "/3"
	center_label.show()
	
	$UI/WaveLabel.text = "Wave " + str(display_wave) + "/3"
	
	# Display centered banner for 1 second before spawning
	await get_tree().create_timer(1.0).timeout
	center_label.hide()
	
	# Determine enemy spawn counts per wave
	var spawn_amount = 0
	if Global.current_wave == 1:
		spawn_amount = 1
		target_kills = 1
	elif Global.current_wave == 2:
		spawn_amount = 2
		target_kills = 1 + 2
	elif Global.current_wave >= 3:
		spawn_amount = 3
		target_kills = 1 + 2 + 3
		
	# Spawn enemies safely at marker points
	var available_spawns = $SpawnPoints.get_children()
	available_spawns.shuffle()
	
	for i in range(spawn_amount):
		var enemy = enemy_scene.instantiate()
		var safe_marker = available_spawns[i % available_spawns.size()]
		enemy.global_position = safe_marker.global_position
		enemy.player_node = $Player
		
		# Apply dynamic stats scale if enemy script supports it
		if enemy.has_method("apply_adaptive_stats"):
			enemy.apply_adaptive_stats(adaptive_difficulty_factor)
			
		add_child(enemy)
		
	wave_in_progress = false

#func update_heart_display():
	## Toggle visible 32px heart icons based on Global.player_lives (3 lives maximum)
#s	$UI/HeartContainer/Heart1.visible = (Global.player_lives >= 1)
	#$UI/HeartContainer/Heart2.visible = (Global.player_lives >= 2)
	#$UI/HeartContainer/Heart3.visible = (Global.player_lives >= 3)

func _process(_delta):
	# Keep Score HUD and Heart indicators updated
	$UI/ScoreLabel.text = "Score: " + str(Global.enemies_defeated * 100)
	#update_heart_display()
	
	# Check wave progress
	if not wave_in_progress and Global.enemies_defeated >= target_kills and Global.current_wave <= 3:
		evaluate_player_performance()
		
		if Global.current_wave == 3:
			$UI/CenterWaveLabel.text = "ALL WAVES CLEARED!"
			$UI/CenterWaveLabel.show()
			$UI/WaveLabel.text = "Wave 3/3"
			
			# Unlock door condition
			Global.all_waves_cleared = true
			Global.current_wave += 1 # Stops further wave progression loops
		else:
			Global.current_wave += 1
			start_wave()
