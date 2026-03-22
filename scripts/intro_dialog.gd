# intro_dialog.gd
# Dialogue d'introduction — bloque le gameplay jusqu'à la fin.
# Déclenché depuis kitchen.gd avant _start_next_order().
# Chemin : res://scripts/ui/intro_dialog.gd

extends CanvasLayer

signal dialog_finished

# ── Noeuds ────────────────────────────────────────────────────────────────
@onready var overlay:       ColorRect    = $Overlay
@onready var dialog_box:    PanelContainer = $DialogBox
@onready var portrait_icon: TextureRect  = $DialogBox/HBox/Portrait/VBoxPortrait/PortraitIcon
@onready var speaker_name:  Label        = $DialogBox/HBox/Portrait/VBoxPortrait/SpeakerName
@onready var dialog_text:   RichTextLabel = $DialogBox/HBox/VBoxText/DialogText
@onready var progress_dots: Label        = $DialogBox/HBox/VBoxText/HBoxBottom/ProgressDots
@onready var prompt_label:  Label        = $DialogBox/HBox/VBoxText/HBoxBottom/PromptLabel

# ── Couleurs ───────────────────────────────────────────────────────────────
const C_PAPER:       Color = Color(0.961, 0.941, 0.878, 1.0)
const C_BORDER:      Color = Color(0.545, 0.451, 0.333, 1.0)
const C_PORTRAIT_BG: Color = Color(0.910, 0.875, 0.784, 1.0)
const C_TEXT_DARK:   Color = Color(0.173, 0.122, 0.055, 1.0)
const C_TEXT_MUTED:  Color = Color(0.420, 0.333, 0.200, 1.0)
const C_ACCENT:      Color = Color(0.545, 0.451, 0.333, 1.0)

# ── Dialogues ──────────────────────────────────────────────────────────────
# Chaque entrée : { speaker, icon, text }
# Chemins des portraits — à placer dans res://assets/ui/portraits/
# bernard.png  : le propriétaire
# player.png   : le joueur
const PORTRAIT_ANDY: String = "res://assets/Andy.png"
const PORTRAIT_PLAYER:  String ="res://assets/Matt.png"

const LINES: Array = [
	{
		"speaker": "M. Andy",
		"portrait": PORTRAIT_ANDY,
		"text": "Ah, te voilà ! Bienvenue au [b]Café Emmêlé[/b]. Je suis M. Andy, le propriétaire."
	},
	{
		"speaker": "M. Andy",
		"portrait": PORTRAIT_ANDY,
		"text": "C'est ton premier jour... et j'ai un [b]petit problème[/b]. Une urgence familiale. Je dois partir [i]maintenant[/i]."
	},
	{
		"speaker": "M. Andy",
		"portrait": PORTRAIT_ANDY,
		"text": "Personne d'autre ne peut venir aujourd'hui. Tu vas devoir [b]te débrouiller seul[/b] pour ouvrir le service."
	},
	{
		"speaker": "M. Andy",
		"portrait": PORTRAIT_ANDY,
		"text": "J'ai laissé le [b]calepin des recettes[/b] sur le comptoir. Toutes les préparations sont dedans... en théorie."
	},
	{
		"speaker": "M. Andy",
		"portrait": PORTRAIT_ANDY,
		"text": "Bon, je dois y aller. [i]Bonne chance ![/i]"
	},
	{
		"speaker": "Vous",
		"portrait": PORTRAIT_PLAYER,
		"text": "Euh... d'accord. Je... je vais gérer."
	},
	{
		"speaker": "Vous",
		"portrait": PORTRAIT_PLAYER,
		"text": "[i](Je feuillette le calepin...)[/i]\n\nAttends, les étapes sont complètement dans le désordre ! Comment je suis censé m'y retrouver ?"
	},
	{
		"speaker": "Vous",
		"portrait": PORTRAIT_PLAYER,
		"text": "Bon. Première commande. Je regarde bien la recette avant qu'elle disparaisse... et j'essaie de retrouver l'ordre logique.\n\n[b]Allons-y.[/b]"
	},
]

# ── État ──────────────────────────────────────────────────────────────────
var _current_line: int = 0
var _is_typing: bool = false
var _full_text: String = ""
var _type_timer: float = 0.0
var _char_index: int = 0
const TYPE_SPEED: float = 0.03   # secondes par caractère


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_style_nodes()


