extends ColorRect

var droite = true
var min_bar = 445
var max_bar = 790
var speed = 400


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if position.x <= max_bar and droite == true:
		position += Vector2(1, 0) * speed * delta
		if position.x >= max_bar:
			droite = false
	elif position.x >= min_bar and droite == false:
		position -= Vector2(1, 0) * speed * delta
		if position.x <= min_bar:
			droite = true

	if Input.is_action_just_pressed("left_click"):
		if position.x < 710 and position.x > 655:
			Context.return_to_previous(true)
			print(true)
		else:
			print(false)
