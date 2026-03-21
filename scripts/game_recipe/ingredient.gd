# ingredient.gd
# Attacher à un StaticBody3D posé dans la scène
# Enfants requis : MeshInstance3D, CollisionShape3D
# Enfant optionnel : Label3D (prompt)

class_name Ingredient
extends StaticBody3D

# ── Identité ───────────────────────────────────────────────────────────────
@export var ingredient_id: String = ""      # ex: "farine", "oeufs", "matcha"
@export var ingredient_label: String = ""   # ex: "Farine", "Œufs"

# Si true : source infinie (étagère, frigo) — réapparaît après ramassage
# Si false : disparaît définitivement après ramassage
@export var is_infinite_source: bool = false

# ── Noeuds ────────────────────────────────────────────────────────────────
@onready var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")
@onready var prompt_label: Label3D         = get_node_or_null("PromptLabel")


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("ingredient")
	if prompt_label:
		prompt_label.visible = false
		prompt_label.text = "[E] Prendre %s" % ingredient_label


func show_prompt(show: bool) -> void:
	if prompt_label:
		prompt_label.visible = show


func on_picked_up() -> void:
	if is_infinite_source:
		hide()
		await get_tree().create_timer(0.5).timeout
		show()
	else:
		queue_free()
