
extends "res://main.gd"

# RISE OF CONQUEST - BUILD 92.7
# CONFIRMED CONSTRUCTION SYSTEM
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

var construction_pending := false
var construction_position := Vector3.ZERO
var construction_screen_position := Vector2.ZERO
var construction_kind := ""

func zoom_camera(delta: float) -> void:
	if world_mode:
		camera_distance = clampf(
			camera_distance + delta,
			35.0,
			155.0
		)
	else:
		camera_distance = clampf(
			camera_distance + delta,
			12.0,
			CAMERA_MAX_61
		)

	update_camera()

func construction_spacing(
	kind_a: String,
	kind_b: String
) -> float:
	return maxf(
		float(BUILDING_SPACING.get(kind_a, 4.5)),
		float(BUILDING_SPACING.get(kind_b, 4.5))
	)

func construction_check(
	kind: String,
	position: Vector3
) -> String:
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
				kind,
				other_kind
			)

			var distance := Vector2(
				position.x - building.position.x,
				position.z - building.position.z
			).length()

			if distance < spacing:
				return "Bina cok yakin. Baska konum sec."

	for cell in occupied:
		var distance := Vector2(
			position.x,
			position.z
		).distance_to(Vector2(cell))

		if distance < 4.5:
			return "Bu alan dolu."

	return ""

func choose_building(kind: String) -> void:
	clear_construction_pending()
	super.choose_building(kind)

func cancel_placement() -> void:
	clear_construction_pending()
	super.cancel_placement()

func clear_construction_pending() -> void:
	construction_pending = false
	construction_position = Vector3.ZERO
	construction_screen_position = Vector2.ZERO
	construction_kind = ""

func get_construction_pending() -> bool:
	return construction_pending

func get_construction_position() -> Vector3:
	return construction_position

func handle_ground_tap(screen_pos: Vector2) -> void:
	if not placing or world_mode or ruler_mode or battle_active:
		clear_construction_pending()
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
		clear_construction_pending()
		status = problem
		update_ui()
		return

	construction_position = grid_pos
	construction_screen_position = screen_pos
	construction_kind = selected_building
	construction_pending = true

	status = "%s konumu secildi. INSA ET ile onayla." % (
		selected_building
	)
	update_ui()

func confirm_construction() -> void:
	if not construction_pending:
		status = "Once bina konumu sec."
		update_ui()
		return

	if not placing or world_mode or ruler_mode or battle_active:
		clear_construction_pending()
		return

	if selected_building != construction_kind:
		clear_construction_pending()
		status = "Bina secimi degisti. Tekrar konum sec."
		update_ui()
		return

	var problem := construction_check(
		construction_kind,
		construction_position
	)

	if problem != "":
		clear_construction_pending()
		status = problem
		update_ui()
		return

	# Recheck the actual ray at confirmation time.
	# This prevents placing at a stale camera position.
	if not is_instance_valid(camera):
		return

	var ray_origin := camera.project_ray_origin(
		construction_screen_position
	)
	var ray_direction := camera.project_ray_normal(
		construction_screen_position
	)

	if absf(ray_direction.y) < 0.0001:
		clear_construction_pending()
		return

	var distance := -ray_origin.y / ray_direction.y

	if distance <= 0.0:
		clear_construction_pending()
		return

	var hit := ray_origin + ray_direction * distance

	var actual_position := Vector3(
		float(roundi(hit.x)),
		0.0,
		float(roundi(hit.z))
	)

	if actual_position.distance_to(
		construction_position
	) > 0.1:
		clear_construction_pending()
		status = "Kamera degisti. Konumu tekrar sec."
		update_ui()
		return

	var saved_screen_pos := construction_screen_position

	clear_construction_pending()

	# The base implementation performs the actual
	# resource deduction, creation, and saving.
	super.handle_ground_tap(saved_screen_pos)

func reject_construction() -> void:
	clear_construction_pending()
	status = "Bina konumu secimi iptal edildi."
	update_ui()
