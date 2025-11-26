extends ColorRect

@export var alpha: float = 0.31  # Target alpha value
@export var duration: float = 0.3  # Duration of the fade-in effect in seconds

func enable() -> void:
    var mat = material as ShaderMaterial

    visible = true

    # Remove current alpha
    mat.set_shader_parameter("alpha", 0.0)

    # Fade in from 0 to sugar_rush_alpha
    var tween = create_tween()
    tween.tween_property(mat, "shader_parameter/alpha", alpha, duration)

func disable() -> void:
    var mat = material as ShaderMaterial

    # Fade out from current alpha to 0
    var tween = create_tween()
    tween.tween_property(mat, "shader_parameter/alpha", 0.0, duration)  
    tween.finished.connect(func(): visible = false, CONNECT_ONE_SHOT)