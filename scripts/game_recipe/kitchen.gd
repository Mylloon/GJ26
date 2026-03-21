# kitchen.gd
# Script de la scène principale kitchen.tscn
# Orchestre la boucle : commande → recette → validation → nouvelle commande
#
# Chemin : res://scripts/kitchen.gd

extends Node3D

# ── Références aux noeuds ──────────────────────────────────────────────────
@onready var player:             CharacterBody3D = $Player/CharacterBody3D
@onready var hud:                CanvasLayer     = $HUD
@onready var hud_recipe:         CanvasLayer     = $HUDRecipe
@onready var interaction_popup:  CanvasLayer     = $Player/CharacterBody3D/InteractionPopup
@onready var ingredient_menu:    CanvasLayer     = $IngredientMenu

# ── Paramètres de gameplay ─────────────────────────────────────────────────
# Difficulté de la prochaine recette (peut évoluer au fil des commandes)
var current_difficulty: String = "facile"
var recipes_completed: int = 0


func _ready() -> void:
	_connect_nodes()
	_start_next_order()


# ── Connexions ─────────────────────────────────────────────────────────────

func _connect_nodes() -> void:
	# Player → GameManager
	GameManager.player = player
	player.action_performed.connect(GameManager.on_action_performed)

	# Player → HUD ingrédient en main
	hud.set_player(player)

	# Player → popup d'interaction
	interaction_popup.set_player(player)
	player.interaction_popup = interaction_popup

	# GameManager → HUD recette
	GameManager.recipe_loaded.connect(hud_recipe.on_recipe_loaded)
	GameManager.step_validated.connect(hud_recipe.on_step_validated)
	GameManager.step_ingredient_added.connect(hud_recipe.on_step_ingredient_added)
	GameManager.step_reset.connect(hud_recipe.on_step_reset)
	GameManager.recipe_completed.connect(_on_recipe_completed)

	# Connecter player_ref sur tous les racks de la scène
	for rack in get_tree().get_nodes_in_group("station"):
		if rack is StationIngredientRack:
			rack.player_ref = player


# ── Boucle de gameplay ─────────────────────────────────────────────────────

func _start_next_order() -> void:
	# Progresser la difficulté tous les 3 recettes
	if recipes_completed >= 3 and current_difficulty == "facile":
		current_difficulty = "moyen"
	elif recipes_completed >= 7 and current_difficulty == "moyen":
		current_difficulty = "difficile"

	var recipe = RecipeLoader.get_random_recipe(current_difficulty)
	if recipe.is_empty():
		push_error("[Kitchen] Aucune recette trouvée pour la difficulté : %s" % current_difficulty)
		return

	# Mélanger les étapes affichées (thème emmêlé)
	# Les étapes réelles restent dans l'ordre dans GameManager
	GameManager.load_recipe(recipe)


func _on_recipe_completed(recipe_id: String) -> void:
	recipes_completed += 1
	print("[Kitchen] Recette terminée : %s (%d au total)" % [recipe_id, recipes_completed])

	# Petite pause avant la prochaine commande
	await get_tree().create_timer(2.0).timeout
	_start_next_order()
