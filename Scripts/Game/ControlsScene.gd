extends Control

func _ready() -> void:
	$MainMenuButton.pressed.connect(_on_main_menu_button_pressed)

	_on_viewport_size_changed()
	var vp = get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed() -> void:
	$Background.size = get_viewport_rect().size
	
func _on_main_menu_button_pressed() -> void:
	World.load_menu()
	$AudioStreamPlayer2.play()

func _on_main_menu_button_mouse_entered() -> void:
	$AudioStreamPlayer.play()
