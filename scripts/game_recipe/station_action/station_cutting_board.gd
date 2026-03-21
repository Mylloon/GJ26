
# ═══════════════════════════════════════════════════════════════════
# station_cutting_board.gd — Planche à découper (couper)
# ═══════════════════════════════════════════════════════════════════

class_name StationCuttingBoard
extends StationBase

const CUTTABLE: Dictionary = {
	"chocolat":    "chocolat",
	"fraise":      "fraise",
	"beurre":      "beurre",
	"pain_de_mie": "pain_de_mie",
}


func _ready() -> void:
	super._ready()
	station_id = "CUTTING_BOARD"
	station_label = "Planche"
	accepted_action = "couper"
	consumes_ingredient = true
	action_duration = 1.2


func try_interact(ingredient_in_hand: String) -> Dictionary:
	if is_busy:
		return { "success": false, "message": "En cours…" }

	if ingredient_in_hand == "":
		return { "success": false, "message": "Rien à couper !" }

	if ingredient_in_hand not in CUTTABLE:
		return { "success": false, "message": "On ne peut pas couper ça !" }

	produced_ingredient = CUTTABLE[ingredient_in_hand]
	_start_timed_action(ingredient_in_hand)

	return {
		"success": true,
		"action_id": "couper",
		"station_id": station_id,
		"consumes_ingredient": consumes_ingredient,
		"produces_ingredient": produced_ingredient,
		"message": "Découpe en cours…"
	}
