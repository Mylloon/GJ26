# minigame_mix_circle.gd
# Nœud : Control (instancié dynamiquement par le gestionnaire)
# Un cercle avec un arc qui se vide — cliquer avant qu'il disparaisse.
# Chemin : res://scripts/game_recipe/minigame/minigame_mix_circle.gd

extends Control

# ── Signaux ────────────────────────────────────────────────────────────────
signal clicked(success: bool)   # true = cliqué à temps, false = expiré

# ── Paramètres ────────────────────────────────────────────────────────────
@export var lifetime:    float = 1.8    # durée de vie en secondes
@export var radius:      float = 32.0   # rayon du cercle px

# ── Couleurs ──────────────────────────────────────────────────────────────
const C_BG:       Color = Color(0.95, 0.90, 0.78, 0.92)
const C_BORDER:   Color = Color(0.55, 0.40, 0.20, 1.0)
const C_ARC_FULL: Color = Color(0.25, 0.65, 0.35, 1.0)   # vert
const C_ARC_LOW:  Color = Color(0.80, 0.25, 0.15, 1.0)   # rouge quand peu de temps
const C_CLICK:    Color = Color(1.0,  0.85, 0.40, 1.0)   # flash jaune au clic

# ── État ──────────────────────────────────────────────────────────────────
var _elapsed:   float = 0.0
var _done:      bool  = false
var _hit:       bool  = false


func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	pivot_offset        = Vector2(radius, radius)
	mouse_filter        = Control.MOUSE_FILTER_STOP
	_animate_spawn()


func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	queue_redraw()
	if _elapsed >= lifetime:
		_expire()


func _draw() -> void:
	var center := Vector2(radius, radius)
	var progress := clampf(1.0 - _elapsed / lifetime, 0.0, 1.0)

	# Fond du cercle
	draw_circle(center, radius - 2.0, C_BG)

	# Arc timer
	var arc_color := C_ARC_FULL.lerp(C_ARC_LOW, 1.0 - progress)
	var arc_start := -PI * 0.5                          # départ en haut
	var arc_end   := arc_start + TAU * progress
	draw_arc(center, radius - 4.0, arc_start, arc_end, 48, arc_color, 5.0, true)

	# Bordure extérieure
	draw_arc(center, radius - 1.0, 0.0, TAU, 48, C_BORDER, 1.5)

	# Petite croix centrale
	var s := 6.0
	draw_line(center - Vector2(s, 0), center + Vector2(s, 0), C_BORDER, 1.5)
	draw_line(center - Vector2(0, s), center + Vector2(0, s), C_BORDER, 1.5)


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hit = true
		_done = true
		emit_signal("clicked", true)
		_animate_hit()


func _expire() -> void:
	if _done:
		return
	_done = true
	emit_signal("clicked", false)
	_animate_miss()


# ── Animations ────────────────────────────────────────────────────────────

func _animate_spawn() -> void:
	scale = Vector2(0.3, 0.3)
	modulate.a = 0.0
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(self, "scale",       Vector2(1.0, 1.0), 0.18)
	t.parallel().tween_property(self, "modulate:a", 1.0,        0.15)


func _animate_hit() -> void:
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "scale",       Vector2(1.3, 1.3), 0.08)
	t.tween_property(self, "scale",       Vector2(0.0, 0.0), 0.12)
	t.parallel().tween_property(self, "modulate:a", 0.0,        0.12)
	t.tween_callback(queue_free)


func _animate_miss() -> void:
	var t := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate",    Color(1.0, 0.2, 0.2, 0.8), 0.08)
	t.tween_property(self, "modulate:a",  0.0,                        0.18)
	t.tween_callback(queue_free)
