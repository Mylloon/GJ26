# hud_recipe.gd
# HUD affichant la recette en cours avec encoches de progression.
# Connecté aux signaux du GameManager depuis kitchen.gd.
#
# Chemin : res://scripts/ui/hud_recipe.gd

extends CanvasLayer

# ── Noeuds ────────────────────────────────────────────────────────────────
@onready var panel:           PanelContainer = $Panel
@onready var recipe_title:    Label          = $Panel/VBox/Header/RecipeTitle
@onready var recipe_icon:     Label          = $Panel/VBox/Header/RecipeIcon
@onready var steps_container: VBoxContainer  = $Panel/VBox/StepsContainer

# ── Couleurs ───────────────────────────────────────────────────────────────
const COLOR_BG:           Color = Color(0.10, 0.08, 0.06, 0.90)
const COLOR_BORDER:       Color = Color(0.45, 0.33, 0.20, 1.0)
const COLOR_STEP_PENDING: Color = Color(0.20, 0.16, 0.12, 1.0)
const COLOR_STEP_DONE:    Color = Color(0.15, 0.35, 0.18, 1.0)
const COLOR_STEP_WRONG:   Color = Color(0.35, 0.10, 0.08, 1.0)
const COLOR_TEXT_PENDING: Color = Color(0.70, 0.63, 0.52, 1.0)
const COLOR_TEXT_DONE:    Color = Color(0.60, 0.92, 0.65, 1.0)
const COLOR_TEXT_WRONG:   Color = Color(1.00, 0.45, 0.38, 1.0)
const COLOR_TITLE:        Color = Color(0.98, 0.92, 0.80, 1.0)

# ── État ──────────────────────────────────────────────────────────────────
var _step_rows: Array[Control] = []   # une entrée par étape
var _total_steps: int = 0
var _current_index: int = 0           # miroir local de GameManager.expected_step_index


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	_build_panel_style()


# ── Callbacks signaux GameManager ──────────────────────────────────────────

func on_recipe_loaded(recipe: Dictionary) -> void:
	_total_steps = recipe.get("etapes", []).size()
	_current_index = 0

	recipe_title.text = recipe.get("label", "Commande")
	recipe_icon.text  = recipe.get("icon", "🍽")

	_build_steps(recipe)
	panel.visible = true
	_animate_in()


func on_step_validated(step_index: int, success: bool) -> void:
	if step_index >= _step_rows.size():
		return

	if success:
		_current_index = step_index + 1
		_set_step_state(step_index, "done")
		_animate_step_pop(step_index)
	else:
		# Mauvaise étape — on flash en rouge mais on attend on_step_reset
		_set_step_state(step_index, "wrong")
		await get_tree().create_timer(0.4).timeout
		# step_reset va tout remettre à pending
		# (si step_reset arrive avant le timer, pas grave — idempotent)


func on_step_ingredient_added(step_index: int, ingredient_id: String, remaining: int) -> void:
	if step_index >= _step_rows.size():
		return
	var row := _step_rows[step_index]

	# Debug : afficher l'arbre du row pour trouver le bon chemin
	print("[HUD] Recherche Ing_%s dans row %s" % [ingredient_id, row.name])
	_print_tree(row, "  ")

	# Chercher le label en parcourant récursivement
	var ing_lbl := _find_ingredient_label(row, "Ing_" + ingredient_id)
	if ing_lbl:
		ing_lbl.add_theme_color_override("font_color", Color(0.4, 0.6, 0.42, 1.0))
		ing_lbl.text = "✓ " + ing_lbl.text
	else:
		print("[HUD] Label Ing_%s introuvable !" % ingredient_id)

	var icon := row.get_node("Notch/Icon") as Label
	icon.text = "+%d" % remaining
	icon.add_theme_color_override("font_color", Color(1.0, 0.78, 0.2, 1.0))


func _find_ingredient_label(node: Node, target_name: String) -> Label:
	if node.name == target_name and node is Label:
		return node as Label
	for child in node.get_children():
		var result := _find_ingredient_label(child, target_name)
		if result:
			return result
	return null


func _print_tree(node: Node, indent: String) -> void:
	print("%s%s (%s)" % [indent, node.name, node.get_class()])
	for child in node.get_children():
		_print_tree(child, indent + "  ")


func on_step_reset() -> void:
	_current_index = 0
	for i in _step_rows.size():
		_set_step_state(i, "pending")
	_animate_shake()


# ── Construction des lignes d'étapes ───────────────────────────────────────

func _build_steps(recipe: Dictionary) -> void:
	# Vider les anciens
	for child in steps_container.get_children():
		child.queue_free()
	_step_rows.clear()

	var steps := RecipeLoader.get_steps_with_labels(recipe.get("id", ""))

	for step in steps:
		var row := _make_step_row(step)
		steps_container.add_child(row)
		_step_rows.append(row)


