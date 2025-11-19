@abstract class_name ActorNavigation
extends Node

var actor: CharacterBody2D
var global_position: Vector2:
	get: return actor.global_position
	set(value): actor.global_position = value

@warning_ignore("UNUSED_SIGNAL")
signal target_reached(target: Vector2) ## Emitted when the actor enters the zone within DISTANCE_EPSILON of the target

func _ready() -> void:
	actor = get_parent() as CharacterBody2D
	assert(actor != null, "ActorKinematics must be a child of a CharacterBody2D node.")

	_on_ready()

func _on_ready() -> void: pass # To be overridden by subclasses