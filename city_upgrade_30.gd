
extends Node3D

# RISE OF CONQUEST 3.0
# PAKET 1 - 10 SEHIR GELISTIRMESI
# Mevcut kayit dosyalarina dokunmaz.

var game: Node3D
var expansion: Node
var city: Node3D
var castle_parts: Node3D
var building_parts: Node3D
var last_castle_level := -1
var last_building_levels := ""
var update_timer := 0.0

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	game = get_tree().current_scene as Node3D
	if game == null:
		return
	expansion = game.get_node_or_null("ConquestExpansion")
	if expansion == null:
		return

	city = Node3D.new()
	city.name = "CityDecorations30"
	add_child(city)

	castle_parts = Node3D.new()
	castle_parts.name = "CastleUpgrades"
	city.add_child(castle_parts)

	building_parts = Node3D.new()
	building_parts.name = "BuildingUpgrades"
	city.add_child(building_parts)

	create_roads()
	create_square()
	create_fountain()
	create_trees()
	create_lamps()
	create_gate_details()
	create_static_banners()
	refresh_levels()

func box_mesh(
	parent: Node3D,
	part_name: String,
	pos: Vector3,
	size: Vector3,
	color: Color
) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	part.material_override = mat
	parent.add_child(part)
	return part

func column_mesh(
	parent: Node3D,
	part_name: String,
	pos: Vector3,
	radius: float,
	height: float,
	color: Color
) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	part.mesh = mesh
	part.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	part.material_override = mat
	parent.add_child(part)
	return part

func create_roads() -> void:
	var road := Color(0.58, 0.52, 0.43)
	for i in range(8):
		var z := 5.0 + float(i) * 0.78
		box_mesh(city, "StoneRoad",
			Vector3(0, 0.045, z),
			Vector3(2.5, 0.05, 0.7), road)

func create_square() -> void:
	var stone := Color(0.67, 0.61, 0.50)
	for x in range(4):
		for z in range(3):
			box_mesh(city, "SquareTile",
				Vector3(4.0 + float(x) * 0.85,
					0.045, 5.0 + float(z) * 0.85),
				Vector3(0.78, 0.05, 0.78), stone)

func create_fountain() -> void:
	var stone := Color(0.55, 0.55, 0.53)
	var water := Color(0.22, 0.48, 0.65)
	var fountain := Node3D.new()
	fountain.position = Vector3(5.3, 0, 6.0)
	city.add_child(fountain)

	column_mesh(fountain, "Basin",
		Vector3(0, 0.24, 0), 1.05, 0.45, stone)
	column_mesh(fountain, "Water",
		Vector3(0, 0.49, 0), 0.85, 0.06, water)
	column_mesh(fountain, "Pillar",
		Vector3(0, 0.95, 0), 0.18, 1.0, stone)
	column_mesh(fountain, "Top",
		Vector3(0, 1.48, 0), 0.48, 0.16, stone)

func create_trees() -> void:
	var positions := [
		Vector3(12, 0, 5),
		Vector3(12, 0, 9),
		Vector3(-13, 0, 6),
		Vector3(-13, 0, 10),
		Vector3(8, 0, 9),
		Vector3(-8, 0, 9)
	]
	for pos in positions:
		var tree := Node3D.new()
		tree.position = pos
		city.add_child(tree)
		column_mesh(tree, "Trunk",
			Vector3(0, 0.9, 0), 0.19, 1.8,
			Color(0.35, 0.22, 0.12))
		var leaves := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 1.05
		mesh.height = 2.0
		leaves.mesh = mesh
		leaves.position = Vector3(0, 2.35, 0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.22, 0.43, 0.24)
		leaves.material_override = mat
		tree.add_child(leaves)

func create_lamps() -> void:
	for pos in [
		Vector3(-2.0, 0, 7.5),
		Vector3(2.0, 0, 7.5),
		Vector3(3.3, 0, 9.5),
		Vector3(-3.3, 0, 9.5)
	]:
		var lamp := Node3D.new()
		lamp.position = pos
		city.add_child(lamp)
		box_mesh(lamp, "Pole",
			Vector3(0, 1.1, 0),
			Vector3(0.12, 2.2, 0.12),
			Color(0.30, 0.22, 0.15))
		box_mesh(lamp, "Light",
			Vector3(0, 2.35, 0),
			Vector3(0.38, 0.45, 0.38),
			Color(1.0, 0.69, 0.25))

