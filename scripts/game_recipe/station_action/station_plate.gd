# ═══════════════════════════════════════════════════════════════════
# station_plate.gd — Assiette (dresser)
# ═══════════════════════════════════════════════════════════════════

class_name StationPlate
extends StationBase


func _ready() -> void:
	super._ready()
	station_id = "PLATE"
	station_label = "Assiette"
	accepted_action = "dresser"
	consumes_ingredient = true
	action_duration = 0.0


func try_interact(ingredient_in_hand: String) -> Dictionary:
	if ingredient_in_hand == "":
		return { "success": false, "message": "Rien à dresser !" }

	emit_signal("action_completed", station_id, "dresser", "")
	return {
		"success": true,
		"action_id": "dresser",
		"station_id": station_id,
		"consumes_ingredient": consumes_ingredient,
		"produces_ingredient": "",
		"message": "Dressé !"
	}
