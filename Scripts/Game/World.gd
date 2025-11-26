extends Node2D

const ppu: float = 64.0 # pixels per unit 
var raycast: RayCast2D
const GROUND_COLLISION_MASK: int = 1
var verbose: bool = false

var hud_scene: PackedScene = preload("res://Scenes/HUD.tscn")
var main_menu_scene: PackedScene = preload("res://Scenes/MainMenu.tscn")
var maze_scene: PackedScene = preload("res://Scenes/Maze.tscn")
var debug_scene: PackedScene = preload("res://Scenes/Debug.tscn")

var menu_active: bool = false

@export var win_screen_path: StringName = "res://Art/Screens/WinScreen.png"
@export var main_menu_scene_path: StringName = "res://Scenes/MainMenu.tscn"
var win_node: TextureRect

var sugar_rush_alpha: float = 0.31  # Target alpha value
var sugar_rush_fade_duration: float = 0.3  # Duration of the fade-in effect in seconds

var HUD: HUDcontroller

signal game_finished


func _ready() -> void:
	# Set clear color
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 1))

	raycast = RayCast2D.new()
	add_child(raycast)
	raycast.enabled = false
	raycast.collision_mask = GROUND_COLLISION_MASK
	raycast.hit_from_inside = true
	
	HUD = hud_scene.instantiate()
	add_child(HUD)

	win_node = TextureRect.new()
	win_node.texture = load(win_screen_path)
	win_node.visible = false
	HUD.add_child(win_node)

	# Await until the game is done loading
	await get_tree().process_frame

	Player.disable_input()
	Player.visible = false

	menu_active = true
	load_maze()	

func ray_intersects_ground(from: Vector2, to: Vector2) -> bool:
	raycast.global_position = from
	raycast.target_position = to - from  # target_position is RELATIVE to the raycast position
	raycast.force_raycast_update()

	return raycast.is_colliding()

func log(...msg: Array) -> void:
	if verbose:
		print(msg)

func teleport_player(p: Vector2) -> void:
	Player.global_position = p

	# Move the camera immediately to the spawn point
	var mainCamera = get_viewport().get_camera_2d()
	mainCamera.global_position = Player.global_position
	mainCamera.reset_smoothing()

func load_menu() -> void:
	await HUD.enable_transition()

	var menu: Node = main_menu_scene.instantiate()
	HUD.add_menu(menu)

	await HUD.disable_transition()

	menu_active = true

func load_maze() -> void:
	if not menu_active:
		return
	menu_active = false

	await HUD.enable_transition()

	# Remove menu
	HUD.remove_menu()

	# Load maze
	var maze: Node = maze_scene.instantiate()
	maze.name = "Maze"
	add_child(maze)

	# Enable player input and make visible
	Player.enable_input()
	Player.visible = true

	await HUD.disable_transition()

func get_maze() -> Node:
	return get_node_or_null("Maze")

func load_debug() -> void:
	if not menu_active:
		return
	menu_active = false

	await HUD.enable_transition()

	# Remove menu
	HUD.remove_menu()

	# Load demo maze
	var scene: Node = debug_scene.instantiate()
	add_child(scene)

	# Enable player input and make visible
	Player.enable_input()
	Player.visible = true

	await HUD.disable_transition()

func game_completed() -> void:
	# Show win screen
	game_finished.emit()

	await HUD.enable_transition()
	win_node.visible = true
	get_node("Maze").queue_free()
	await HUD.disable_transition()

func activate_sugar_rush_effect() -> void:
	var effect = HUD.get_node("SugarRushEffect")
	var mat = effect.material as ShaderMaterial
	
	effect.visible = true

	# Remove current alpha
	mat.set_shader_parameter("alpha", 0.0)
	
	# Fade in from 0 to sugar_rush_alpha
	var tween = create_tween()
	tween.tween_property(mat, "shader_parameter/alpha", sugar_rush_alpha, sugar_rush_fade_duration)

func deactivate_sugar_rush_effect() -> void:
	var effect = HUD.get_node("SugarRushEffect")
	var mat = effect.material as ShaderMaterial
	
	# Fade out from current alpha to 0
	var tween = create_tween()
	tween.tween_property(mat, "shader_parameter/alpha", 0.0, sugar_rush_fade_duration)
	await tween.finished
	
	effect.visible = false
