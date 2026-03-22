extends StaticBody3D

@export var stain_texture: Texture2D
@export var mesh_instance_3d: MeshInstance3D


func _ready():
	for i in range(20):  # DEBUG
		spawn_one()


func spawn_one():
	var mesh_size = mesh_instance_3d.mesh.size
	var top_y = mesh_instance_3d.position.y + (mesh_size.y / 2.0) + 0.02
	var stain = MeshInstance3D.new()
	var quad = QuadMesh.new()
	stain.mesh = quad

	var mat = StandardMaterial3D.new()
	mat.albedo_texture = stain_texture
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR

	# Scale UVs to show only one quadrant (half in each axis)
	mat.uv1_scale = Vector3(0.5, 0.5, 1.0)

	# Pick a random quadrant: col and row each 0 or 1
	var col = randi() % 2
	var row = randi() % 2
	mat.uv1_offset = Vector3(col * 0.5, row * 0.5, 0.0)

	stain.material_override = mat
	stain.rotation_degrees.x = -90.0
	stain.rotation_degrees.z = randf_range(0, 360)
	stain.position = Vector3(
		randf_range(-mesh_size.x / 2.5, mesh_size.x / 2.5),
		top_y,
		randf_range(-mesh_size.z / 1.2, 0)
	)
	add_child(stain)
