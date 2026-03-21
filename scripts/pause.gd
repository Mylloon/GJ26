extends Control

@export var background: TextureRect
var _pending_background: ImageTexture

func set_background(texture: ImageTexture) -> void:
	_pending_background = texture

func _ready() -> void:
	if _pending_background:
		background.texture = _pending_background
