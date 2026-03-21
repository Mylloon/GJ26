extends Node3D

@export var smoothing: float = 10.0
var camera: Camera3D
var player: Node3D
var cam_offset: Vector3

func _ready() -> void:
	player = $"../Player/CharacterBody3D"  
	camera = $"../SubViewportContainer/SubViewport/Camera3D"
	cam_offset = camera.global_position - player.global_position

func _process(delta: float) -> void:
	print("Player pos: ", player.global_position)
	print("Camera pos: ", camera.global_position)
	var desired = player.global_position + cam_offset
	camera.global_position = camera.global_position.lerp(desired, smoothing * delta)
