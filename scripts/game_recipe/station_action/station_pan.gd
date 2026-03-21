

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
	action_duration = 2.0


func try_interact(ingredient_in_hand: String) -> Dictionary:
	if is_busy:
		return { "success": false, "message": "Déjà en cuisson !" }

	_start_timed_action("")
	return {
		"success": true,
		"action_id": "cuire_poele",
		"station_id": station_id,
		"consumes_ingredient": false,
		"produces_ingredient": "",
		"message": "Cuisson en cours…"
	}
