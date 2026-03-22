# mini_game_steam.gd
# Chemin : res://scripts/game_recipe/minigame/mini_game_steam.gd

extends TextureProgressBar

@export var fill_on_hit:     float = 18.0
@export var drain_on_miss:   float = 14.0
@export var drain_idle:      float = 3.0
@export var min_spawn_delay: float = 0.7
@export var max_spawn_delay: float = 1.5
@export var max_circles:     int   = 3
@export var circle_lifetime: float = 1.8
@export var circle_radius:   float = 30.0

var _spawn_timer:    float        = 0.0
var _next_delay:     float        = 0.0
var _active_circles: int          = 0
var _canvas_layer:   CanvasLayer  = null
var _spawn_area:     Control      = null


func _ready() -> void:
	position  = Vector2(950, 210)
	min_value = 0.0
	max_value = 100.0
	value     = 0.0
	step      = 0.0
	_next_delay = randf_range(min_spawn_delay, max_spawn_delay)

	# Créer un CanvasLayer au niveau racine — deferred car le nœud est en cours d'init
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 10

	_spawn_area = Control.new()
	_spawn_area.name         = "SteamSpawnArea"
	_spawn_area.position     = Vector2.ZERO
	_spawn_area.size         = Vector2(1280, 720)
	_spawn_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_layer.add_child(_spawn_area)

	get_tree().root.add_child.call_deferred(_canvas_layer)


func _process(delta: float) -> void:
	if value >= 100.0:
		# Nettoyer avant de quitter
		_cleanup()
		Context.return_to_previous(true)
		return

	value = maxf(value - drain_idle * delta, 0.0)

	if _active_circles < max_circles:
		_spawn_timer += delta
		if _spawn_timer >= _next_delay:
			_spawn_timer = 0.0
			_next_delay  = randf_range(min_spawn_delay, max_spawn_delay)
			_spawn_circle()


func _spawn_circle() -> void:
	var circle: Control = Control.new()

	var margin := circle_radius + 8.0
	var sw     := _spawn_area.size.x
	var sh     := _spawn_area.size.y
	var pos    := Vector2(
		randf_range(margin, sw - margin),
		randf_range(margin, sh - margin - 80.0)
	)
	circle.position           = pos - Vector2(circle_radius, circle_radius)
	circle.custom_minimum_size = Vector2(circle_radius * 2.0, circle_radius * 2.0)
	circle.pivot_offset       = Vector2(circle_radius, circle_radius)
	circle.mouse_filter       = Control.MOUSE_FILTER_STOP

	_spawn_area.add_child(circle)
	_active_circles += 1

	var script := load("res://scripts/game_recipe/minigame/minigame_mix_circle.gd")
	circle.set_script(script)
	circle.set("lifetime", circle_lifetime)
	circle.set("radius",   circle_radius)

	circle.connect("clicked", _on_circle_clicked.bind(circle))


func _on_circle_clicked(success: bool, _circle: Control) -> void:
	_active_circles = maxi(_active_circles - 1, 0)
	if success:
		value = minf(value + fill_on_hit, 100.0)
	else:
		value = maxf(value - drain_on_miss, 0.0)


func _cleanup() -> void:
	if _canvas_layer and is_instance_valid(_canvas_layer):
		_canvas_layer.queue_free()
		_canvas_layer = null


func _exit_tree() -> void:
	_cleanup()
