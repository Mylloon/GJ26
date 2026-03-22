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
# @export var station_mini_game: Node = null

# Ingrédients acceptés (vide = accepte tout)
@export var accepted_ingredients: Array[String] = []

# Ingrédient produit après interaction (ex: "lait_chaud" après chauffer_lait)
@export var produced_ingredient: String = ""

# Ce poste consomme-t-il l'ingrédient en main ?
@export var consumes_ingredient: bool = true

# ── État interne ───────────────────────────────────────────────────────────
var is_busy: bool = false
var progress: float = 0.0
@export var action_duration: float = 0.0   # 0 = instantané

# ── Noeuds enfants ─────────────────────────────────────────────────────────
@onready var prompt_label: Label3D        = get_node_or_null("PromptLabel")
@onready var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")
@onready var anim_player: AnimationPlayer  = get_node_or_null("AnimationPlayer")

# Optionnel : barre de progression via un MeshInstance3D qu'on scale en X
@onready var progress_mesh: MeshInstance3D = get_node_or_null("ProgressMesh")

signal action_completed(station_id: String, action_id: String, produced: String)


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("station")
	if prompt_label:
		prompt_label.visible = false

func _process(_delta: float) -> void:
	if is_busy and progress_mesh:
		progress_mesh.scale.x = progress


# ── Interface appelée par le joueur ────────────────────────────────────────

func show_prompt(show_bool: bool) -> void:
	if prompt_label:
		prompt_label.visible = show_bool
		prompt_label.text = "[E] %s" % station_label


func try_interact(ingredient_in_hand: String) -> Dictionary:
	if is_busy:
		return { "success": false, "message": "En cours…" }

	if accepted_ingredients.size() > 0:
		if ingredient_in_hand not in accepted_ingredients and ingredient_in_hand != "":
			return { "success": false, "message": "Mauvais ingrédient !" }

	if consumes_ingredient and ingredient_in_hand == "":
		return { "success": false, "message": "Rien en main !" }

	if action_duration > 0.0:
		_start_timed_action(ingredient_in_hand)
		return {
			"success": true,
			"action_id": accepted_action,
			"station_id": station_id,
			"consumes_ingredient": consumes_ingredient,
			"produces_ingredient": "",
			"message": "En cours…"
		}
	else:
		return _instant_action(ingredient_in_hand)


# ── Action instantanée ─────────────────────────────────────────────────────

func _instant_action(_ingredient_in_hand: String) -> Dictionary:
	_play_action_animation()
	emit_signal("action_completed", station_id, accepted_action, produced_ingredient)
	
	return {
		"success": true,
		"action_id": accepted_action,
		"station_id": station_id,
		"consumes_ingredient": consumes_ingredient,
		"produces_ingredient": produced_ingredient,
		"message": "✓ %s" % accepted_action
	}


# ── Action avec durée ──────────────────────────────────────────────────────

func _start_timed_action(ingredient_in_hand: String) -> void:
	is_busy = true
	progress = 0.0
	if progress_mesh:
		progress_mesh.visible = true
		progress_mesh.scale.x = 0.0

	_play_action_animation()

	var tween := create_tween()
	tween.tween_property(self, "progress", 1.0, action_duration)
	tween.tween_callback(_on_timed_action_done.bind(ingredient_in_hand))


func _on_timed_action_done(_ingredient_in_hand: String) -> void:
	is_busy = false
	if progress_mesh:
		progress_mesh.visible = false
	emit_signal("action_completed", station_id, accepted_action, produced_ingredient)


# ── Animation ─────────────────────────────────────────────────────────────

func _play_action_animation() -> void:
	if anim_player and anim_player.has_animation("use"):
		anim_player.play("use")
