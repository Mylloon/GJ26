extends Node

var config = ConfigFile.new()
const SETTINGS_FILE_PATH = "user://settings.ini"

const SETTINGS = {
	"audio": {"name": "audio", "elements": {"master": {"name": "master", "default": 67.0}}}
}


func _ready():
	if !FileAccess.file_exists(SETTINGS_FILE_PATH):
		for cat in SETTINGS.values():
			for element in cat.elements.values():
				config.set_value(cat.name, element.name, element.default)
		config.save(SETTINGS_FILE_PATH)
	else:
		config.load(SETTINGS_FILE_PATH)
	apply_config()


func save_setting(cat, key, value):
	config.set_value(cat, key, value)
	config.save(SETTINGS_FILE_PATH)


func apply_config():
	# Audio
	AudioHandler.set_volume(
		(
			config.get_value(
				ConfigHandler.SETTINGS.audio.name, ConfigHandler.SETTINGS.audio.elements.master.name
			)
			/ 100
		)
	)