func _style_nodes() -> void:
	# Dialog box — fond papier crème
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = C_PAPER
	box_style.border_color = C_BORDER
	box_style.set_border_width_all(2)
	box_style.set_corner_radius_all(0)
	box_style.content_margin_left   = 16.0
	box_style.content_margin_right  = 16.0
	box_style.content_margin_top    = 14.0
	box_style.content_margin_bottom = 14.0
	dialog_box.add_theme_stylebox_override("panel", box_style)

	# Portrait — fond crème foncé
	var port_node := $DialogBox/HBox/Portrait
	var port_style := StyleBoxFlat.new()
	port_style.bg_color = C_PORTRAIT_BG
	port_style.border_color = C_BORDER
	port_style.set_border_width_all(2)
	port_style.set_corner_radius_all(0)
	port_style.content_margin_left   = 8.0
	port_style.content_margin_right  = 8.0
	port_style.content_margin_top    = 10.0
	port_style.content_margin_bottom = 10.0
	port_node.add_theme_stylebox_override("panel", port_style)

	speaker_name.add_theme_color_override("font_color", C_TEXT_MUTED)
	dialog_text.add_theme_color_override("default_color", C_TEXT_DARK)
	progress_dots.add_theme_color_override("font_color", C_TEXT_MUTED)
	prompt_label.add_theme_color_override("font_color", C_ACCENT)


# ── API publique ───────────────────────────────────────────────────────────

func start() -> void:
	visible = true
	_current_line = 0
	_show_line(_current_line)
	_animate_in()


# ── Affichage d'une ligne ──────────────────────────────────────────────────

func _show_line(index: int) -> void:
	var line: Dictionary = LINES[index]

	# Charger le portrait depuis le chemin de ressource
	var portrait_path: String = line.get("portrait", "")
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		portrait_icon.texture = load(portrait_path)
	else:
		portrait_icon.texture = null
	speaker_name.text = line["speaker"]
	progress_dots.text = "%d / %d" % [index + 1, LINES.size()]

	_full_text  = line["text"]
	_char_index = 0
	_is_typing  = true
	dialog_text.text = ""
	prompt_label.text = "..."
	set_process(true)


func _process(delta: float) -> void:
	if not _is_typing:
		return
	_type_timer += delta
	if _type_timer >= TYPE_SPEED:
		_type_timer = 0.0
		_char_index += 1
		# RichTextLabel : on traque les balises pour ne pas les afficher partiellement
		dialog_text.text = _full_text.substr(0, _char_index)
		if _char_index >= _full_text.length():
			_is_typing = false
			prompt_label.text = "[ Clic ou Espace ]" if _current_line < LINES.size() - 1 \
								else "[ Commencer ]"
			set_process(false)


# ── Input ──────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	var advance := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		advance = true

	if not advance:
		return

	get_viewport().set_input_as_handled()

	if _is_typing:
		# Afficher le texte complet immédiatement
		_char_index = _full_text.length()
		dialog_text.text = _full_text
		_is_typing = false
		prompt_label.text = "[ Clic ou Espace ]" if _current_line < LINES.size() - 1 \
							else "[ Commencer ]"
		set_process(false)
		return

	_advance()


func _advance() -> void:
	_current_line += 1
	if _current_line >= LINES.size():
		_finish()
		return
	_show_line(_current_line)


# ── Fin du dialogue ────────────────────────────────────────────────────────

func _finish() -> void:
	var tween := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "layer", 20, 0.0)
	tween.tween_property(overlay, "color:a", 0.0, 0.35)
	tween.parallel().tween_property(dialog_box, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func():
		visible = false
		emit_signal("dialog_finished")
	)


# ── Animation d'entrée ────────────────────────────────────────────────────

func _animate_in() -> void:
	overlay.color.a = 0.0
	dialog_box.modulate.a = 0.0
	dialog_box.position.y += 20.0
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(overlay, "color:a", 0.72, 0.4)
	tween.parallel().tween_property(dialog_box, "modulate:a", 1.0, 0.35)
	tween.parallel().tween_property(dialog_box, "position:y", dialog_box.position.y - 20.0, 0.35)
