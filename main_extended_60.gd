
extends "res://main.gd"

# RISE OF CONQUEST - BUILD 94.2
# BUILDING COUNTS + SAFE CITY SAVE
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
			camera_distance + delta, 35.0, 155.0
		)
	else:
		camera_distance = clampf(
			camera_distance + delta,
			12.0, CAMERA_MAX_61
		)
	update_camera()

func _kind_from_name(node_name: String) -> String:
	for kind in BUILDING_SPACING.keys():
		if node_name == kind:
			return kind
		if node_name.begins_with("@" + kind + "@"):
			return kind
		if node_name.begins_with(kind):
			var suffix := node_name.substr(
				kind.length()
			)
			if suffix.is_valid_int():
				return kind
	return ""

func _all_buildings() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for child in get_children():
		if child is Node3D:
			var building := child as Node3D
			if _kind_from_name(
				str(building.name)
			) != "":
				result.append(building)
	return result

func recount_production_buildings() -> void:
	var houses := 0
	var farms := 0
	var mines := 0
	var lumber := 0
	var barracks := 0

	for building in _all_buildings():
		var kind := _kind_from_name(
			str(building.name)
		)
		match kind:
			"Ev":
				houses += 1
			"Çiftlik":
				farms += 1
			"Taşocağı":
				mines += 1
			"Kereste":
				lumber += 1
			"Kışla":
				barracks += 1

	house_count = houses
	farm_count = farms
	mine_count = mines
	lumber_count = lumber
	barracks_count = barracks

