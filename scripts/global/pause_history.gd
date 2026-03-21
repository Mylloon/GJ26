extends Node

## Current scene loaded
var _current_scene_path
## Stack of previous scenes
var _history := []
## Suspended scenes
var _paused_scenes := {}


func _ready() -> void:
	# initialize the scene path with the current one
	_current_scene_path = get_tree().current_scene.scene_file_path

## Switch to a different scene.
## If it's a pause, we suspend the current scene and store, so we can save the current state.
func switch_scene(path: NodePath, pause: ImageTexture = null) -> Error:
	_history.push_back(_current_scene_path)

	if pause:
		var current_scene = get_tree().get_current_scene()
		current_scene.process_mode = Node.PROCESS_MODE_DISABLED
		_paused_scenes[_current_scene_path] = current_scene
		current_scene.get_parent().remove_child(current_scene)

		var new_scene = load(path).instantiate()
		
		if new_scene.has_method("set_background"):
			await new_scene.set_background(pause)
		else:
			print_debug("Pause could have method: set_background(ImageTexture) -> void")
		
		get_tree().root.add_child(new_scene)
		get_tree().set_current_scene(new_scene)
		_current_scene_path = path
		return Error.OK

	_current_scene_path = path
	return get_tree().change_scene_to_file(path)


## Return to previous screen.
## For paused scenes, we overwrite the current one to restore the initial state.
func return_to_previous(was_paused: bool = false) -> Error:
	if _history.is_empty():
		return Error.ERR_DOES_NOT_EXIST

	_current_scene_path = _history.pop_back()

	if was_paused:
		var current_scene = get_tree().current_scene
		current_scene.queue_free()

		var paused_scene = _paused_scenes[_current_scene_path]
		get_tree().root.add_child(paused_scene)
		get_tree().set_current_scene(paused_scene)
		_paused_scenes.erase(_current_scene_path)
		paused_scene.process_mode = Node.PROCESS_MODE_ALWAYS
		return Error.OK

	return get_tree().change_scene_to_file(_current_scene_path)


## Clear full history.[br][br]
## Example usage: Going from pause menu to main menu
func clear_history() -> void:
	_history.clear()
	_paused_scenes.clear()


## Quit the game properly.
func exit_game() -> void:
	# TODO: If web: don't crash just ignore
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
