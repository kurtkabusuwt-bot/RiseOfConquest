
extends Node3D

# RISE OF CONQUEST
# CITY EXPANSION 6.0
# Godot 4.4.1 / Android

const CITY_SIZE := 100.0
const INNER_LIMIT := 19.0
const OUTER_LIMIT := 48.0

var game: Node3D
var extension_root: Node3D

func _ready() -> void:
	call_deferred("initialize")

func initialize() -> void:
	game = get_parent() as Node3D
	if game == null:
		return

	extension_root = Node3D.new()
	extension_root.name = "ExpandedCityTerrain60"
	add_child(extension_root)

	create_ground()
	create_outer_roads()
	create_outer_trees()
	create_border_markers()

func add_box(
	parent: Node3D,
	pos: Vector3,
	size: Vector3,
	color: Color
) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	node.material_override = material

	parent.add_child(node)
	return node

func add_tree(pos: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.16
	trunk_mesh.bottom_radius = 0.24
	trunk_mesh.height = 1.8
	trunk.mesh = trunk_mesh
	trunk.position = pos + Vector3(0, 0.9, 0)

	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.35, 0.22, 0.12)
	trunk.material_override = wood
	extension_root.add_child(trunk)

	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.25
	crown_mesh.height = 2.5
	crown.mesh = crown_mesh
	crown.position = pos + Vector3(0, 2.45, 0)

	var leaves := StandardMaterial3D.new()
	leaves.albedo_color = Color(
		0.20 + randf_range(0.0, 0.07),
		0.34 + randf_range(0.0, 0.10),
		0.19
	)
	crown.material_override = leaves
	extension_root.add_child(crown)

func create_ground() -> void:
	add_box(
		extension_root,
		Vector3(0, -0.19, 0),
		Vector3(CITY_SIZE, 0.35, CITY_SIZE),
		Color(0.43, 0.55, 0.36)
	)

func create_outer_roads() -> void:
	var road_color := Color(0.70, 0.63, 0.47)

	# East and west district roads.
	for z in [-30.0, 30.0]:
		add_box(
			extension_root,
			Vector3(0, 0.015, z),
			Vector3(86.0, 0.035, 2.6),
			road_color
		)

	# North and south district roads.
	for x in [-30.0, 30.0]:
		add_box(
			extension_root,
			Vector3(x, 0.017, 0),
			Vector3(2.6, 0.035, 86.0),
			road_color
		)

	# Connections between old city and districts.
	for side in [-1.0, 1.0]:
		add_box(
			extension_root,
			Vector3(side * 24.0, 0.02, 6.0),
			Vector3(12.0, 0.04, 2.0),
			road_color
		)
		add_box(
			extension_root,
			Vector3(6.0, 0.02, side * 24.0),
			Vector3(2.0, 0.04, 12.0),
			road_color
		)

func create_outer_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 602026

	for i in range(54):
		var x := rng.randf_range(-46.0, 46.0)
		var z := rng.randf_range(-46.0, 46.0)

		# Preserve the old city center.
		if absf(x) < INNER_LIMIT:
			if absf(z) < INNER_LIMIT:
				continue

		# Keep the new main roads clear.
		if absf(absf(x) - 30.0) < 4.0:
			continue
		if absf(absf(z) - 30.0) < 4.0:
			continue

		# Leave most outer districts open for buildings.
		if i % 3 != 0:
			continue

		add_tree(Vector3(x, 0, z))

func create_border_markers() -> void:
	var stone := Color(0.52, 0.50, 0.44)

	for i in range(-4, 5):
		var p := float(i) * 11.0

		for side in [-1.0, 1.0]:
			add_box(
				extension_root,
				Vector3(p, 0.55, side * OUTER_LIMIT),
				Vector3(0.75, 1.1, 0.75),
				stone
			)

			add_box(
				extension_root,
				Vector3(side * OUTER_LIMIT, 0.55, p),
				Vector3(0.75, 1.1, 0.75),
				stone
			)