func get_resource_production_per_minute() -> Dictionary:
	recount_production_buildings()
	return {
		"coins": (house_count * 3 + 1) * 12,
		"woods": (lumber_count * 8 + 2) * 12,
		"stones": mine_count * 6 * 12,
		"foods": (farm_count * 10 + 2) * 12,
		"gems": 0
	}

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
	if not BUILDING_SPACING.has(kind):
		return "Gecersiz bina turu."

	for building in _all_buildings():
		var other_kind := _kind_from_name(
			str(building.name)
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

func _screen_to_ground(
	screen_pos: Vector2
) -> Vector3:
	if not is_instance_valid(camera):
		return Vector3.INF

	var origin := camera.project_ray_origin(screen_pos)
	var direction := camera.project_ray_normal(
		screen_pos
	)

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

func handle_ground_tap(
	screen_pos: Vector2
) -> void:
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

	status = "%s konumu secildi. INSA ET ile onayla." % selected_building
	update_ui()

func _construction_cost_problem(
	kind: String
) -> String:
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

func _pay_construction_cost(
	kind: String
) -> void:
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

func _building_id_exists(
	id: String,
	excluded: Node3D = null
) -> bool:
	for building in _all_buildings():
		if building == excluded:
			continue
		if str(building.get_meta(
			"building_id", ""
		)) == id:
			return true
	return false

func ensure_building_id(
	building: Node3D
) -> String:
	if not is_instance_valid(building):
		return ""

	var existing := str(
		building.get_meta("building_id", "")
	)

	if not existing.is_empty():
		if not _building_id_exists(
			existing, building
		):
			return existing

	var new_id := _next_building_id()
	while _building_id_exists(
		new_id, building
	):
		new_id = _next_building_id()

	building.set_meta("building_id", new_id)
	return new_id

func ensure_all_building_ids() -> void:
	for building in _all_buildings():
		ensure_building_id(building)

func _find_building_at(
	kind: String,
	position: Vector3
) -> Node3D:
	var buildings := _all_buildings()
	buildings.reverse()

	for building in buildings:
		if _kind_from_name(
			str(building.name)
		) != kind:
			continue
		if building.position.distance_to(
			position
		) < 0.1:
			return building
	return null

func _sync_occupied_cells() -> void:
	occupied.clear()
	for building in _all_buildings():
		occupied.append(
			Vector2i(
				roundi(building.position.x),
				roundi(building.position.z)
			)
		)

func _rebuild_saved_buildings() -> void:
	var entries: Array[Dictionary] = []

	for building in _all_buildings():
		var kind := _kind_from_name(
			str(building.name)
		)
		if kind == "Merkez":
			continue

		entries.append({
			"id": ensure_building_id(building),
			"kind": kind,
			"x": roundi(building.position.x),
			"z": roundi(building.position.z)
		})

	buildings_saved = entries

func _save_city_state() -> void:
	ensure_all_building_ids()
	recount_production_buildings()
	_sync_occupied_cells()
	_rebuild_saved_buildings()
	save_game(false)

	var interaction := get_node_or_null(
		"CityInteraction"
	)
	if interaction != null:
		if interaction.has_method("save_positions"):
			interaction.call("save_positions")

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

	var problem := construction_check(
		kind, position
	)
	if not problem.is_empty():
		clear_construction_pending()
		status = problem
		update_ui()
		return

	var cost_problem := _construction_cost_problem(
		kind
	)
	if not cost_problem.is_empty():
		status = cost_problem
		update_ui()
		return

	_pay_construction_cost(kind)
	create_building(kind, position)

	var building := _find_building_at(
		kind, position
	)
	if is_instance_valid(building):
		ensure_building_id(building)

	clear_construction_pending()
	_save_city_state()

	status = "%s insa edildi!" % kind
	update_ui()

func reject_construction() -> void:
	clear_construction_pending()
	status = "Bina konumu secimi iptal edildi."
	update_ui()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		recount_production_buildings()
		return

	var file := FileAccess.open(
		SAVE_PATH, FileAccess.READ
	)
	if file == null:
		recount_production_buildings()
		return

	var parsed: Variant = JSON.parse_string(
		file.get_as_text()
	)
	file.close()

	if not (parsed is Dictionary):
		recount_production_buildings()
		return

	var data: Dictionary = parsed

	coins = int(data.get("coins", coins))
	woods = int(data.get("woods", woods))
	stones = int(data.get("stones", stones))
	foods = int(data.get("foods", foods))

	var entries: Variant = data.get(
		"buildings", []
	)

	var loaded_ids: Dictionary = {}
	var loaded_positions: Dictionary = {}

	if entries is Array:
		for entry in entries:
			if not (entry is Dictionary):
				continue

			var kind := str(
				entry.get("kind", "")
			)

			if kind not in [
				"Ev", "Kule", "Kışla",
				"Çiftlik", "Kereste",
				"Taşocağı"
			]:
				continue

			var x := int(entry.get("x", 0))
			var z := int(entry.get("z", 0))

			if absi(x) > 47 or absi(z) > 47:
				continue

			var position := Vector3(x, 0, z)
			var saved_id := str(
				entry.get("id", "")
			)

			if not saved_id.is_empty():
				if loaded_ids.has(saved_id):
					continue

			var position_key := (
				str(x) + ":" + str(z)
			)

			if loaded_positions.has(
				position_key
			):
				continue

			var existing := _find_building_at(
				kind, position
			)

			if existing != null:
				continue

			create_building(kind, position)

			var building := _find_building_at(
				kind, position
			)
			if building == null:
				continue

			if not saved_id.is_empty():
				if not _building_id_exists(
					saved_id, building
				):
					building.set_meta(
						"building_id", saved_id
					)

			var final_id := ensure_building_id(
				building
			)

			loaded_ids[final_id] = true
			loaded_positions[position_key] = true

			buildings_saved.append({
				"id": final_id,
				"kind": kind,
				"x": x,
				"z": z
			})

	ruler.position.x = clampf(
		float(data.get("ruler_x", 3.0)),
		-14.0, 14.0
	)
	ruler.position.z = clampf(
		float(data.get("ruler_z", 4.0)),
		-14.0, 14.0
	)

	ensure_all_building_ids()
	recount_production_buildings()
	_sync_occupied_cells()

	status = "Kayitli sehrin yuklendi."
