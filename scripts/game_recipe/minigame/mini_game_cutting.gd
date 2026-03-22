# mini_game_cutting.gd
# Le couteau suit la souris en déplaçant uniquement X et Z
# en mappant le delta souris sur le plan de la planche.
# Chemin : res://scripts/game_recipe/minigame/mini_game_cutting.gd

extends Node3D

# ── Paramètres ─────────────────────────────────────────────────────────────
# Sensibilité : combien d'unités monde par pixel souris
@export var sensitivity: float = 0.005

# Limites de déplacement en X et Z autour de la position initiale
@export var clamp_x: float = 0.3
@export var clamp_z: float = 0.2

# Lissage (lerp speed)
@export var smooth_speed: float = 20.0

# ── État ──────────────────────────────────────────────────────────────────
var _origin:     Vector3   # position initiale = centre de la planche
var _target_pos: Vector3
var _last_mouse: Vector2


func _ready() -> void:
	_origin     = global_position
	_target_pos = global_position
	_last_mouse = _get_mouse()


func _process(delta: float) -> void:
	var mouse     := _get_mouse()
	var mouse_delta := mouse - _last_mouse
	_last_mouse   = mouse

	# Mapper le delta souris directement en déplacement X/Z monde
	# (la caméra regarde de haut en bas-gauche, on approx. X→X, Y→Z)
	_target_pos.x = clamp(
		_target_pos.x + mouse_delta.x * sensitivity,
		_origin.x - clamp_x,
		_origin.x + clamp_x
	)
	_target_pos.z = clamp(
		_target_pos.z + mouse_delta.y * sensitivity,
		_origin.z - clamp_z,
		_origin.z + clamp_z
	)
	_target_pos.y = _origin.y   # Y fixe — pas de mouvement vertical

	global_position = global_position.lerp(_target_pos, smooth_speed * delta)


func _get_mouse() -> Vector2:
	# get_viewport() depuis un Node3D dans le SubViewport
	# retourne bien la souris dans les coordonnées du SubViewport
	return get_viewport().get_mouse_position()
