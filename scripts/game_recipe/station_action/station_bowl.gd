
# ═══════════════════════════════════════════════════════════════════
# StationBowl — Bol
# Mains pleines → mettre_dans_bol (ou tremper)
# Mains vides   → mélanger
# Un seul poste pour les deux actions.
# ═══════════════════════════════════════════════════════════════════
 
class_name StationBowl
extends StationBase
 
var contents: Array[String] = []
 
 
func _ready() -> void:
	super._ready()
	station_id = "BOWL"
	station_label = "Bol"
	consumes_ingredient = true
	action_duration = 0.0
 
 
func show_prompt(show_bool: bool) -> void:
	if prompt_label:
		prompt_label.visible = show_bool
		prompt_label.text = "[E] Ajouter / Mélanger" if not contents.is_empty() else "[E] Ajouter au bol"
 
 
func try_interact(ingredient_in_hand: String) -> Dictionary:
	if is_busy:
		return { "success": false, "message": "En cours…" }
 
	# ── Mains vides → mélanger ────────────────────────────────────────
	if ingredient_in_hand == "":
		if contents.is_empty():
			return { "success": false, "message": "Le bol est vide !" }
		accepted_action = "mélanger"
		action_duration = 1.5
		_start_timed_action("")
		return {
			"success": true,
			"action_id": "mélanger",
			"station_id": station_id,
			"consumes_ingredient": false,
			"produces_ingredient": "",
			"message": "Mélange en cours…"
		}
 
	# ── Mains pleines → ajouter (ou tremper si pain de mie) ───────────
	var action := "mettre_dans_bol"
	if ingredient_in_hand == "pain_de_mie" and contents.has("oeufs"):
		action = "tremper"
 
	accepted_action = action
	action_duration = 0.0
	contents.append(ingredient_in_hand)
	_update_visual()
	emit_signal("action_completed", station_id, action, "")
 
	return {
		"success": true,
		"action_id": action,
		"station_id": station_id,
		"consumes_ingredient": true,
		"produces_ingredient": "",
		"message": "Ajouté au bol !"
	}
 
 
func _update_visual() -> void:
	if prompt_label:
		prompt_label.text = "Bol : %s" % ", ".join(contents) if not contents.is_empty() else "[E] Ajouter au bol"
 
 
func clear() -> void:
	contents.clear()
	_update_visual()
 
 
func get_contents() -> Array[String]:
	return contents.duplicate()
 
 
