 
# ═══════════════════════════════════════════════════════════════════
# StationExpressoSteamer — Machine expresso + buse vapeur fusionnées
#   lait en main      → mousser_lait  (produit : lait_mousse)
#   café_moulu en main → faire_expresso (produit : expresso)
#   mains vides       → chauffer_lait si lait déjà posé, sinon erreur
# ═══════════════════════════════════════════════════════════════════
 
class_name StationExpressoSteamer
extends StationBase
 
# Dernier ingrédient déposé sur le poste (pour chauffer_lait mains vides)
var _staged_ingredient: String = ""
 
 
func _ready() -> void:
	super._ready()
	station_id = "ESPRESSO_STEAMER"
	station_label = "Expresso / Vapeur"
	consumes_ingredient = true
	# station_mini_game = ""
 
 
func show_prompt(show: bool) -> void:
	if prompt_label:
		prompt_label.visible = show
		prompt_label.text = "[E] Café → expresso  |  Lait → vapeur"
 
 
func try_interact(ingredient_in_hand: String) -> Dictionary:
 
	match ingredient_in_hand:
 
		"café_moulu":
			# Extraction expresso
			accepted_action = "faire_expresso"
			produced_ingredient = "expresso"
			
			playMiniGame(station_mini_game)
			return {
				"success": true,
				"action_id": "faire_expresso",
				"station_id": station_id,
				"consumes_ingredient": consumes_ingredient,
				"produces_ingredient": "expresso",
				"message": "Extraction…"
			}
 
		"lait":
			# Mousser le lait directement
			accepted_action = "mousser_lait"
			produced_ingredient = "lait_mousse"
			
			playMiniGame(station_mini_game)
			return {
				"success": true,
				"action_id": "mousser_lait",
				"station_id": station_id,
				"consumes_ingredient": consumes_ingredient,
				"produces_ingredient": "lait_mousse",
				"message": "Lait en mousse…"
			}
 
		"":
			return { "success": false, "message": "Café ou lait requis !" }
 
		_:
			return { "success": false, "message": "Café ou lait requis !" }
 
