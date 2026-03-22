extends TextureProgressBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = Vector2(850, 210)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	value -= 100 * delta
	if Input.is_action_just_pressed("left_click"):
		value += 25
		if value >= 100:
			Context.return_to_previous(true)
