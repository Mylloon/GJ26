# station_base.gd
# Classe de base pour tous les postes de travail
# Attacher à un StaticBody3D
# Enfants recommandés : MeshInstance3D, CollisionShape3D, Label3D (prompt), AnimationPlayer

class_name StationBase
extends StaticBody3D

# ── Identité du poste ──────────────────────────────────────────────────────
@export var station_id: String = ""
@export var station_label: String = "Poste"
@export var accepted_action: String = ""
@export var station_mini_game: NodePath = ""

# Ingrédients acceptés (vide = accepte tout)
@export var accepted_ingredients: Array[String] = []

# Ingrédient produit après interaction (ex: "lait_chaud" après chauffer_lait)
@export var produced_ingredient: String = ""

# Ce poste consomme-t-il l'ingrédient en main ?
@export var consumes_ingredient: bool = true

# ── État interne ───────────────────────────────────────────────────────────

# ── Noeuds enfants ─────────────────────────────────────────────────────────
@onready var prompt_label: Label3D = get_node_or_null("PromptLabel")
@onready var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

# Optionnel : barre de progression via un MeshInstance3D qu'on scale en X
@onready var progress_mesh: MeshInstance3D = get_node_or_null("ProgressMesh")

signal action_completed(station_id: String, action_id: String, produced: String)


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("station")
	if prompt_label:
		prompt_label.visible = false


func _process(_delta: float) -> void:
	pass


# ── Interface appelée par le joueur ────────────────────────────────────────


func show_prompt(show_bool: bool) -> void:
	if prompt_label:
		prompt_label.visible = show_bool
		prompt_label.text = "[E] %s" % station_label


func try_interact(ingredient_in_hand: String) -> Dictionary:
	if accepted_ingredients.size() > 0:
		if ingredient_in_hand not in accepted_ingredients and ingredient_in_hand != "":
			return {"success": false, "message": "Mauvais ingrédient !"}

	if consumes_ingredient and ingredient_in_hand == "":
		return {"success": false, "message": "Rien en main !"}

	else:
		playMiniGame(station_mini_game)
		return _instant_action(ingredient_in_hand)


func playMiniGame(mini_game_path) -> void:
	print(mini_game_path)
	if mini_game_path.is_empty():
		print("pas de mini game")
		return
	Context.switch_scene(mini_game_path, true)
	emit_signal("action_completed", station_id, accepted_action, produced_ingredient)


# ── Action instantanée ─────────────────────────────────────────────────────


func _instant_action(_ingredient_in_hand: String) -> Dictionary:
	emit_signal("action_completed", station_id, accepted_action, produced_ingredient)

	return {
		"success": true,
		"action_id": accepted_action,
		"station_id": station_id,
		"consumes_ingredient": consumes_ingredient,
		"produces_ingredient": produced_ingredient,
		"message": "✓ %s" % accepted_action
	}
