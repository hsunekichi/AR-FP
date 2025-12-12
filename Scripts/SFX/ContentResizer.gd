extends Control
var _original_scales: Dictionary[NodePath, Vector2] = {}
var _original_positions: Dictionary[NodePath, Vector2] = {}

func _ready() -> void:
	_store_originals(self)


func _store_originals(node: Node) -> void:
	for child in node.get_children():
		var key = child.get_path()
		# Store scale depending on node type (Node2D vs Control)
		_original_scales[key] = child.scale
		_original_positions[key] = child.position
		
		_store_originals(child)


func rescale_all(factor: Vector2) -> void:
	"""Multiply each child's original scale by `factor`.

	This always uses the stored original scale, so calling this multiple
	times with different factors does not accumulate errors.
	"""
	for child in get_children():
		_apply_scale_recursive(child, factor)


func _apply_scale_recursive(node: Node, factor: Vector2) -> void:
	var key = node.get_path()
	# Apply scale using stored originals (handles Node2D and Control)
	if _original_scales.has(key):
		node.scale = _original_scales[key] * factor
		
	# Also scale distance from relative origin by the same factor
	if _original_positions.has(key):
		node.position = _original_positions[key] * factor
		
	for c in node.get_children():
		_apply_scale_recursive(c, factor)


func reset_to_original() -> void:
	"""Reset all children back to their original scales."""
	rescale_all(Vector2.ONE)
