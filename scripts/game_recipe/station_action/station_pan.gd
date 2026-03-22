

# ═══════════════════════════════════════════════════════════════════
# station_pan.gd — Poêle (cuire_poele)
# ═══════════════════════════════════════════════════════════════════

class_name StationPan
extends StationBase


func _ready() -> void:
	super._ready()
	station_id = "PAN"
	station_label = "Poêle"
	accepted_action = "cuire_poele"
	consumes_ingredient = false
	# station_mini_game = ""

func try_interact(ingredient_in_hand: String) -> Dictionary:
	playMiniGame(station_mini_game)
	return {
		"success": true,
		"action_id": "cuire_poele",
		"station_id": station_id,
		"consumes_ingredient": false,
		"produces_ingredient": "",
		"message": "Cuisson en cours…"
	}
