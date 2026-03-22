extends AudioStreamPlayer

const pause_filter = 0

@onready var index = AudioServer.get_bus_index(bus)

const main_music = preload("res://assets/audio/background.mp3")


func _ready() -> void:
	# Mute volume on startup, will be overrided by the config
	set_volume(0.0)

	var filter := AudioEffectLowPassFilter.new()
	filter.cutoff_hz = 300.0

	AudioServer.add_bus_effect(index, filter, pause_filter)


## Play an audio stream.[br][br]
## Example usage: When the node enters the scene tree for the first time.
func _play_music(music: AudioStream) -> void:
	if stream == music:
		seek(0.)  # redémarre le son
		return

	stream = music
	if !playing:
		play()


func play_main_music() -> void:
	_play_music(main_music)
	pass


func play_music_menu() -> void:
	# _play_music(menu_music)
	pass


## Change the volume db
func set_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(index, linear_to_db(value))


## Get the volume db
func get_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(index))


## Disable a sound filter
func disable_pause_filter() -> void:
	AudioServer.set_bus_effect_enabled(index, pause_filter, false)


## Enable a sound filter
func enable_pause_filter() -> void:
	AudioServer.set_bus_effect_enabled(index, pause_filter, true)
