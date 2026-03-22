# ═══════════════════════════════════════════════════════════════════
# station_oven.gd — Four (mettre_au_four)
# ═══════════════════════════════════════════════════════════════════

class_name sq
extends StationBase


func _ready() -> void:
	super._ready()
	station_id = "OVEN"
	station_label = "Four"
	accepted_action = "mettre_au_four"
	consumes_ingredient = false


func try_interact(ingredient_in_hand: String) -> Dictionary:
	playMiniGame("res://scenes/minigame/minigame_heat_up.tscn")
	return {
		"success": true,
		"action_id": "mettre_au_four",
		"station_id": station_id,
		"consumes_ingredient": false,
		"produces_ingredient": "",
		"message": "Au four !"
	}
