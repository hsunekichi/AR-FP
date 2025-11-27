extends Control

var base_message: StringName = ""
var value: int = 0

func red_animation() -> void:
	var tween = create_tween()
	tween.set_parallel(true)

	# Red flash
	tween.tween_property(self, "modulate", Color(1.5, 0.3, 0.3), 0.1)
	# Scale up
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	# Rotation twitch
	tween.tween_property(self, "rotation", -0.15, 0.05).set_trans(Tween.TRANS_BOUNCE)
	
	tween.chain() # Finish previous block

	# Twitch back
	tween.tween_property(self, "rotation", 0.1, 0.05)
	tween.chain() # Finish rotation

	# Return to normal
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "rotation", 0.0, 0.1)

func set_value(new_value: int) -> void:
	if new_value < value:
		red_animation()

	value = new_value
	$Label.text = base_message + str(value)
