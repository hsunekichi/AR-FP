extends Area2D

func _on_body_entered(body: Node2D) -> void:
	
	if body.name == "Player":
		print("Goal reached")
		get_tree().reload_current_scene()
