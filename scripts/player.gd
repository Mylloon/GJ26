extends CharacterBody3D

const SPEED = 5.0

@onready var camera_rotation = $"../../SubViewportContainer/SubViewport/Camera3D".get_rotation()


func _physics_process(_delta):
	var inputs = Input.get_vector("left", "right", "forward", "backward")
	var direction = (
		(transform.basis * Vector3(inputs.x, 0, inputs.y))
		. rotated(Vector3.UP, camera_rotation.y)
		. normalized()
	)

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
