
extends "res://main.gd"

# RISE OF CONQUEST - BUILD 93.3
# PERSISTENT BUILDING ID FOUNDATION
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

var building_id_counter := 0

func zoom_camera(delta: float) -> void:
	if world_mode:
		camera_distance = clampf(
			camera_distance + delta,
			35.0, 155.0
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

	for building in interaction.get_buildings():
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

func _screen_to_ground(screen_pos: Vector2) -> Vector3:
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

func _next_building_id() -> String:
	building_id_counter += 1

	return "building_%s_%s" % [
		str(Time.get_unix_time_from_system()),
		str(building_id_counter)
	]

func _building_id_exists(id: String) -> bool:
	var interaction := get_node_or_null("CityInteraction")

	if interaction == null:
		return false

	if not interaction.has_method("get_buildings"):
		return false

	for building in interaction.get_buildings():
		if is_instance_valid(building):
			if str(building.get_meta("building_id", "")) == id:
				return true

	return false

func ensure_building_id(building: Node3D) -> String:
	if not is_instance_valid(building):
		return ""

	var existing := str(
		building.get_meta("building_id", "")
	)

	if not existing.is_empty():
		return existing

	var new_id := _next_building_id()

	while _building_id_exists(new_id):
		new_id = _next_building_id()

	building.set_meta("building_id", new_id)

	return new_id

func ensure_all_building_ids() -> void:
	var interaction := get_node_or_null("CityInteraction")

	if interaction == null:
		return

	if not interaction.has_method("get_buildings"):
		return

	for building in interaction.get_buildings():
		if is_instance_valid(building):
			ensure_building_id(building)

func _find_building_at(
	kind: String,
	position: Vector3
) -> Node3D:
	var interaction := get_node_or_null("CityInteraction")

	if interaction == null:
		return null

	if not interaction.has_method("get_buildings"):
		return null

	for building in interaction.get_buildings():
		if not is_instance_valid(building):
			continue

		if str(interaction.building_kind(building)) != kind:
			continue

		if building.global_position.distance_to(position) < 0.1:
			return building

	return null

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

	var building := _find_building_at(kind, position)
	var new_id := ""

	if is_instance_valid(building):
		new_id = ensure_building_id(building)

	buildings_saved.append({
		"id": new_id,
		"kind": kind,
		"x": int(position.x),
		"z": int(position.z)
	})

	ensure_all_building_ids()
	_sync_occupied_cells()
	clear_construction_pending()

	save_game(false)

	status = "%s insa edildi!" % kind
	update_ui()

func reject_construction() -> void:
	clear_construction_pending()
	status = "Bina konumu secimi iptal edildi."
	update_ui()
