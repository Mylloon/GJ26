extends Control

@export var animated_sprite_2d: AnimatedSprite2D

signal animation_start


func _ready() -> void:
	reset_animation()


func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite_2d.get_frame() > 0:
		animation_start.emit()


func reset_animation() -> void:
	animated_sprite_2d.set_frame_and_progress(0, 0.0)
	animated_sprite_2d.play()
