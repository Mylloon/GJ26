# station_trash.gd
# Poste "Poubelle" — jette l'ingrédient actuellement en main
# Étend StationBase comme tous les autres postes
#
# Chemin suggéré : res://scripts/game_recipe/station_action/station_trash.gd

class_name StationTrash
extends StationBase


func _ready() -> void:
	super._ready()
	station_id = "TRASH"
	station_label = "Poubelle"
	accepted_action = "jeter"
	consumes_ingredient = true
	action_duration = 0.0


func try_interact(ingredient_in_hand: String) -> Dictionary:
	if ingredient_in_hand == "":
		return { "success": false, "message": "Rien à jeter !" }

	var discarded := ingredient_in_hand
	emit_signal("action_completed", station_id, "jeter", "")

	return {
		"success": true,
		"action_id": "jeter",
		"station_id": station_id,
		"consumes_ingredient": true,
		"produces_ingredient": "",
		"message": "🗑 %s jeté." % RecipeLoader.get_ingredient_label(discarded)
	}
