# hud_recipe.gd
# Chemin : res://scripts/ui/hud_recipe.gd

extends CanvasLayer

@onready var panel:           PanelContainer = $Panel
@onready var recipe_title:    Label          = $Panel/VBox/Header/RecipeTitle
@onready var recipe_icon:     Label          = $Panel/VBox/Header/RecipeIcon
@onready var steps_container: VBoxContainer  = $Panel/VBox/StepsContainer

const C_PAPER:     Color = Color(0.961, 0.941, 0.878, 1.0)
const C_TAB:       Color = Color(0.910, 0.875, 0.784, 1.0)
const C_BORDER:    Color = Color(0.545, 0.451, 0.333, 1.0)
const C_SPIRAL:    Color = Color(0.929, 0.898, 0.800, 1.0)
const C_TEXT_DARK: Color = Color(0.173, 0.122, 0.055, 1.0)
const C_TEXT_STEP: Color = Color(0.353, 0.251, 0.125, 1.0)
const C_TEXT_ING:  Color = Color(0.420, 0.314, 0.188, 1.0)
const C_TEXT_DONE: Color = Color(0.165, 0.420, 0.208, 1.0)
const C_DONE_BG:   Color = Color(0.165, 0.420, 0.208, 0.12)

var _step_rows:  Array[Control]    = []
var _ing_labels: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	_style_panel()


func _style_panel() -> void:
	# Corps principal — fond papier crème avec bordure brun tabac
	var s := StyleBoxFlat.new()
	s.bg_color = C_PAPER
	s.border_color = C_BORDER
	s.set_border_width_all(2)
	s.set_corner_radius_all(0)
	s.content_margin_left   = 0.0
	s.content_margin_right  = 4.0
	s.content_margin_top    = 0.0
	s.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", s)

	# Titre
	recipe_title.add_theme_color_override("font_color", C_TEXT_DARK)


# ── Callbacks GameManager ──────────────────────────────────────────────────

func on_recipe_loaded(recipe: Dictionary, display_steps: Array) -> void:
	recipe_title.text = recipe.get("label", "Commande")
	recipe_icon.text  = recipe.get("icon", "")
	_build_steps(recipe, display_steps)
	panel.visible = true
	_animate_in()


func on_step_validated(step_index: int, display_index: int, success: bool) -> void:
	if success:
		if display_index < _step_rows.size():
			_set_step_state(display_index, "done")
			_animate_step_pop(display_index)
	else:
		_animate_error()


func on_step_ingredient_added(step_index: int, ingredient_id: String, _remaining: int) -> void:
	var display_idx: int = GameManager.display_index_map.get(step_index + 1, -1)
	if display_idx < 0 or display_idx >= _ing_labels.size():
		return
	var ing_dict: Dictionary = _ing_labels[display_idx]
	if ing_dict.has(ingredient_id):
		var lbl := ing_dict[ingredient_id] as Label
		lbl.text = "OK " + lbl.text
		lbl.add_theme_color_override("font_color", C_TEXT_DONE)


func on_step_reset() -> void:
	_animate_error()


# ── Construction ───────────────────────────────────────────────────────────

func _build_steps(recipe: Dictionary, display_steps: Array) -> void:
	for child in steps_container.get_children():
		child.queue_free()
	_step_rows.clear()
	_ing_labels.clear()

	for step in display_steps:
		var action_id: String = step.get("action", "")
		var action_data       := RecipeLoader.get_action(action_id)
		var enriched          = step.duplicate()
		enriched["action_label"] = action_data.get("label", action_id)
		enriched["action_icon"]  = action_data.get("icone", "")
		var result := _make_step_row(enriched)
		steps_container.add_child(result[0])
		_step_rows.append(result[0])
		_ing_labels.append(result[1])


