extends Control

@export var animation_player: AnimationPlayer

@export var background: TextureRect
var _pending_background: ImageTexture

func set_background(texture: ImageTexture) -> void:
	_pending_background = texture

func _ready() -> void:
	if _pending_background:
		background.texture = _pending_background
	animation_player.play("blur")

func _input(event):
	if event.is_action_pressed("pause"):
		_on_resume_pressed()

func _on_resume_pressed() -> void:
	AudioHandler.disable_pause_filter()
	Context.return_to_previous(true)
