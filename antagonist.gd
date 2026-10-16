extends CharacterBody3D

@export var speed: float = 4.0
@export var gravity: float = 9.8
@export var vision_range: float = 15.0

@export var roam_radius: float = 15.0
@export var arrival_distance: float = 0.7
@export var wall_check_distance: float = 1.0

@export var roam_pause_time: float = 1.5

var roam_pause_timer: float = 0.0



var player: CharacterBody3D

var roam_target: Vector3
var has_roam_target: bool = false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")


func _physics_process(delta: float) -> void:

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# Chase player
	if player != null and can_see_player():
		has_roam_target = false
		chase_player()

	# Otherwise roam
	else:
		roam()

	move_and_slide()


func chase_player() -> void:
	var direction := global_position.direction_to(player.global_position)

	# Don't move vertically toward the player
	direction.y = 0.0
	direction = direction.normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	face_direction(direction)


func roam() -> void:

	# Pause after reaching a destination
	if roam_pause_timer > 0.0:
		roam_pause_timer -= get_physics_process_delta_time()

		velocity.x = 0.0
		velocity.z = 0.0
		return

	# Pick a destination if we don't have one
	if not has_roam_target:
		pick_roam_target()

		if not has_roam_target:
			velocity.x = 0.0
			velocity.z = 0.0
			return

	# Have we reached the destination?
	var distance: float = global_position.distance_to(roam_target)

	if distance <= arrival_distance:
		has_roam_target = false

		velocity.x = 0.0
		velocity.z = 0.0

		# Wait 1.5 seconds before picking another destination
		roam_pause_timer = roam_pause_time

		return

	# Direction toward destination
	var direction: Vector3 = global_position.direction_to(roam_target)

	direction.y = 0.0
	direction = direction.normalized()

	# Wall ahead?
	if wall_in_direction(direction):
		has_roam_target = false

		velocity.x = 0.0
		velocity.z = 0.0

		return

	# Walk toward destination
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	face_direction(direction)

func pick_roam_target() -> void:

	for i in range(30):

		var offset := Vector3(
			randf_range(-roam_radius, roam_radius),
			0.0,
			randf_range(-roam_radius, roam_radius)
		)

		# Keep point inside circle
		if offset.length() > roam_radius:
			continue

		var candidate := global_position + offset

		if valid_roam_position(candidate):
			roam_target = candidate
			has_roam_target = true
			return

	has_roam_target = false


func valid_roam_position(position: Vector3) -> bool:

	var space_state := get_world_3d().direct_space_state

	# Look for floor
	var floor_start := position + Vector3.UP * 2.0
	var floor_end := position + Vector3.DOWN * 2.0

	var floor_query := PhysicsRayQueryParameters3D.create(
		floor_start,
		floor_end
	)

	floor_query.exclude = [self]

	var floor_result := space_state.intersect_ray(floor_query)

	if floor_result.is_empty():
		return false

	return true


func wall_in_direction(direction: Vector3) -> bool:

	var space_state := get_world_3d().direct_space_state

	var start := global_position + Vector3.UP * 0.8
	var end := start + direction * wall_check_distance

	var query := PhysicsRayQueryParameters3D.create(
		start,
		end
	)

	query.exclude = [self]

	var result := space_state.intersect_ray(query)

	return not result.is_empty()


func can_see_player() -> bool:

	var start := global_position + Vector3.UP * 0.8
	var end := player.global_position + Vector3.UP * 0.8

	# Too far away
	if start.distance_to(end) > vision_range:
		return false

	var query := PhysicsRayQueryParameters3D.create(
		start,
		end
	)

	query.exclude = [self]

	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		return false

	return result["collider"] == player


func face_direction(direction: Vector3) -> void:

	if direction.length_squared() < 0.01:
		return

	var target := global_position + direction

	look_at(
		Vector3(
			target.x,
			global_position.y,
			target.z
		),
		Vector3.UP
	)
