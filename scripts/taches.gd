extends StaticBody3D

@export var stain_texture: Texture2D
@export var mesh_instance_3d: MeshInstance3D

var invert_timer: Timer


func _ready():
	# Timer for control inversion
	invert_timer = Timer.new()
	invert_timer.one_shot = true
	add_child(invert_timer)

	# Auto-spawn every 30 seconds
	var spawn_timer = Timer.new()
	spawn_timer.wait_time = 10.0
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(spawn_one)
	add_child(spawn_timer)


func spawn_one():
	print("Spawning a stain!")
	var mesh_size = mesh_instance_3d.mesh.size
	var top_y = mesh_instance_3d.position.y + (mesh_size.y / 2.0) + 0.02

	var stain = MeshInstance3D.new()
	var quad = QuadMesh.new()
	stain.mesh = quad
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = stain_texture
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.uv1_scale = Vector3(0.5, 0.5, 1.0)
	var col = randi() % 2
	var row = randi() % 2
	mat.uv1_offset = Vector3(col * 0.5, row * 0.5, 0.0)
	stain.material_override = mat
	stain.rotation_degrees.x = -90.0

	var pos = Vector3(
		randf_range(-mesh_size.x / 2.5, mesh_size.x / 2.5),
		top_y,
		randf_range(-mesh_size.z / 1.2, 0)
	)

	var stain_root = Node3D.new()
	stain_root.position = pos
	add_child(stain_root)

	stain.position = Vector3.ZERO
	stain_root.add_child(stain)

	var area = Area3D.new()
	area.collision_layer = 0  # sur aucun layer
	area.collision_mask = 2  # regarde le layer 2
	var col_shape = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.4
	shape.height = 0.2
	col_shape.shape = shape
	area.add_child(col_shape)
	stain_root.add_child(area)

	area.call_deferred("connect", "body_entered", _on_player_stepped_on_stain.bind(stain_root))


func _on_player_stepped_on_stain(player: Node3D, stain_root: Node3D) -> void:
	print(player.name, "Walked on a stain!")
	stain_root.queue_free()

	if player.has_method("set_controls_inverted"):
		player.set_controls_inverted(true)
		if invert_timer.timeout.is_connected(_restore_controls.bind(player)):
			invert_timer.timeout.disconnect(_restore_controls.bind(player))

		invert_timer.timeout.connect(_restore_controls.bind(player), CONNECT_ONE_SHOT)
		invert_timer.start(10.0)  # Reset the countdown every time


func _restore_controls(player: Node3D) -> void:
	if is_instance_valid(player):
		player.set_controls_inverted(false)
