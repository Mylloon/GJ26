# game_manager.gd
# Autoload (Singleton) — à ajouter dans Projet > Paramètres > Autoload
# Nom du singleton : GameManager
#
# Reçoit les actions du joueur via le signal action_performed du Player
# et vérifie si elles correspondent à la recette active.

extends Node

# ── Signaux vers l'UI ──────────────────────────────────────────────────────
signal recipe_loaded(recipe: Dictionary)
signal step_validated(step_index: int, success: bool)
signal recipe_completed(recipe_id: String)
signal recipe_failed(reason: String)
signal chaos_triggered(chaos_type: String)
signal controls_inverted_changed(inverted: bool)

# ── État courant ───────────────────────────────────────────────────────────
var current_recipe: Dictionary = {}
var expected_step_index: int = 0  # index de la prochaine étape à valider
var controls_inverted: bool = false

# ── Chaos ─────────────────────────────────────────────────────────────────
@export var chaos_interval_min: float = 8.0
@export var chaos_interval_max: float = 15.0
var chaos_timer: Timer

# ── Référence au joueur ────────────────────────────────────────────────────
var player: Node = null  # assigné depuis la scène principale


func _ready() -> void:
	# Créer le timer de chaos
	chaos_timer = Timer.new()
	chaos_timer.one_shot = true
	chaos_timer.timeout.connect(_trigger_random_chaos)
	add_child(chaos_timer)


# ── Charger une recette ────────────────────────────────────────────────────


func load_recipe(recipe: Dictionary) -> void:
	current_recipe = recipe
	expected_step_index = 0
	emit_signal("recipe_loaded", recipe)
	_schedule_next_chaos()


# ── Recevoir une action du joueur ──────────────────────────────────────────
# Connecter le signal action_performed du Player ici :
# player.action_performed.connect(GameManager.on_action_performed)


func on_action_performed(action_id: String, ingredient: String, station_id: String) -> void:
	if current_recipe.is_empty():
		return

	var steps: Array = current_recipe.get("etapes", [])
	if expected_step_index >= steps.size():
		return

	var expected_step: Dictionary = steps[expected_step_index]
	var valid := _validate_step(expected_step, action_id, ingredient, station_id)

	emit_signal("step_validated", expected_step_index, valid)

	if valid:
		expected_step_index += 1
		if expected_step_index >= steps.size():
			_on_recipe_complete()
	else:
		_on_wrong_step(action_id, station_id)


# ── Validation d'une étape ─────────────────────────────────────────────────


func _validate_step(
	step: Dictionary, action_id: String, ingredient: String, station_id: String
) -> bool:
	var expected_action: String = step.get("action", "")
	var expected_poste: String = step.get("poste", "")
	var expected_ings: Array = step.get("ingredients", [])

	# Vérifier action et poste
	if action_id != expected_action:
		return false
	if station_id != expected_poste:
		return false

	# Vérifier ingrédient si l'étape en exige un
	if expected_ings.size() > 0:
		if ingredient not in expected_ings:
			return false

	return true


# ── Recette terminée ───────────────────────────────────────────────────────


func _on_recipe_complete() -> void:
	emit_signal("recipe_completed", current_recipe.get("id", ""))
	chaos_timer.stop()
	current_recipe = {}
	expected_step_index = 0


# ── Mauvaise étape ─────────────────────────────────────────────────────────


func _on_wrong_step(action_id: String, station_id: String) -> void:
	print("[GameManager] Mauvaise étape : %s sur %s" % [action_id, station_id])
	# Pénalité optionnelle (temps, vie…) gérée ici


# ── Chaos : événements aléatoires ─────────────────────────────────────────


func _schedule_next_chaos() -> void:
	var delay := randf_range(chaos_interval_min, chaos_interval_max)
	chaos_timer.start(delay)


func _trigger_random_chaos() -> void:
	if current_recipe.is_empty():
		return

	var chaos_types := ["invert_controls", "reshuffle_display", "fake_ingredient"]
	var chosen: String = chaos_types[randi() % chaos_types.size()]

	match chosen:
		"invert_controls":
			_toggle_controls_inverted()
		"reshuffle_display":
			emit_signal("chaos_triggered", "reshuffle_display")
		"fake_ingredient":
			emit_signal("chaos_triggered", "fake_ingredient")

	emit_signal("chaos_triggered", chosen)
	_schedule_next_chaos()


func _toggle_controls_inverted() -> void:
	controls_inverted = !controls_inverted
	emit_signal("controls_inverted_changed", controls_inverted)
	if player:
		player.set_controls_inverted(controls_inverted)


# ── API publique ───────────────────────────────────────────────────────────


func get_current_step() -> Dictionary:
	if current_recipe.is_empty():
		return {}
	var steps: Array = current_recipe.get("etapes", [])
	if expected_step_index < steps.size():
		return steps[expected_step_index]
	return {}


func get_progress() -> float:
	if current_recipe.is_empty():
		return 0.0
	var steps: Array = current_recipe.get("etapes", [])
	if steps.is_empty():
		return 0.0
	return float(expected_step_index) / float(steps.size())


func reset() -> void:
	current_recipe = {}
	expected_step_index = 0
	controls_inverted = false
	chaos_timer.stop()
	if player:
		player.set_controls_inverted(false)
