
# recipe_loader.gd
# Place tes JSON dans res://data/recettes_jeu.json et res://data/actions_jeu.json

extends Node

var recipes:     Dictionary = {}   # { "cookie_chocolat": { ...recette... }, … }
var actions:     Dictionary = {}   # { "couper": { label, icone, ... }, … }
var ingredients: Dictionary = {}   # { "farine": { label, emoji }, … }
var meta:        Dictionary = {}   # postes, etc.

const RECIPES_PATH := "res://assets/data/recettes_jeu.json"
const ACTIONS_PATH := "res://assets/data/actions_jeu.json"
const INGREDIENTS_PATH := "res://assets/data/ingredients_labels.json"


func _ready() -> void:
	_load_recipes()
	_load_actions()
	_load_ingredients()


# ── Chargement ─────────────────────────────────────────────────────────────

func _load_recipes() -> void:
	var file := FileAccess.open(RECIPES_PATH, FileAccess.READ)
	if not file:
		push_error("[RecipeLoader] Impossible d'ouvrir %s" % RECIPES_PATH)
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("[RecipeLoader] Erreur JSON recettes : %s" % json.get_error_message())
		return

	var data: Dictionary = json.get_data()
	meta = data.get("meta", {})

	for recipe in data.get("recettes", []):
		var id: String = recipe.get("id", "")
		if id != "":
			recipes[id] = recipe

	print("[RecipeLoader] %d recettes chargées." % recipes.size())


func _load_actions() -> void:
	var file := FileAccess.open(ACTIONS_PATH, FileAccess.READ)
	if not file:
		push_error("[RecipeLoader] Impossible d'ouvrir %s" % ACTIONS_PATH)
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("[RecipeLoader] Erreur JSON actions : %s" % json.get_error_message())
		return

	var data: Dictionary = json.get_data()
	for action in data.get("actions", []):
		var id: String = action.get("id", "")
		if id != "":
			actions[id] = action

	print("[RecipeLoader] %d actions chargées." % actions.size())


func _load_ingredients() -> void:
	var file := FileAccess.open(INGREDIENTS_PATH, FileAccess.READ)
	if not file:
		push_error("[RecipeLoader] Impossible d'ouvrir %s" % INGREDIENTS_PATH)
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("[RecipeLoader] Erreur JSON ingrédients : %s" % json.get_error_message())
		return

	for ing in json.get_data().get("ingredients", []):
		var id: String = ing.get("id", "")
		if id != "":
			ingredients[id] = ing

	print("[RecipeLoader] %d ingrédients chargés." % ingredients.size())


# ── API publique ───────────────────────────────────────────────────────────

func get_recipe(id: String) -> Dictionary:
	return recipes.get(id, {})


func get_all_recipes() -> Array:
	return recipes.values()


func get_recipes_by_difficulty(difficulty: String) -> Array:
	return recipes.values().filter(func(r): return r.get("difficulte", "") == difficulty)


func get_action(id: String) -> Dictionary:
	return actions.get(id, {})


func get_action_label(id: String) -> String:
	return actions.get(id, {}).get("label", id)


func get_action_icon(id: String) -> String:
	return actions.get(id, {}).get("icone", "?")


func get_random_recipe(difficulty: String = "") -> Dictionary:
	var pool: Array
	if difficulty == "":
		pool = recipes.values()
	else:
		pool = get_recipes_by_difficulty(difficulty)

	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()]


# Retourne les étapes avec les labels/icônes résolus (pratique pour l'UI)
func get_steps_with_labels(recipe_id: String) -> Array:
	var recipe := get_recipe(recipe_id)
	if recipe.is_empty():
		return []

	var result := []
	for step in recipe.get("etapes", []):
		var action_id: String = step.get("action", "")
		var action_data := get_action(action_id)
		result.append({
			"ordre":       step.get("ordre", 0),
			"ingredients": step.get("ingredients", []),
			"action_id":   action_id,
			"action_label": action_data.get("label", action_id),
			"action_icon":  action_data.get("icone", "?"),
			"poste":        step.get("poste", ""),
			"note":         step.get("note", ""),
		})

	return result

func get_ingredient(id: String) -> Dictionary:
	return ingredients.get(id, {})


func get_ingredient_label(id: String) -> String:
	return ingredients.get(id, {}).get("label", id)


func get_ingredient_emoji(id: String) -> String:
	return ingredients.get(id, {}).get("emoji", "?")

"""
func get_ingredient(id: String) -> Dictionary:
	return ingredients.get(id, {})


func get_ingredient_label(id: String) -> String:
	return ingredients.get(id, {}).get("label", id)


func get_ingredient_emoji(id: String) -> String:
	return ingredients.get(id, {}).get("emoji", "?")
"""
