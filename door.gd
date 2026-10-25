extends StaticBody2D

var is_open = false

func take_damage(_amount):
	# Only open if hit, not already open, AND all waves are cleared!
	if not is_open and Global.all_waves_cleared:
		is_open = true
		$AnimatedSprite2D.play("open")
		$CollisionShape2D.set_deferred("disabled", true)
		
		# Wait for the opening animation to finish
		await $AnimatedSprite2D.animation_finished
		$AnimatedSprite2D.visible = false
	elif not Global.all_waves_cleared:
		print("The door is locked! Clear all 3 waves first.")
