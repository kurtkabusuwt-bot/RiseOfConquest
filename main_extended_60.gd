
extends "res://main.gd"

# RISE OF CONQUEST - BUILD 92.1
# SAFE CONSTRUCTION PLACEMENT
# Godot 4.4.1 / Android

const BUILD_LIMIT_61 := 47.0
const CAMERA_MAX_61 := 125.0

const BUILDING_SPACING := {
	"Merkez": 8.0,
	"Kule": 5.5,
	"Ev": 4.5,
	"Kışla": 4.5,
	"Çiftlik": 4.5,
	"Kereste": 4.5,
	"Taşocağı": 4.5
}

func zoom_camera(delta: float) -> void:
	if world_mode:
		camera_distance = clampf(
			camera_distance + delta, 35.0, 155.0
		)
	else:
		camera_distance = clampf(
			camera_distance + delta, 12.0, CAMERA_MAX_61
		)

	update_camera()

func construction_spacing(kind_a: String, kind_b: String) -> float:
	return maxf(
		float(BUILDING_SPACING.get(kind_a, 4.5)),
		float(BUILDING_SPACING.get(kind_b, 4.5))
	)

func construction_check(kind: String, position: Vector3) -> String:
	if absf(position.x) > BUILD_LIMIT_61:
		return "Sehir siniri disinda."

	if absf(position.z) > BUILD_LIMIT_61:
		return "Sehir siniri disinda."

	var interaction := get_node_or_null("CityInteraction")

	if interaction != null and interaction.has_method("get_buildings"):
		var buildings: Array = interaction.get_buildings()

		for building in buildings:
			if not is_instance_valid(building):
				continue

			var other_kind := str(
				interaction.building_kind(building)
			)

			var spacing := construction_spacing(
				kind, other_kind
			)

			var distance := Vector2(
				position.x - building.position.x,
				position.z - building.position.z
			).length()

			if distance < spacing:
				return "Bina cok yakin. Baska konum sec."

	# Also check the original occupied-cell records.
	for cell in occupied:
		var distance := Vector2(
			position.x, position.z
		).distance_to(Vector2(cell))

		if distance < 4.5:
			return "Bu alan dolu."

	return ""

func handle_ground_tap(screen_pos: Vector2) -> void:
	if not placing or world_mode or ruler_mode or battle_active:
		super.handle_ground_tap(screen_pos)
		return

	if not is_instance_valid(camera):
		return

	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_direction := camera.project_ray_normal(screen_pos)

	if absf(ray_direction.y) < 0.0001:
		return

	var distance := -ray_origin.y / ray_direction.y

	if distance <= 0.0:
		return

	var hit := ray_origin + ray_direction * distance

	var grid_pos := Vector3(
		float(roundi(hit.x)),
		0.0,
		float(roundi(hit.z))
	)

	var problem := construction_check(
		selected_building,
		grid_pos
	)

	if problem != "":
		status = problem
		update_ui()
		return

	# The original game handles costs, creation,
	# saving, and status after validation.
	super.handle_ground_tap(screen_pos)
