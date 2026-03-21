# hud.gd
# Attacher au nœud HUD (CanvasLayer)
# Chemin suggéré : res://scripts/ui/hud.gd
#
# Connexion depuis kitchen.gd :
#   $HUD.set_player($Player)

extends CanvasLayer

# ── Noeuds ────────────────────────────────────────────────────────────────
@onready var slot_bg:          PanelContainer = $HeldItemPanel/SlotBg
@onready var emoji_label:      Label          = $HeldItemPanel/SlotBg/VBox/EmojiLabel
@onready var ingredient_label: Label          = $HeldItemPanel/SlotBg/VBox/IngredientLabel

# ── Couleurs (style café/pâtisserie) ──────────────────────────────────────
const COLOR_BG_EMPTY:    Color = Color(0.13, 0.10, 0.08, 0.85)
const COLOR_BG_FILLED:   Color = Color(0.22, 0.16, 0.10, 0.92)
const COLOR_BORDER_EMPTY: Color = Color(0.35, 0.28, 0.20, 1.0)
const COLOR_BORDER_FILLED: Color = Color(0.80, 0.58, 0.22, 1.0)
const COLOR_LABEL_EMPTY:  Color = Color(0.55, 0.48, 0.40, 1.0)
const COLOR_LABEL_FILLED: Color = Color(0.98, 0.92, 0.80, 1.0)
const COLOR_SLOT_TEXT:    Color = Color(0.55, 0.48, 0.40, 1.0)

# ── État ──────────────────────────────────────────────────────────────────
@onready var _player: Node = null
var _tween: Tween = null


func _ready() -> void:
	set_player($"../Player/CharacterBody3D")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_style(false)
	_build_styles()


# ── Connexion au joueur ────────────────────────────────────────────────────

func set_player(player: Node) -> void:
	print("iciiii")
	print("player : ",player)
	if _player:
		print("decconnecteeeed")
		if _player.ingredient_picked_up.is_connected(_on_ingredient_picked_up):
			_player.ingredient_picked_up.disconnect(_on_ingredient_picked_up)
		if _player.ingredient_dropped.is_connected(_on_ingredient_dropped):
			_player.ingredient_dropped.disconnect(_on_ingredient_dropped)

	_player = player

	if _player:
		print("connected")
		_player.ingredient_picked_up.connect(_on_ingredient_picked_up)
		_player.ingredient_dropped.connect(_on_ingredient_dropped)
		# Synchroniser l'état actuel si le joueur tient déjà quelque chose
		if _player.held_ingredient != "":
			_on_ingredient_picked_up(_player.held_ingredient)


# ── Callbacks signaux joueur ───────────────────────────────────────────────

func _on_ingredient_picked_up(ingredient_id: String) -> void:
	print("dans la maaaaaaaaain", ingredient_id)
	var label_text: String = RecipeLoader.get_ingredient_label(ingredient_id)
	var emoji: String      = RecipeLoader.get_ingredient_emoji(ingredient_id)
	emoji_label.text      = emoji
	ingredient_label.text = label_text
	_apply_style(true)
	_animate_pop()


func _on_ingredient_dropped() -> void:
	emoji_label.text      = ""
	ingredient_label.text = "—"
	_apply_style(false)
	_animate_fade()


# ── Styles dynamiques ──────────────────────────────────────────────────────

func _build_styles() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BG_EMPTY
	style.border_color = COLOR_BORDER_EMPTY
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left   = 12.0
	style.content_margin_right  = 12.0
	style.content_margin_top    = 10.0
	style.content_margin_bottom = 10.0
	slot_bg.add_theme_stylebox_override("panel", style)

	# Label "EN MAIN"
	var slot_label: Label = $HeldItemPanel/SlotBg/VBox/SlotLabel
	slot_label.add_theme_color_override("font_color", COLOR_SLOT_TEXT)


func _apply_style(filled: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color     = COLOR_BG_FILLED     if filled else COLOR_BG_EMPTY
	style.border_color = COLOR_BORDER_FILLED if filled else COLOR_BORDER_EMPTY
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left   = 12.0
	style.content_margin_right  = 12.0
	style.content_margin_top    = 10.0
	style.content_margin_bottom = 10.0
	slot_bg.add_theme_stylebox_override("panel", style)

	var text_color := COLOR_LABEL_FILLED if filled else COLOR_LABEL_EMPTY
	emoji_label.add_theme_color_override("font_color", text_color)
	ingredient_label.add_theme_color_override("font_color", text_color)


# ── Animations ────────────────────────────────────────────────────────────

func _animate_pop() -> void:
	if _tween:
		_tween.kill()
	var panel: Control = $HeldItemPanel
	panel.scale = Vector2(0.85, 0.85)
	panel.pivot_offset = panel.size / 2.0
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.25)


func _animate_fade() -> void:
	if _tween:
		_tween.kill()
	var panel: Control = $HeldItemPanel
	panel.scale = Vector2(1.0, 1.0)
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(panel, "scale", Vector2(0.92, 0.92), 0.15)
	_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.1)
