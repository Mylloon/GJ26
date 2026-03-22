# mini_game_cutting_texture.gd
# Chemin : res://scripts/game_recipe/minigame/mini_game_cutting_texture.gd

extends TextureProgressBar

@export var fill_speed:         float = 20.0
@export var drain_speed:        float = 20.0


var _last_mouse: Vector2


func _ready() -> void:
	position = Vector2(950, 210)
	min_value   = 0.0
	max_value   = 100.0
	value       = 0.0
	_last_mouse = _root_mouse()


func _root_mouse() -> Vector2:
	return get_tree().root.get_viewport().get_mouse_position()



func _process(delta: float) -> void:
	if value >= 100:
			Context.return_to_previous(true)

	var mouse   := _root_mouse()
	var dist    := mouse.distance_to(_last_mouse)
	_last_mouse  = mouse
	value +=  (fill_speed*(dist/50) - drain_speed) * delta * 10