func _make_step_row(step: Dictionary) -> Array:
	# Conteneur de la ligne
	var row := PanelContainer.new()
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color(0, 0, 0, 0)
	row_style.set_border_width_all(0)
	row_style.content_margin_left   = 6.0
	row_style.content_margin_right  = 6.0
	row_style.content_margin_top    = 3.0
	row_style.content_margin_bottom = 3.0
	row.add_theme_stylebox_override("panel", row_style)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	# Encoche
	var check := Label.new()
	check.name = "Check"
	check.text = "o"
	check.custom_minimum_size = Vector2(14, 0)
	check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	check.add_theme_font_size_override("font_size", 12)
	check.add_theme_color_override("font_color", C_TEXT_STEP)

	# Colonne contenu
	var col := VBoxContainer.new()
	col.name = "Col"
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)

	# Action
	var action_lbl := Label.new()
	action_lbl.name = "Action"
	action_lbl.text = "%s %s" % [step.get("action_icon", ""), step.get("action_label", "")]
	action_lbl.add_theme_font_size_override("font_size", 12)
	action_lbl.add_theme_color_override("font_color", C_TEXT_DARK)

	# Ingrédients
	var ing_dict: Dictionary = {}
	var ings: Array = step.get("ingredients", [])
	if ings.size() > 0:
		var ing_row := HBoxContainer.new()
		ing_row.name = "Ings"
		ing_row.add_theme_constant_override("separation", 4)
		for ing_id in ings:
			var tag := PanelContainer.new()
			var ts  := StyleBoxFlat.new()
			ts.bg_color     = Color(C_TEXT_ING, 0.07)
			ts.border_color = Color(C_TEXT_ING, 0.35)
			ts.set_border_width_all(1)
			ts.set_corner_radius_all(3)
			ts.content_margin_left   = 4.0
			ts.content_margin_right  = 4.0
			ts.content_margin_top    = 1.0
			ts.content_margin_bottom = 1.0
			tag.add_theme_stylebox_override("panel", ts)
			var lbl := Label.new()
			lbl.text = RecipeLoader.get_ingredient_label(ing_id)
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.add_theme_color_override("font_color", C_TEXT_ING)
			tag.add_child(lbl)
			ing_row.add_child(tag)
			ing_dict[ing_id] = lbl
		col.add_child(ing_row)

	col.add_child(action_lbl)
	hbox.add_child(check)
	hbox.add_child(col)
	row.add_child(hbox)
	return [row, ing_dict]


# ── État visuel ────────────────────────────────────────────────────────────

func _set_step_state(index: int, state: String) -> void:
	if index >= _step_rows.size():
		return
	var row    := _step_rows[index]
	var hbox   := row.get_child(0)
	var check  := hbox.get_node("Check") as Label
	var col    := hbox.get_node("Col")
	var action := col.get_node_or_null("Action") as Label

	match state:
		"done":
			# Fond vert très léger sur la ligne
			var s := StyleBoxFlat.new()
			s.bg_color = C_DONE_BG
			s.set_border_width_all(0)
			s.content_margin_left   = 6.0
			s.content_margin_right  = 6.0
			s.content_margin_top    = 3.0
			s.content_margin_bottom = 3.0
			row.add_theme_stylebox_override("panel", s)
			check.text = "v"
			check.add_theme_color_override("font_color", C_TEXT_DONE)
			if action:
				action.add_theme_color_override("font_color", C_TEXT_DONE)
		"pending":
			var s := StyleBoxFlat.new()
			s.bg_color = Color(0, 0, 0, 0)
			s.set_border_width_all(0)
			s.content_margin_left   = 6.0
			s.content_margin_right  = 6.0
			s.content_margin_top    = 3.0
			s.content_margin_bottom = 3.0
			row.add_theme_stylebox_override("panel", s)
			check.text = "o"
			check.add_theme_color_override("font_color", C_TEXT_STEP)
			if action:
				action.add_theme_color_override("font_color", C_TEXT_DARK)


# ── Animations ────────────────────────────────────────────────────────────

func _animate_in() -> void:
	panel.modulate.a = 0.0
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(panel, "modulate:a", 1.0, 0.3)


func _animate_step_pop(index: int) -> void:
	if index >= _step_rows.size():
		return
	var row := _step_rows[index]
	row.pivot_offset = Vector2(row.size.x * 0.5, row.size.y * 0.5)
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(row, "scale", Vector2(1.04, 1.04), 0.08)
	t.tween_property(row, "scale", Vector2(1.0,  1.0),  0.12)


func _animate_error() -> void:
	var ox := panel.position.x
	var flash := create_tween()
	flash.tween_property(panel, "self_modulate", Color(1.4, 0.3, 0.3, 1.0), 0.05)
	flash.tween_property(panel, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.30)
	var shake := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	shake.tween_property(panel, "position:x", ox - 10.0, 0.05)
	shake.tween_property(panel, "position:x", ox + 10.0, 0.05)
	shake.tween_property(panel, "position:x", ox - 6.0,  0.04)
	shake.tween_property(panel, "position:x", ox + 6.0,  0.04)
	shake.tween_property(panel, "position:x", ox - 3.0,  0.03)
	shake.tween_property(panel, "position:x", ox,        0.03)
