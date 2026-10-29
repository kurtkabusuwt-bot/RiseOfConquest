
extends Node3D

# RISE OF CONQUEST 8.0
# LIVING KINGDOM - CITY PACKAGE
# Godot 4.4.1 / Android
# Independent visual module.
# Does not modify game saves or resources.

const MAX_CITIZENS: int = 18
const MAX_GUARDS: int = 6
const CITY_LIMIT: float = 44.0
const DAY_LENGTH: float = 240.0

var game: Node3D
var root: Node3D
var people_root: Node3D
var details_root: Node3D
var sun: DirectionalLight3D

var people: Array[Dictionary] = []
var lamp_lights: Array[OmniLight3D] = []
var lamp_flames: Array[MeshInstance3D] = []

var houses: Array[Vector3] = []
var work_places: Array[Vector3] = []
var building_signature: String = ""

var day_clock: float = 0.25
var update_clock: float = 0.0
var walk_clock: float = 0.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	call_deferred("initialize")

func initialize() -> void:
	game = get_parent() as Node3D
	if game == null:
		return

	rng.seed = 802026

	root = Node3D.new()
	root.name = "LivingKingdom80"
	add_child(root)

	people_root = Node3D.new()
	people_root.name = "Citizens80"
	root.add_child(people_root)

	details_root = Node3D.new()
	details_root.name = "BuildingDetails80"
	root.add_child(details_root)

	create_sun()
	create_roads()
	create_castle_details()
	create_lamps()
	refresh_buildings()
	create_people()
	update_daylight()

func make_material(
	color: Color,
	emissive: bool = false
) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88

	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.3

	return mat

func add_box(
	parent: Node3D,
	pos: Vector3,
	size: Vector3,
	color: Color,
	emissive: bool = false
) -> MeshInstance3D:
	var part: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = pos
	part.material_override = make_material(color, emissive)
	parent.add_child(part)
	return part

func add_cylinder(
	parent: Node3D,
	pos: Vector3,
	radius: float,
	height: float,
	color: Color
) -> MeshInstance3D:
	var part: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	part.mesh = mesh
	part.position = pos
	part.material_override = make_material(color)
	parent.add_child(part)
	return part

func create_sun() -> void:
	sun = DirectionalLight3D.new()
	sun.name = "DayNightSun80"
	sun.shadow_enabled = false
	sun.light_energy = 0.0
	sun.rotation_degrees = Vector3(-50, -30, 0)
	root.add_child(sun)

func create_roads() -> void:
	var road: Color = Color(0.58, 0.51, 0.40)
	var edging: Color = Color(0.39, 0.36, 0.30)

	# Fixed roads. Castle upgrades do not change them.
	for x in [-39.0, -21.0, 21.0, 39.0]:
		add_box(
			root,
			Vector3(x, 0.045, 0),
			Vector3(1.5, 0.045, 84.0),
			road
		)

	for z in [-39.0, -21.0, 21.0, 39.0]:
		add_box(
			root,
			Vector3(0, 0.045, z),
			Vector3(84.0, 0.045, 1.5),
			road
		)

	for x in [-39.0, -21.0, 21.0, 39.0]:
		for z in [-39.0, -21.0, 21.0, 39.0]:
			add_box(
				root,
				Vector3(x, 0.09, z),
				Vector3(2.1, 0.08, 2.1),
				edging
			)

func create_castle_details() -> void:
	var stone: Color = Color(0.72, 0.67, 0.57)
	var red: Color = Color(0.59, 0.12, 0.14)
	var gold: Color = Color(0.88, 0.70, 0.31)

	# Decorations do not replace the original castle.
	for x in [-7.0, 7.0]:
		add_box(
			root,
			Vector3(x, 0.85, -7.0),
			Vector3(1.1, 1.7, 1.1),
			stone
		)
		add_box(
			root,
			Vector3(x, 1.8, -7.0),
			Vector3(1.5, 0.35, 1.5),
			stone
		)
		add_box(
			root,
			Vector3(x, 3.0, -7.0),
			Vector3(0.12, 2.4, 0.12),
			Color(0.35, 0.24, 0.15)
		)
		add_box(
			root,
			Vector3(x + 0.55, 3.5, -7.0),
			Vector3(1.0, 0.7, 0.08),
			red
		)
		add_box(
			root,
			Vector3(x + 0.55, 3.5, -6.94),
			Vector3(0.18, 0.18, 0.04),
			gold
		)

