extends Control


func _on_quit_pressed() -> void:
	Context.exit_game()


func _on_settings_pressed() -> void:
	Context.switch_scene("res://scenes/settings.tscn")
