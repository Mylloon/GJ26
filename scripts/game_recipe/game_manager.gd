# game_manager.gd
# Autoload (Singleton) — à ajouter dans Projet > Paramètres > Autoload
# Nom du singleton : GameManager
#
# Reçoit les actions du joueur via le signal action_performed du Player
# et vérifie si elles correspondent à la recette active.

extends Node

# ── Signaux vers l'UI ──────────────────────────────────────────────────────
signal recipe_loaded(recipe: Dictionary, display_steps: Array)
signal step_validated(step_index: int, display_index: int, success: bool)
signal step_ingredient_added(step_index: int, ingredient_id: String, remaining: int)
signal step_reset()                          # raté → toutes les encoches effacées
signal recipe_completed(recipe_id: String)
signal recipe_failed(reason: String)
signal chaos_triggered(chaos_type: String)
signal controls_inverted_changed(inverted: bool)

# ── État courant ───────────────────────────────────────────────────────────
var current_recipe: Dictionary = {}       # recette avec étapes dans l'ordre ORIGINAL
var display_steps: Array = []             # étapes dans l'ordre SHUFFLÉ pour l'affichage
var display_index_map: Dictionary = {}    # { ordre_original → index_dans_display_steps }
var expected_step_index: int = 0          # index dans l'ordre original
var controls_inverted: bool = false

# Pour les étapes multi-ingrédients : ingrédients restant à apporter
var _pending_ingredients: Array = []

# ── Chaos ─────────────────────────────────────────────────────────────────
@export var chaos_interval_min: float = 8.0
@export var chaos_interval_max: float = 15.0
var chaos_timer: Timer

# ── Référence au joueur ────────────────────────────────────────────────────
var player: Node = null   # assigné depuis la scène principale


func _ready() -> void:
	# Créer le timer de chaos
	print("ready")
	"""
	chaos_timer = Timer.new()
	chaos_timer.one_shot = true
	chaos_timer.timeout.connect(_trigger_random_chaos)
	add_child(chaos_timer)
"""


# ── Charger une recette ────────────────────────────────────────────────────

func load_recipe(recipe: Dictionary) -> void:
	current_recipe = recipe
	expected_step_index = 0
	_pending_ingredients.clear()

	# Générer l'ordre d'affichage shufflé — indépendant de l'ordre de validation
	var steps: Array = recipe.get("etapes", []).duplicate()
	display_steps = _shuffle_array(steps)

	# Construire la map : ordre_original (1-based) → index dans display_steps
	display_index_map = {}
	for i in display_steps.size():
		var original_ordre: int = display_steps[i].get("ordre", i + 1)
		display_index_map[original_ordre] = i

	emit_signal("recipe_loaded", recipe, display_steps)
	# _schedule_next_chaos()


func _shuffle_array(arr: Array) -> Array:
	var a := arr.duplicate()
	for i in range(a.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp
	return a


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

	# Initialiser _pending_ingredients au premier apport de l'étape
	if _pending_ingredients.is_empty():
		_pending_ingredients = expected_step.get("ingredients", []).duplicate()

	print("[GM] action=%s | ingredient=%s | station=%s" % [action_id, ingredient, station_id])
	print("[GM] expected action=%s | poste=%s | pending=%s" % [expected_step.get("action"), expected_step.get("poste"), _pending_ingredients])

	var valid := _validate_step(expected_step, action_id, ingredient, station_id)
	print("[GM] valid=%s" % valid)

	var _display_idx: int = display_index_map.get(expected_step_index + 1, expected_step_index)
	emit_signal("step_validated", expected_step_index, _display_idx, valid)

	if valid:
		# Étape multi-ingrédients : attendre que tous soient apportés
		if not _pending_ingredients.is_empty():
			emit_signal("step_ingredient_added", expected_step_index, ingredient, _pending_ingredients.size())
			return  # pas encore fini, on ne passe pas à la suivante
		expected_step_index += 1
		if expected_step_index >= steps.size():
			_on_recipe_complete()
	else:
		#_pending_ingredients.clear()
		_on_wrong_step(action_id, station_id)


# ── Validation d'une étape ─────────────────────────────────────────────────
# Pour les étapes multi-ingrédients, on retire l'ingrédient de _pending_ingredients
# au fur et à mesure. L'étape est validée quand la liste est vide.

func _validate_step(step: Dictionary, action_id: String, ingredient: String, station_id: String) -> bool:
	var expected_action: String = step.get("action", "")
	var expected_poste: String  = step.get("poste", "")
	var expected_ings: Array    = step.get("ingredients", [])

	# Vérifier action et poste
	if action_id != expected_action:
		return false
	if station_id != expected_poste:
		return false

	# Étape sans ingrédient requis (ex: mélanger, enfourner) → valide directement
	if expected_ings.is_empty():
		_pending_ingredients.clear()
		return true

	# Étape avec ingrédients : vérifier que celui apporté est attendu
	if ingredient not in _pending_ingredients:
		return false

	# Retirer l'ingrédient apporté de la liste d'attente
	_pending_ingredients.erase(ingredient)
	return true


# ── Recette terminée ───────────────────────────────────────────────────────

func _on_recipe_complete() -> void:
	emit_signal("recipe_completed", current_recipe.get("id", ""))
	"""
	chaos_timer.stop()
	"""
	current_recipe = {}
	display_steps = []
	display_index_map = {}
	expected_step_index = 0
	_pending_ingredients.clear()


# ── Mauvaise étape → remise à zéro ────────────────────────────────────────

func _on_wrong_step(action_id: String, station_id: String) -> void:
	print("[GameManager] Mauvaise étape : %s sur %s" % [action_id, station_id])
	#emit_signal("step_reset")


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
	# _schedule_next_chaos()


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
	display_steps = []
	display_index_map = {}
	expected_step_index = 0
	_pending_ingredients.clear()
	controls_inverted = false
	chaos_timer.stop()
	if player:
		player.set_controls_inverted(false)