func create_lamps() -> void:
	var locations: Array[Vector3] = [
		Vector3(-21, 0, -21),
		Vector3(21, 0, -21),
		Vector3(-21, 0, 21),
		Vector3(21, 0, 21),
		Vector3(-39, 0, 0),
		Vector3(39, 0, 0),
		Vector3(0, 0, -39),
		Vector3(0, 0, 39)
	]

	for pos in locations:
		var holder: Node3D = Node3D.new()
		holder.position = pos
		root.add_child(holder)

		add_box(
			holder,
			Vector3(0, 1.15, 0),
			Vector3(0.15, 2.3, 0.15),
			Color(0.34, 0.23, 0.13)
		)

		var flame: MeshInstance3D = add_box(
			holder,
			Vector3(0, 2.48, 0),
			Vector3(0.42, 0.46, 0.42),
			Color(1.0, 0.67, 0.22),
			true
		)
		lamp_flames.append(flame)

		var light: OmniLight3D = OmniLight3D.new()
		light.position = Vector3(0, 2.48, 0)
		light.light_color = Color(1.0, 0.67, 0.34)
		light.light_energy = 0.0
		light.omni_range = 6.5
		light.shadow_enabled = false
		holder.add_child(light)
		lamp_lights.append(light)

func get_saved_buildings() -> Array:
	if game == null:
		return []

	var data: Variant = game.get("buildings_saved")
	if data is Array:
		return data

	return []

func refresh_buildings() -> void:
	var saved: Array = get_saved_buildings()
	var signature: String = JSON.stringify(saved)

	if signature == building_signature:
		return

	building_signature = signature
	houses.clear()
	work_places.clear()

	for child in details_root.get_children():
		details_root.remove_child(child)
		child.queue_free()

	for item in saved:
		if not (item is Dictionary):
			continue

		var entry: Dictionary = item
		var kind: String = str(entry.get("kind", ""))
		var x: float = float(entry.get("x", 0.0))
		var z: float = float(entry.get("z", 0.0))

		if absf(x) > CITY_LIMIT:
			continue
		if absf(z) > CITY_LIMIT:
			continue

		var pos: Vector3 = Vector3(x, 0, z)

		if kind == "Ev":
			houses.append(pos)
		else:
			work_places.append(pos)

		create_building_details(kind, pos)

func create_building_details(
	kind: String,
	pos: Vector3
) -> void:
	var holder: Node3D = Node3D.new()
	holder.position = pos
	details_root.add_child(holder)

	match kind:
		"Ev":
			add_box(
				holder,
				Vector3(1.55, 0.35, 1.55),
				Vector3(0.85, 0.7, 0.85),
				Color(0.55, 0.38, 0.24)
			)
			add_box(
				holder,
				Vector3(1.55, 0.83, 1.55),
				Vector3(1.05, 0.28, 1.05),
				Color(0.38, 0.19, 0.14)
			)

		"Çiftlik":
			for i in range(3):
				add_box(
					holder,
					Vector3(-1.0 + float(i), 0.12, 2.0),
					Vector3(0.5, 0.20, 1.1),
					Color(0.50, 0.40, 0.20)
				)

		"Kışla":
			add_box(
				holder,
				Vector3(1.9, 1.2, 0),
				Vector3(0.12, 2.4, 0.12),
				Color(0.35, 0.24, 0.15)
			)
			add_box(
				holder,
				Vector3(2.4, 1.85, 0),
				Vector3(0.95, 0.65, 0.08),
				Color(0.65, 0.15, 0.14)
			)

		"Kereste":
			for i in range(3):
				var log_part: MeshInstance3D = add_cylinder(
					holder,
					Vector3(1.5, 0.24, float(i) * 0.48),
					0.20,
					1.5,
					Color(0.39, 0.24, 0.13)
				)
				log_part.rotation.z = PI / 2.0

		"Taşocağı":
			for i in range(4):
				add_box(
					holder,
					Vector3(
						1.4 + float(i % 2) * 0.55,
						0.28,
						1.3 + float(int(i / 2)) * 0.6
					),
					Vector3(0.55, 0.5, 0.6),
					Color(0.55, 0.54, 0.51)
				)

		"Kule":
			add_box(
				holder,
				Vector3(1.6, 0.65, 1.6),
				Vector3(0.7, 1.3, 0.7),
				Color(0.63, 0.60, 0.54)
			)

func choose_destination(
	is_guard: bool,
	current: Vector3
) -> Vector3:
	if is_guard:
		var patrol: Array[Vector3] = [
			Vector3(-11, 0, -11),
			Vector3(11, 0, -11),
			Vector3(11, 0, 11),
			Vector3(-11, 0, 11)
		]
		var best: Vector3 = patrol[0]
		var best_distance: float = -1.0

		for point in patrol:
			var dist: float = current.distance_to(point)
			if dist > best_distance:
				best_distance = dist
				best = point

		return best

	if houses.size() > 0 and rng.randf() < 0.5:
		var house: Vector3 = houses[
			rng.randi_range(0, houses.size() - 1)
		]
		return house + Vector3(
			rng.randf_range(-2.0, 2.0),
			0,
			rng.randf_range(-2.0, 2.0)
		)

	if work_places.size() > 0 and rng.randf() < 0.65:
		var work: Vector3 = work_places[
			rng.randi_range(0, work_places.size() - 1)
		]
		return work + Vector3(
			rng.randf_range(-2.0, 2.0),
			0,
			rng.randf_range(-2.0, 2.0)
		)

	return Vector3(
		rng.randf_range(-CITY_LIMIT, CITY_LIMIT),
		0,
		rng.randf_range(-CITY_LIMIT, CITY_LIMIT)
	)

