extends CharacterBody3D

const SPEED = 5.0


func _physics_process(delta):
	var inputs = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(inputs.x, 0, inputs.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
