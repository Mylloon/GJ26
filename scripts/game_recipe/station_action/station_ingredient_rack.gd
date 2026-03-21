class_name StationIngredientRack
extends StationBase


@export var available_ingredients: Array[String] = ["farine","beurre","oeufs","sucre","lait","levure","sel","chocolat","matcha","café_moulu","crème","vanille","pépites_chocolat","amandes","fraise","mangue","sirop_vanille","sirop_fraise","sirop_mangue","cannelle","pain_de_mie"]

# Référence au joueur — assigner depuis la scène principale
@onready var player_ref: Node = $"../../../../../../Player/CharacterBody3D"

# Référence interne au menu, résolue au premier interact
var _menu: Node = null

signal ingredient_selected(ingredient_id: String)


func _ready() -> void:
	super._ready()
	station_id = "INGREDIENT_RACK"
	station_label = "Étagère"
	accepted_action = ""
	consumes_ingredient = false
	action_duration = 0.0


# ── Résolution paresseuse du menu ─────────────────────────────────────────
# Cherche le menu dans le groupe "ingredient_menu" — pas besoin d'appel externe
"""

@export var menu_node_path: NodePath = NodePath("../../../../../IngredientMenu")
@onready var ingredient_menu = get_node_or_null(menu_node_path)
"""
func _get_menu() -> Node:
	if _menu:
		return _menu
	var nodes := get_tree().get_nodes_in_group("ingredient_menu")
	if nodes.is_empty():
		push_error("[StationIngredientRack] Aucun nœud dans le groupe \'ingredient_menu\'.")
		return null
	_menu = nodes[0]
	if not _menu.ingredient_chosen.is_connected(_on_ingredient_chosen):
		_menu.ingredient_chosen.connect(_on_ingredient_chosen)
	return _menu


# ── Surcharge de try_interact ──────────────────────────────────────────────

func try_interact(ingredient_in_hand: String) -> Dictionary:
	if ingredient_in_hand != "":
		return { "success": false, "message": "Mains pleines !" }

	if available_ingredients.is_empty():
		return { "success": false, "message": "Étagère vide !" }

	var menu := _get_menu()
	if not menu:
		return { "success": false, "message": "Erreur menu." }

	menu.open(available_ingredients, station_label)
	return { "success": false, "message": "", "reason": "menu_opening" }


# ── Réception du choix ─────────────────────────────────────────────────────

func _on_ingredient_chosen(ingredient_id: String) -> void:
	emit_signal("ingredient_selected", ingredient_id)
	if player_ref:
		player_ref.receive_ingredient(ingredient_id)
