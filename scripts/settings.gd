extends VBoxContainer

@onready var volume_bar = $Volume/Slider
@onready var volume_info = $Volume/Info
@onready var volume_top_tex = $Volume/Slider/Top


func _ready():
	volume_bar.value = AudioHandler.get_volume() * 100
	_update_info(volume_bar.value)


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_return_button_pressed()


func _on_slider_value_changed(value: float) -> void:
	AudioHandler.set_volume(value / 100)
	_update_info(value)


func _on_slider_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		_save_volume()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var ratio = 1.0 - clampf(event.position.y / volume_bar.size.y, 0.0, 1.0)
		volume_bar.set_value(ratio * 100)


func _save_volume() -> void:
	(
		ConfigHandler
		. save_setting(
			ConfigHandler.SETTINGS.audio.name,
			ConfigHandler.SETTINGS.audio.elements.master.name,
			volume_bar.value,
		)
	)


func _update_info(value: float) -> void:
	volume_info.set_text(str(value).pad_decimals(0) + "%")

	# Move top cap
	var ratio = clampf(1.0 - value / 100.0, 0.04, 0.93)  # INFO: dégeu les valeures hardcodées
	volume_top_tex.position.y = ratio * volume_bar.size.y - volume_top_tex.size.y / 2.0


func _on_return_button_pressed() -> void:
	Context.return_to_previous()
