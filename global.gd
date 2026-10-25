extends Node

var attacks_used = 0
var enemies_defeated = 0
var current_level = 1
var current_wave = 1
var all_waves_cleared = false

# --- ADAPTIVE AI STATS  ---
var enemy_speed_multiplier = 1.0
var enemy_health_bonus = 0
var enemy_damage = 1
