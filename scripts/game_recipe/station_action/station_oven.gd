

# ═══════════════════════════════════════════════════════════════════
# station_oven.gd — Four (mettre_au_four)
# ═══════════════════════════════════════════════════════════════════

class_name StationOven
extends StationBase


func _ready() -> void:
	super._ready()
	station_id = "OVEN"
	station_label = "Four"
	accepted_action = "mettre_au_four"
	consumes_ingredient = false
	action_duration = 3.0


func try_interact(ingredient_in_hand: String) -> Dictionary:
	if is_busy:
		return { "success": false, "message": "Déjà en cuisson !" }

	_start_timed_action("")
	return {
		"success": true,
		"action_id": "mettre_au_four",
		"station_id": station_id,
		"consumes_ingredient": false,
		"produces_ingredient": "",
		"message": "Au four !"
	}
