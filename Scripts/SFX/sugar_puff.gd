extends AnimatedSprite2D

signal cloudAtMaxSize

func _process(_delta: float) -> void:
    if frame == 2:
        cloudAtMaxSize.emit()

