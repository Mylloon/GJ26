extends GridContainer

@onready var volume_slider = $Volume/HSlider
@onready var volume_info = $Volume/Info


func _ready():
	volume_slider.set_value(AudioHandler.get_volume() * 100)


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_return_button_pressed()


func _on_volume_slider_value_changed(value: float) -> void:
	AudioHandler.set_volume(value / 100)
	volume_info.set_text(str(value).pad_decimals(0) + "%")


func _on_volume_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		(
			ConfigHandler
			. save_setting(
				ConfigHandler.SETTINGS.audio.name,
				ConfigHandler.SETTINGS.audio.elements.master.name,
				volume_slider.get_value(),
			)
		)


func _on_return_button_pressed() -> void:
	Context.return_to_previous()