func _make_step_row(step: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# ── Encoche (indicateur d'état) ──
	var notch := PanelContainer.new()
	notch.name = "Notch"
	notch.custom_minimum_size = Vector2(28, 28)
	var notch_style := StyleBoxFlat.new()
	notch_style.bg_color = Color(0.3, 0.25, 0.18)
	notch_style.set_corner_radius_all(4)
	notch.add_theme_stylebox_override("panel", notch_style)

	var notch_label := Label.new()
	notch_label.name = "Icon"
	notch_label.text = "○"
	notch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notch_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	notch_label.add_theme_font_size_override("font_size", 14)
	notch_label.add_theme_color_override("font_color", COLOR_TEXT_PENDING)
	notch.add_child(notch_label)

	# ── Contenu de l'étape ──
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 1)

	var action_lbl := Label.new()
	action_lbl.name = "ActionLabel"
	action_lbl.text = "%s  %s" % [step.get("action_icon", ""), step.get("action_label", "")]
	action_lbl.add_theme_font_size_override("font_size", 12)
	action_lbl.add_theme_color_override("font_color", COLOR_TEXT_PENDING)

	var ings: Array = step.get("ingredients", [])
	if ings.size() > 0:
		var ing_row := HBoxContainer.new()
		ing_row.name = "IngredientsRow"
		ing_row.add_theme_constant_override("separation", 4)
		for ing_id in ings:
			var lbl := Label.new()
			# Nom unique pour retrouver ce label plus tard
			lbl.name = "Ing_" + ing_id
			lbl.text = RecipeLoader.get_ingredient_label(ing_id)
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.add_theme_color_override("font_color", Color(COLOR_TEXT_PENDING, 0.75))
			ing_row.add_child(lbl)
		content.add_child(ing_row)

	content.add_child(action_lbl)

	# ── Assemblage ──
	var bg := PanelContainer.new()
	bg.name = "StepBg"
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COLOR_STEP_PENDING
	bg_style.set_corner_radius_all(6)
	bg_style.content_margin_left   = 8.0
	bg_style.content_margin_right  = 8.0
	bg_style.content_margin_top    = 5.0
	bg_style.content_margin_bottom = 5.0
	bg.add_theme_stylebox_override("panel", bg_style)
	bg.add_child(content)

	row.add_child(notch)
	row.add_child(bg)

	return row


# ── Changer l'état visuel d'une étape ─────────────────────────────────────

func _set_step_state(index: int, state: String) -> void:
	if index >= _step_rows.size():
		return

	var row    := _step_rows[index]
	var notch  := row.get_node("Notch") as PanelContainer
	var icon   := notch.get_node("Icon") as Label
	var bg     := row.get_node("StepBg") as PanelContainer
	var action := bg.get_node_or_null("VBoxContainer/ActionLabel") as Label

	var bg_style    := StyleBoxFlat.new()
	bg_style.set_corner_radius_all(6)
	bg_style.content_margin_left   = 8.0
	bg_style.content_margin_right  = 8.0
	bg_style.content_margin_top    = 5.0
	bg_style.content_margin_bottom = 5.0

	match state:
		"done":
			icon.text = "✓"
			icon.add_theme_color_override("font_color", COLOR_TEXT_DONE)
			bg_style.bg_color = COLOR_STEP_DONE
			if action:
				action.add_theme_color_override("font_color", COLOR_TEXT_DONE)
		"wrong":
			icon.text = "✗"
			icon.add_theme_color_override("font_color", COLOR_TEXT_WRONG)
			bg_style.bg_color = COLOR_STEP_WRONG
			if action:
				action.add_theme_color_override("font_color", COLOR_TEXT_WRONG)
		"pending":
			icon.text = "○"
			icon.add_theme_color_override("font_color", COLOR_TEXT_PENDING)
			bg_style.bg_color = COLOR_STEP_PENDING
			if action:
				action.add_theme_color_override("font_color", COLOR_TEXT_PENDING)

	bg.add_theme_stylebox_override("panel", bg_style)


# ── Animations ────────────────────────────────────────────────────────────

func _animate_in() -> void:
	panel.modulate.a = 0.0
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)


func _animate_step_pop(index: int) -> void:
	if index >= _step_rows.size():
		return
	var row := _step_rows[index]
	row.scale = Vector2(1.0, 1.0)
	row.pivot_offset = row.size / 2.0
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(row, "scale", Vector2(1.06, 1.06), 0.08)
	tween.tween_property(row, "scale", Vector2(1.0, 1.0), 0.12)


func _animate_shake() -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(panel, "position:x", panel.position.x - 8.0, 0.06)
	tween.tween_property(panel, "position:x", panel.position.x + 8.0, 0.06)
	tween.tween_property(panel, "position:x", panel.position.x - 4.0, 0.05)
	tween.tween_property(panel, "position:x", panel.position.x, 0.05)


# ── Style du panel principal ───────────────────────────────────────────────

func _build_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BG
	style.border_color = COLOR_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left   = 14.0
	style.content_margin_right  = 14.0
	style.content_margin_top    = 12.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)
	recipe_title.add_theme_color_override("font_color", COLOR_TITLE)


func _debug_print_children(node: Node, depth: int) -> void:
	print("%s%s (%s)" % ["  ".repeat(depth), node.name, node.get_class()])
	for child in node.get_children():
		_debug_print_children(child, depth + 1)


func _find_node_by_name(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var result := _find_node_by_name(child, target)
		if result:
			return result
	return null
