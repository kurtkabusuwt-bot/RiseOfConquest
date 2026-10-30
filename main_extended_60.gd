
extends "res://main.gd"

# RISE OF CONQUEST - BUILD 93.1
# LIVE BUILDING POSITION VALIDATION
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
			camera_distance + delta, 35.0, 155.0
		)
	else:
		camera_distance = clampf(
			camera_distance + delta,
			12.0, CAMERA_MAX_61
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

	if interaction == null:
		return "Bina kontrol sistemi hazir degil."

	if not interaction.has_method("get_buildings"):
		return "Bina kontrol sistemi hazir degil."

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
			position.x - building.global_position.x,
			position.z - building.global_position.z
		).length()

		if distance < spacing:
			return "Bina cok yakin. Baska konum sec."

	# Old occupied cells are intentionally not used here.
	# Actual building positions are authoritative after moves.
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

func _screen_to_ground(
	screen_pos: Vector2
) -> Vector3:
	if not is_instance_valid(camera):
		return Vector3.INF

	var origin := camera.project_ray_origin(screen_pos)
	var direction := camera.project_ray_normal(screen_pos)

	if absf(direction.y) < 0.0001:
		return Vector3.INF

	var distance := -origin.y / direction.y

	if distance <= 0.0:
		return Vector3.INF

	var hit := origin + direction * distance

	return Vector3(
		float(roundi(hit.x)),
		0.0,
		float(roundi(hit.z))
	)

func handle_ground_tap(screen_pos: Vector2) -> void:
	if not placing or world_mode or ruler_mode or battle_active:
		clear_construction_pending()
		super.handle_ground_tap(screen_pos)
		return

	var position := _screen_to_ground(screen_pos)

	if not position.is_finite():
		return

	var problem := construction_check(
		selected_building, position
	)

	if not problem.is_empty():
		clear_construction_pending()
		status = problem
		update_ui()
		return

	construction_position = position
	construction_screen_position = screen_pos
	construction_kind = selected_building
	construction_pending = true

	status = "%s konumu secildi. INSA ET ile onayla." % (
		selected_building
	)
	update_ui()

func _construction_cost_problem(kind: String) -> String:
	match kind:
		"Ev":
			if woods < 100:
				return "Yeterli odun yok."
		"Kışla":
			if woods < 200:
				return "Yeterli odun yok."
		"Çiftlik":
			if woods < 80:
				return "Yeterli odun yok."
		"Taşocağı":
			if woods < 100:
				return "Yeterli odun yok."
		"Kereste":
			if coins < 100:
				return "Yeterli altin yok."
		"Kule":
			if coins < 150:
				return "Yeterli altin yok."
		_:
			return "Gecersiz bina turu."

	return ""

func _pay_construction_cost(kind: String) -> void:
	match kind:
		"Ev":
			woods -= 100
		"Kışla":
			woods -= 200
		"Çiftlik":
			woods -= 80
		"Taşocağı":
			woods -= 100
		"Kereste":
			coins -= 100
		"Kule":
			coins -= 150

func _sync_occupied_cells() -> void:
	var interaction := get_node_or_null("CityInteraction")

	if interaction == null:
		return

	if not interaction.has_method("get_buildings"):
		return

	occupied.clear()

	for building in interaction.get_buildings():
		if not is_instance_valid(building):
			continue

		var position := building.global_position

		occupied.append(
			Vector2i(
				roundi(position.x),
				roundi(position.z)
			)
		)

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

	var position := construction_position
	var kind := construction_kind

	var problem := construction_check(kind, position)

	if not problem.is_empty():
		clear_construction_pending()
		status = problem
		update_ui()
		return

	var cost_problem := _construction_cost_problem(kind)

	if not cost_problem.is_empty():
		status = cost_problem
		update_ui()
		return

	_pay_construction_cost(kind)
	create_building(kind, position)

	buildings_saved.append({
		"kind": kind,
		"x": int(position.x),
		"z": int(position.z)
	})

	_sync_occupied_cells()
	clear_construction_pending()

	save_game(false)

	status = "%s insa edildi!" % kind
	update_ui()

func reject_construction() -> void:
	clear_construction_pending()
	status = "Bina konumu secimi iptal edildi."
	update_ui()
