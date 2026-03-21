
# ═══════════════════════════════════════════════════════════════════
# station_cup.gd — Tasse (verser)
# ═══════════════════════════════════════════════════════════════════

class_name StationCup
extends StationBase

var cup_contents: Array[String] = []


func _ready() -> void:
	super._ready()
	station_id = "CUP"
	station_label = "Tasse"
	accepted_action = "verser"
	consumes_ingredient = true
	action_duration = 0.0


func try_interact(ingredient_in_hand: String) -> Dictionary:
	if ingredient_in_hand == "":
		return { "success": false, "message": "Rien à verser !" }

	cup_contents.append(ingredient_in_hand)
	emit_signal("action_completed", station_id, "verser", "")

	return {
		"success": true,
		"action_id": "verser",
		"station_id": station_id,
		"consumes_ingredient": true,
		"produces_ingredient": "",
		"message": "Versé !"
	}


func clear() -> void:
	cup_contents.clear()


func get_contents() -> Array[String]:
	return cup_contents.duplicate()