func create_person(
	pos: Vector3,
	is_guard: bool
) -> Dictionary:
	var character: Node3D = Node3D.new()
	character.position = pos
	people_root.add_child(character)

	var outfit: Color = Color(
		rng.randf_range(0.27, 0.65),
		rng.randf_range(0.25, 0.52),
		rng.randf_range(0.20, 0.48)
	)

	if is_guard:
		outfit = Color(0.25, 0.36, 0.55)

	add_box(
		character,
		Vector3(0, 0.85, 0),
		Vector3(0.45, 0.85, 0.33),
		outfit
	)

	add_box(
		character,
		Vector3(0, 1.47, 0),
		Vector3(0.35, 0.35, 0.34),
		Color(0.76, 0.58, 0.44)
	)

	for side in [-1.0, 1.0]:
		add_box(
			character,
			Vector3(side * 0.15, 0.22, 0),
			Vector3(0.15, 0.44, 0.20),
			Color(0.28, 0.26, 0.25)
		)
		add_box(
			character,
			Vector3(side * 0.33, 0.88, 0),
			Vector3(0.13, 0.66, 0.18),
			outfit.darkened(0.12)
		)

	if is_guard:
		add_box(
			character,
			Vector3(0, 1.72, 0),
			Vector3(0.48, 0.15, 0.44),
			Color(0.60, 0.61, 0.64)
		)
		add_box(
			character,
			Vector3(0.46, 1.1, 0),
			Vector3(0.07, 1.55, 0.07),
			Color(0.66, 0.66, 0.69)
		)

	return {
		"node": character,
		"guard": is_guard,
		"target": choose_destination(is_guard, pos),
		"speed": 1.2 if is_guard else 0.85,
		"phase": rng.randf_range(0.0, TAU),
		"waiting": 0.0
	}

func create_people() -> void:
	for i in range(MAX_CITIZENS):
		var start: Vector3 = Vector3(
			rng.randf_range(-32.0, 32.0),
			0,
			rng.randf_range(-32.0, 32.0)
		)
		people.append(create_person(start, false))

	for i in range(MAX_GUARDS):
		var start: Vector3 = Vector3(
			rng.randf_range(-10.0, 10.0),
			0,
			rng.randf_range(-10.0, 10.0)
		)
		people.append(create_person(start, true))

func update_daylight() -> void:
	var height: float = sin(day_clock * TAU)
	var daylight: float = clampf(
		0.35 + height * 0.55,
		0.0,
		0.85
	)

	if sun != null:
		sun.light_energy = daylight
		sun.rotation_degrees = Vector3(
			-25.0 - height * 45.0,
			-35.0,
			0.0
		)

	var is_night: bool = height < -0.15

	for flame in lamp_flames:
		if is_instance_valid(flame):
			flame.visible = is_night

	for light in lamp_lights:
		if is_instance_valid(light):
			light.light_energy = 0.5 if is_night else 0.0

func update_people(delta: float) -> void:
	walk_clock += delta

	for person in people:
		var character: Node3D = person["node"]
		if not is_instance_valid(character):
			continue

		var waiting: float = float(person["waiting"])
		if waiting > 0.0:
			person["waiting"] = maxf(0.0, waiting - delta)
			continue

		var target: Vector3 = person["target"]
		var direction: Vector3 = target - character.position
		direction.y = 0.0

		var distance: float = direction.length()

		if distance < 0.7:
			person["target"] = choose_destination(
				bool(person["guard"]),
				character.position
			)
			person["waiting"] = rng.randf_range(0.4, 2.0)
			continue

		var speed: float = float(person["speed"])
		var step: float = minf(speed * delta, distance)

		character.position += direction.normalized() * step
		character.rotation.y = atan2(
			-direction.x,
			-direction.z
		)

		var phase: float = float(person["phase"])
		character.position.y = absf(
			sin(walk_clock * 7.0 + phase)
		) * 0.035

func _process(delta: float) -> void:
	if game == null or root == null:
		return

	# Pause city animations on the world map.
	if bool(game.get("world_mode")):
		return

	day_clock = fposmod(
		day_clock + delta / DAY_LENGTH,
		1.0
	)

	update_people(delta)

	update_clock += delta
	if update_clock >= 1.0:
		update_clock = 0.0
		refresh_buildings()
		update_daylight()
