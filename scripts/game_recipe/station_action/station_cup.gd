# ═══════════════════════════════════════════════════════════════════
# station_cup.gd — Tasse
#   verser    : mains pleines → ajoute l'ingrédient tenu dans la tasse
#   assembler : mains vides   → assemble les préparations dans la tasse
# ═══════════════════════════════════════════════════════════════════

class_name StationCup
extends StationBase

var cup_contents: Array[String] = []


func _ready() -> void:
	super._ready()
	station_id          = "CUP"
	station_label       = "Tasse"
	accepted_action     = "verser"
	consumes_ingredient = true


func show_prompt(show: bool) -> void:
	if prompt_label:
		prompt_label.visible = show
		prompt_label.text    = "[E] Verser / Assembler"


func try_interact(ingredient_in_hand: String) -> Dictionary:
	# ── Mains vides → assembler ──────────────────────────────────────
	if ingredient_in_hand == "":
		emit_signal("action_completed", station_id, "assembler", "")
		return {
			"success":              true,
			"action_id":            "assembler",
			"station_id":           station_id,
			"consumes_ingredient":  false,
			"produces_ingredient":  "",
			"message":              "Assemblé !"
		}

	# ── Mains pleines → verser l'ingrédient ─────────────────────────
	cup_contents.append(ingredient_in_hand)
	emit_signal("action_completed", station_id, "verser", "")

	return {
		"success":              true,
		"action_id":            "verser",
		"station_id":           station_id,
		"consumes_ingredient":  true,
		"produces_ingredient":  "",
		"message":              "Versé !"
	}


func clear() -> void:
	cup_contents.clear()


func get_contents() -> Array[String]:
	return cup_contents.duplicate()
