extends Control

@onready var display: HBoxContainer = $HBoxContainer  
@export var statIcon: PackedScene

func red_animation(target) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Red flash
	tween.tween_property(target, "modulate", Color(1.5, 0.3, 0.3), 0.1)
	# Scale up
	tween.tween_property(target, "scale", Vector2(1.3, 1.3), 0.1)
	# Rotation twitch
	tween.tween_property(target, "rotation", -0.15, 0.05).set_trans(Tween.TRANS_BOUNCE)
	
	tween.chain()
	# Twitch back
	tween.tween_property(target, "rotation", 0.1, 0.05)
	
	tween.chain()
	tween.set_parallel(true)
	# Return to normal
	tween.tween_property(target, "modulate", Color.WHITE, 0.2)
	tween.tween_property(target, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(target, "rotation", 0.0, 0.1)


func pop_in_animation(target) -> void:
	# Pop-in animation (fade in + bounce + rotation)
	target.modulate.a = 0.0
	target.position.y = -10
	target.scale = Vector2(1.3, 1.3)
	target.rotation = -0.15
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(target, "modulate:a", 1.0, 0.15)
	#tween.tween_property(target, "position:y", 0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	#tween.tween_property(target, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	#tween.tween_property(target, "rotation", 0.0, 0.2)


func update_value(new_value: int) -> void:
	var current_value := display.get_child_count()

	if current_value > new_value:
		red_animation(display)

	# Remove excess lives
	while current_value > new_value:
		var child = display.get_child(current_value - 1)
		display.remove_child(child)
		child.queue_free()
		current_value -= 1

	# Add missing lives
	while current_value < new_value:
		var instance = statIcon.instantiate()
		display.add_child(instance)
		pop_in_animation(instance)
		current_value += 1
