class_name HolonomicND
extends Node

var VALLEY_HYSTERESIS: float = PI * 0.75 ## Minimum angle improvement to switch to a non-consecutive target valley
var RAY_DISTANCE: float = 1.0 * World.ppu
var PATHFINDER_SHAPE_RADIUS: float = 112


func _on_ready() -> void:
	_pathfinder_shape.radius = PATHFINDER_SHAPE_RADIUS

	# Setup valley debug line
	_valley_line = Line2D.new()
	_valley_line.width = 10.0
	_valley_line.default_color = Color.YELLOW
	World.add_child(_valley_line)

	# Setup pathfinder detection area to roughly detect ground and enable the rays
	_collision_detection = Area2D.new()
	add_child(_collision_detection)

	_collision_shape = CollisionShape2D.new()
	_collision_shape.shape = CircleShape2D.new()
	_collision_shape.shape.radius = RAY_DISTANCE
	_collision_detection.add_child(_collision_shape)

	_collision_detection.monitoring = false
	_collision_detection.collision_mask = World.GROUND_COLLISION_MASK
	_collision_detection.collision_layer = 0

	_collision_detection.body_entered.connect(_pathfinder_body_entered)
	_collision_detection.body_exited.connect(_pathfinder_body_exited)

	# Setup proximity rays
	for i in range(8):
		var ray: RayCast2D = RayCast2D.new()
		ray.target_position = Vector2(1, 0).rotated(i * (PI / 4)) * RAY_DISTANCE
		ray.collision_mask = World.GROUND_COLLISION_MASK
		ray.enabled = false

		add_child(ray)
		_proximity_rays.append(ray)
		_ray_angles.append(i * (PI / 4))

	_enable_rays()

func set_shape(ray_radius: float, cast_radius: float) -> void:
	PATHFINDER_SHAPE_RADIUS = cast_radius
	_pathfinder_shape.radius = PATHFINDER_SHAPE_RADIUS

	RAY_DISTANCE = ray_radius
	_collision_shape.shape.radius = RAY_DISTANCE

	for i in range(8):
		_proximity_rays[i].target_position = Vector2(1, 0).rotated(i * (PI / 4)) * RAY_DISTANCE

func _pathfinder_body_entered(_body: Node) -> void: # Ground detected
	_enable_rays()
func _pathfinder_body_exited(_body: Node) -> void: # Ground lost
	_disable_rays()

func compute_direction(position: Vector2, target: Vector2) -> Vector2:
	var to_target = target - position
	var direction: Vector2 = to_target
	var ray_end: Vector2 = position + to_target.normalized() * minf(to_target.length(), RAY_DISTANCE * 2.0)

	# Path is occluded, we need to change the direction
	if World.ray_intersects_ground(position, ray_end) or _circle_intersects(position, ray_end):
		# Select best valley to reach target
		var valley = _select_valley(position, to_target.angle())

		# Combine fleeing from walls with going to a valley
		direction = _repel_walls()		
		if valley != INF: 
			direction += Vector2(1, 0).rotated(valley)
			
			# Update valley line visualization
			if _valley_line:
				var line_length = RAY_DISTANCE * 1.5
				_valley_line.points = [position, position + Vector2(1, 0).rotated(valley) * line_length]
	else:
		# Clear valley line when no occlusion
		if _valley_line:
			_valley_line.points = []

	return direction.normalized()


func _isValley(position: Vector2, ray: RayCast2D) -> bool:
	# If the ray is not colliding, refine with a shape cast
	return not ray.is_colliding() and not _circle_intersects(position, position + ray.target_position)

## Receives angle in -pi to pi radians
func _select_valley(position: Vector2, goal: float) -> float:
	# Sort by proximity to goal angle to optimize the search
	var sorted_rays: Array = range(_proximity_rays.size())
	sorted_rays.sort_custom(func(a: int, b: int) -> bool:
		return absf(angle_difference(_ray_angles[a], goal)) < absf(angle_difference(_ray_angles[b], goal))
	)
	
	# Find closest free valley
	var closest_free_idx: int = -1
	var closest_distance: float = INF
	for i in sorted_rays:
		var ray = _proximity_rays[i]
		var distance = absf(angle_difference(_ray_angles[i], goal))

		# Closer to goal and is a valley
		if distance < closest_distance and _isValley(position, ray):
			closest_free_idx = i
			closest_distance = distance

	if closest_free_idx == -1: # No free valley found
		_current_valley_idx = -1
		return INF


	# If we have no current valley, just use the new one
	if _current_valley_idx == -1:
		_current_valley_idx = closest_free_idx
		_current_valley_angle = _ray_angles[closest_free_idx]
	else: # Compare which valley is better (current or new)
		if (
			absi(closest_free_idx - _current_valley_idx) == 1 or 								# Consecutive indexes
			(closest_free_idx == 0 and _current_valley_idx == _proximity_rays.size() - 1) or    # Wrap around valleys
			(closest_free_idx == _proximity_rays.size() - 1 and _current_valley_idx == 0)
		):
			# Consecutive valleys, always switch
			_current_valley_idx = closest_free_idx
			_current_valley_angle = _ray_angles[closest_free_idx]
		else:
			# Not consecutive, apply hysteresis
			var new_angle = _ray_angles[closest_free_idx]
			var improvement = absf(angle_difference(_current_valley_angle, goal)) - absf(angle_difference(new_angle, goal))
			if improvement > VALLEY_HYSTERESIS:
				_current_valley_angle = new_angle
				_current_valley_idx = closest_free_idx

	return _current_valley_angle

## Returns a force vector to flee from nearby walls
func _repel_walls() -> Vector2:
	return _proximity_rays.reduce(
	func(accum: Vector2, ray: RayCast2D) -> Vector2:
		if ray.is_colliding():
			# Flee faster from closer walls
			var p_collision := ray.get_collision_point() - ray.global_position
			var fleeSpeed = (RAY_DISTANCE - p_collision.length()) / RAY_DISTANCE

			accum += fleeSpeed * (-p_collision.normalized())
		return accum
	, Vector2.ZERO)

func _circle_intersects(from: Vector2, to: Vector2) -> bool:
	var physics := World.get_world_2d().direct_space_state

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = _pathfinder_shape
	query.collision_mask = World.GROUND_COLLISION_MASK

	query.transform = Transform2D.IDENTITY
	query.transform.origin = from
	query.motion = to - from

	var result = physics.intersect_shape(query)

	return not result.is_empty()

func _enable_rays() -> void:
	for ray in _proximity_rays:
		ray.enabled = true

func _disable_rays() -> void:
	for ray in _proximity_rays:
		ray.enabled = false

var _proximity_rays: Array[RayCast2D] = [] ## Rays used to detect nearby walls
var _ray_angles: PackedFloat32Array
var _current_valley_angle: float = INF
var _current_valley_idx: int = -1

var _pathfinder_shape: CircleShape2D = CircleShape2D.new()
var _collision_detection: Area2D
var _collision_shape: CollisionShape2D

var _valley_line: Line2D = null  # Debug line for valley angle
