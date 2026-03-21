# ingredient_menu.gd
# Attacher au nœud IngredientMenu (CanvasLayer)
# Chemin suggéré : res://scripts/game_recipe/station_action/ingredient_menu.gd

extends CanvasLayer

signal ingredient_chosen(ingredient_id: String)

@onready var grid: GridContainer = $Panel/VBox/ScrollContainer/GridContainer
@onready var title_label: Label = $Panel/VBox/Header/TitleLabel
@onready var close_button: Button = $Panel/VBox/Header/CloseButton
@onready var overlay: ColorRect = $Overlay


func _ready() -> void:
	visible = false
	# Le menu doit rester interactif même quand le jeu est en pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Le rack trouve ce menu via ce groupe — pas besoin d'assignation manuelle
	add_to_group("ingredient_menu")
	close_button.pressed.connect(close)
	overlay.gui_input.connect(_on_overlay_input)


# ── Ouvrir avec la liste du rack ───────────────────────────────────────────


func open(available_ingredients: Array[String], rack_label: String = "Étagère") -> void:
	title_label.text = rack_label
	_build_grid(available_ingredients)
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false


# ── Fermer sur clic overlay ou Escape ─────────────────────────────────────


func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()


# ── Construire la grille depuis RecipeLoader ───────────────────────────────


func _build_grid(ingredients: Array[String]) -> void:
	for child in grid.get_children():
		child.queue_free()

	for ing_id in ingredients:
		# Récupération des données depuis le JSON via RecipeLoader
		var label_text: String = RecipeLoader.get_ingredient_label(ing_id)
		var emoji: String = RecipeLoader.get_ingredient_emoji(ing_id)
		grid.add_child(_make_ingredient_button(ing_id, label_text, emoji))


func _make_ingredient_button(ing_id: String, label_text: String, emoji: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(120, 80)
	btn.text = "%s\n%s" % [emoji, label_text]

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.15, 0.12, 0.10)
	normal_style.border_color = Color(0.4, 0.3, 0.2)
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.28, 0.20, 0.14)
	hover_style.border_color = Color(0.75, 0.55, 0.25)
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.55, 0.35, 0.15)
	pressed_style.border_color = Color(0.9, 0.7, 0.3)
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.95, 0.90, 0.80))

	var id_copy := ing_id
	btn.pressed.connect(func(): _on_ingredient_pressed(id_copy))
	return btn


func _on_ingredient_pressed(ingredient_id: String) -> void:
	close()
	emit_signal("ingredient_chosen", ingredient_id)
