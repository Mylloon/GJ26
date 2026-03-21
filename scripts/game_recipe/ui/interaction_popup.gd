# interaction_popup.gd
# CanvasLayer qui affiche un popup 2D positionné au-dessus de la station proche.
# Se connecte au joueur via set_player().
#
# Chemin suggéré : res://scripts/ui/interaction_popup.gd

extends CanvasLayer

# ── Noeuds ────────────────────────────────────────────────────────────────
@onready var container:     Control        = $Container
@onready var panel:         PanelContainer = $Container/Panel
@onready var action_label:  Label          = $Container/Panel/VBox/ActionLabel
@onready var hint_label:    Label          = $Container/Panel/VBox/HintLabel

# ── Couleurs ───────────────────────────────────────────────────────────────
const COLOR_BG:       Color = Color(0.10, 0.08, 0.06, 0.88)
const COLOR_BORDER:   Color = Color(0.75, 0.55, 0.22, 1.0)
const COLOR_ACTION:   Color = Color(0.98, 0.92, 0.80, 1.0)
const COLOR_HINT:     Color = Color(0.65, 0.58, 0.46, 1.0)
const COLOR_KEY_BG:   Color = Color(0.28, 0.20, 0.12, 1.0)
const COLOR_KEY_TEXT: Color = Color(1.00, 0.85, 0.45, 1.0)

# ── État ──────────────────────────────────────────────────────────────────
var _camera:  Camera3D = null
var _station: Node     = null   # station actuellement proche
var _player:  Node     = null
var _tween:   Tween    = null

# Offset vertical en pixels au-dessus du point projeté
const OFFSET_Y: float = -60.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	_build_style()


# ── Connexion ──────────────────────────────────────────────────────────────

func set_player(player: Node) -> void:
	_player = player
	# Récupérer la caméra depuis le SubViewport
	_camera = _find_camera()


func _find_camera() -> Camera3D:
	# Cherche dans le groupe "main_camera" en priorité
	var cams := get_tree().get_nodes_in_group("main_camera")
	if not cams.is_empty():
		return cams[0] as Camera3D
	# Fallback : caméra active de la scène principale
	return get_viewport().get_camera_3d()


# ── Affichage appelé par le joueur (via player._on_body_entered_zone) ──────
# Le joueur appelle station.show_prompt(true/false)
# On se connecte directement au signal du joueur plutôt qu'aux stations

func show_for_station(station: Node) -> void:
	_station = station
	_update_text()
	_show_panel(true)


func hide_popup() -> void:
	_station = null
	_show_panel(false)


# ── Mise à jour du texte selon la station et l'ingrédient en main ─────────

func _update_text() -> void:
	if not _station:
		return

	var label: String = _station.get("station_label") if _station.get("station_label") else "Interagir"
	var held:  String = _player.held_ingredient if _player else ""

	action_label.text = "[E]  %s" % label

	# Hint contextuel selon le poste et ce qu'on tient
	hint_label.text = _build_hint(_station.get("station_id"), held)
	hint_label.visible = hint_label.text != ""


func _build_hint(station_id: String, held: String) -> String:
	match station_id:
		"BOWL":
			if held == "":
				return "Mélanger le contenu"
			return "Ajouter %s" % RecipeLoader.get_ingredient_label(held)
		"ESPRESSO_STEAMER":
			match held:
				"café_moulu": return "Extraire un expresso"
				"lait":       return "Mousser le lait"
				"":           return "Café ou lait requis"
		"CUTTING_BOARD":
			if held == "":
				return "Prends un ingrédient"
			return "Couper %s" % RecipeLoader.get_ingredient_label(held)
		"INGREDIENT_RACK":
			return "Choisir un ingrédient"
		"TRASH":
			if held == "":
				return "Mains vides"
			return "Jeter %s" % RecipeLoader.get_ingredient_label(held)
		"OVEN":
			return "Mettre au four"
		"PAN":
			return "Cuire à la poêle"
		"CUP":
			if held == "":
				return "Rien à verser"
			return "Verser %s" % RecipeLoader.get_ingredient_label(held)
		"PLATE":
			if held == "":
				return "Rien à dresser"
			return "Dresser %s" % RecipeLoader.get_ingredient_label(held)
	return ""


# ── Positionnement 3D → 2D chaque frame ────────────────────────────────────

func _process(_delta: float) -> void:
	if not panel.visible or not _station or not _camera:
		return

	# Projeter la position monde de la station en coordonnées écran
	var world_pos: Vector3 = _station.global_position + Vector3(0, 0.5, 0)
	var screen_pos: Vector2 = _camera.unproject_position(world_pos)

	# Vérifier que la station est devant la caméra
	var is_in_front: bool = _camera.is_position_in_frustum(world_pos)
	panel.visible = is_in_front

	if is_in_front:
		# Centrer le panel sur le point projeté
		var panel_size: Vector2 = panel.size
		container.position = screen_pos + Vector2(-panel_size.x / 2.0, OFFSET_Y - panel_size.y)


# ── Animations ────────────────────────────────────────────────────────────

func _show_panel(show: bool) -> void:
	if _tween:
		_tween.kill()

	if show:
		panel.visible = true
		panel.scale = Vector2(0.8, 0.8)
		panel.pivot_offset = panel.size / 2.0
		_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.18)
	else:
		_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		_tween.tween_property(panel, "scale", Vector2(0.85, 0.85), 0.12)
		_tween.tween_callback(func(): panel.visible = false)


# ── Style ──────────────────────────────────────────────────────────────────

func _build_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BG
	style.border_color = COLOR_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left   = 14.0
	style.content_margin_right  = 14.0
	style.content_margin_top    = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)

	action_label.add_theme_color_override("font_color", COLOR_ACTION)
	hint_label.add_theme_color_override("font_color", COLOR_HINT)
