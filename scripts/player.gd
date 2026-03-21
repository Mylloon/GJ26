extends CharacterBody3D

# ── Mouvement ──────────────────────────────────────────────────────────────
const SPEED = 5.0

@onready var camera_rotation = $"../../SubViewportContainer/SubViewport/Camera3D".get_rotation()

# ── Contrôles inversés (thème emmêlé) ──────────────────────────────────────
var controls_inverted: bool = false

# ── Ingrédient en main ─────────────────────────────────────────────────────
var held_ingredient: String = ""
var held_ingredient_node: Node = null

# ── Zone d'interaction ─────────────────────────────────────────────────────
# Ajouter un nœud Area3D enfant nommé "InteractionZone" avec un CollisionShape3D
@onready var interaction_zone: Area3D = $InteractionZone

# Mesh au-dessus du joueur montrant ce qu'il tient
# Ajouter un nœud MeshInstance3D enfant nommé "HeldItemDisplay"
@onready var held_item_display = get_node_or_null("HeldItemDisplay")

var nearby_interactable: Node = null

# Référence au popup d'interaction (InteractionPopup CanvasLayer)
# Assigné depuis kitchen.gd : player.interaction_popup = $InteractionPopup
var interaction_popup: Node = null

# ── Signaux vers le GameManager ────────────────────────────────────────────
signal action_performed(action_id: String, ingredient: String, station_id: String)
signal ingredient_picked_up(ingredient_id: String)
signal ingredient_dropped()


func _ready() -> void:
	interaction_zone.body_entered.connect(_on_body_entered_zone)
	interaction_zone.body_exited.connect(_on_body_exited_zone)
	interaction_zone.area_entered.connect(_on_area_entered_zone)
	interaction_zone.area_exited.connect(_on_area_exited_zone)
	

func _input(event):
	if event.is_action_pressed("pause"):
		var screenshot = get_viewport().get_texture().get_image()
		Context.switch_scene("res://scenes/pause.tscn", ImageTexture.create_from_image(screenshot))


# ── Mouvement ──────────────────────────────────────────────────────────────

func _physics_process(_delta):
	var inputs = Input.get_vector("left", "right", "forward", "backward")

	if controls_inverted:
		inputs = -inputs

	var direction = (
		transform.basis * Vector3(inputs.x, 0, inputs.y)
	).rotated(Vector3.UP, camera_rotation.y).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


# ── Input interaction ──────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()
	"""
	if event.is_action_pressed("drop"):
		drop_ingredient()
"""

# ── Détection de zone ──────────────────────────────────────────────────────

func _on_body_entered_zone(body: Node) -> void:
	if body.is_in_group("interactable"):
		nearby_interactable = body
		_show_interaction_popup(body)


func _on_body_exited_zone(body: Node) -> void:
	if body == nearby_interactable:
		nearby_interactable = null
		_hide_interaction_popup()


func _on_area_entered_zone(area: Area3D) -> void:
	var parent := area.get_parent()
	if parent.is_in_group("interactable"):
		nearby_interactable = parent
		_show_interaction_popup(parent)


func _on_area_exited_zone(area: Area3D) -> void:
	var parent := area.get_parent()
	if parent == nearby_interactable:
		nearby_interactable = null
		_hide_interaction_popup()


func _show_interaction_popup(station: Node) -> void:
	if interaction_popup:
		interaction_popup.show_for_station(station)


func _hide_interaction_popup() -> void:
	if interaction_popup:
		interaction_popup.hide_popup()


# ── Interaction principale ─────────────────────────────────────────────────

func _try_interact() -> void:
	if nearby_interactable == null:
		return

	# Tous les interactables sont désormais des stations (dont StationIngredientRack)
	if nearby_interactable.is_in_group("station"):
		_try_use_station(nearby_interactable)
		return


# ── Recevoir un ingrédient depuis une étagère (appelé par StationIngredientRack) ──

func receive_ingredient(ingredient_id: String) -> void:
	held_ingredient = ingredient_id
	held_ingredient_node = null   # pas de node 3D associé, vient du menu
	_update_held_display()
	emit_signal("ingredient_picked_up", ingredient_id)
	# Rafraîchir le hint du popup (l'ingrédient en main a changé)
	if interaction_popup and nearby_interactable:
		interaction_popup.show_for_station(nearby_interactable)


# ── Poser l'ingrédient ─────────────────────────────────────────────────────

func drop_ingredient() -> void:
	if held_ingredient == "":
		return

	held_ingredient = ""
	held_ingredient_node = null
	_update_held_display()
	emit_signal("ingredient_dropped")
	# Rafraîchir le hint du popup
	if interaction_popup and nearby_interactable:
		interaction_popup.show_for_station(nearby_interactable)


# ── Utiliser un poste ──────────────────────────────────────────────────────

func _try_use_station(station: Node) -> void:
	var result: Dictionary = station.try_interact(held_ingredient)

	if not result.get("success", false):
		# "menu_opening" = le rack ouvre un menu, ce n'est pas une erreur
		if result.get("reason", "") == "menu_opening":
			return
		var msg: String = result.get("message", "")
		if msg != "":
			_show_feedback(msg)
		return

	var action_id: String  = result.get("action_id", "")
	var station_id: String = result.get("station_id", "")
	var consumed: bool     = result.get("consumes_ingredient", false)
	var produced: String   = result.get("produces_ingredient", "")

	if consumed and held_ingredient != "":
		if held_ingredient_node:
			held_ingredient_node.queue_free()
			held_ingredient_node = null
		held_ingredient = ""
		_update_held_display()

	if produced != "":
		held_ingredient = produced
		_update_held_display()

	emit_signal("action_performed", action_id, held_ingredient, station_id)
	_show_feedback(result.get("message", "✓"))


# ── Affichage ingrédient en main ───────────────────────────────────────────

func _update_held_display() -> void:
	if not held_item_display:
		return
	held_item_display.visible = held_ingredient != ""
	# Optionnel : swapper le mesh selon l'ingrédient
	# held_item_display.mesh = load("res://assets/ingredients/%s.mesh" % held_ingredient)


# ── Feedback texte rapide ──────────────────────────────────────────────────

func _show_feedback(text: String) -> void:
	var label := get_node_or_null("FeedbackLabel")
	if label:
		label.text = text
		label.visible = true
		await get_tree().create_timer(1.0).timeout
		label.visible = false
	else:
		print("[Player] Feedback : ", text)


# ── API publique appelée par le GameManager ────────────────────────────────

func set_controls_inverted(inverted: bool) -> void:
	controls_inverted = inverted
	_show_feedback("⚡ Contrôles inversés !" if inverted else "Contrôles normaux")