func create_gate_details() -> void:
	for x in [-2.5, 2.5]:
		box_mesh(city, "GateShield",
			Vector3(x, 2.3, 12.7),
			Vector3(0.65, 0.85, 0.14),
			Color(0.55, 0.12, 0.14))
		box_mesh(city, "GateEmblem",
			Vector3(x, 2.3, 12.79),
			Vector3(0.23, 0.23, 0.08),
			Color(0.91, 0.73, 0.32))

func create_static_banners() -> void:
	for x in [-5.0, 5.0]:
		box_mesh(city, "BannerPole",
			Vector3(x, 2.2, 10.7),
			Vector3(0.1, 4.4, 0.1),
			Color(0.32, 0.23, 0.14))
		box_mesh(city, "RoyalBanner",
			Vector3(x + 0.55, 3.65, 10.7),
			Vector3(1.0, 0.85, 0.08),
			Color(0.53, 0.10, 0.13))

func clear_parts(parent: Node3D) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func refresh_levels() -> void:
	if expansion == null:
		return

	var level := int(expansion.get("castle_level"))
	if level != last_castle_level:
		last_castle_level = level
		update_castle(level)

	var levels: Dictionary = expansion.get("building_levels")
	var signature := JSON.stringify(levels)
	if signature != last_building_levels:
		last_building_levels = signature
		update_buildings(levels)

func update_castle(level: int) -> void:
	clear_parts(castle_parts)

	# Only the central castle changes with castle level.
	# Roads, square and other buildings stay independent.
	var height := 0.4 + float(level) * 0.22
	var stone := Color(0.78, 0.73, 0.63)
	var gold := Color(0.87, 0.70, 0.31)

	for x in [-2.25, 2.25]:
		for z in [-2.25, 2.25]:
			box_mesh(castle_parts, "CastleTurret",
				Vector3(x, 4.2 + height * 0.5, z),
				Vector3(0.9, height + 0.8, 0.9), stone)
			for dx in [-0.27, 0.27]:
				box_mesh(castle_parts, "Battlement",
					Vector3(x + dx, 4.7 + height, z),
					Vector3(0.24, 0.4, 0.4), stone)

	box_mesh(castle_parts, "RoyalFlagPole",
		Vector3(0, 5.1 + height, 0),
		Vector3(0.1, 2.2, 0.1),
		Color(0.31, 0.23, 0.14))
	box_mesh(castle_parts, "RoyalFlag",
		Vector3(0.6, 5.65 + height, 0),
		Vector3(1.1, 0.7, 0.08),
		Color(0.58, 0.09, 0.13))
	box_mesh(castle_parts, "RoyalEmblem",
		Vector3(0.6, 5.65 + height, 0.06),
		Vector3(0.23, 0.23, 0.08), gold)

func update_buildings(levels: Dictionary) -> void:
	clear_parts(building_parts)

	for child in game.get_children():
		if not (child is Node3D):
			continue
		if not levels.has(child.name):
			continue

		var level := int(levels[child.name])
		if level <= 1:
			continue

		var pos: Vector3 = child.position
		var height := 3.5
		if child.name == "Ev":
			height = 3.8
		elif child.name == "Kışla":
			height = 3.5

		var ornament := Node3D.new()
		ornament.position = pos
		building_parts.add_child(ornament)

		for i in range(mini(level - 1, 5)):
			box_mesh(ornament, "LevelMarker",
				Vector3(-0.8 + float(i) * 0.4,
					height, 0),
				Vector3(0.28, 0.35, 0.28),
				Color(0.88, 0.69, 0.25))

func _process(delta: float) -> void:
	if city == null:
		return
	update_timer += delta
	if update_timer >= 1.0:
		update_timer = 0.0
		refresh_levels()
