
extends RefCounted

# RISE OF CONQUEST - SIEGE 5.1
# Godot 4.4.1 / Android

var wall_hp := 160.0
var wall_max := 160.0
var wall_destroyed := false

var battlements: Node3D
var castle: Node3D
var gate: MeshInstance3D
var wall_mesh: MeshInstance3D
var rubble: Node3D
var cracks: Node3D
var flags: Array[Node3D] = []

var stone_color := Color(0.48, 0.48, 0.46)
var dark_color := Color(0.31, 0.30, 0.29)
var wood_color := Color(0.28, 0.17, 0.10)

func make_box(
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

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.86
	node.material_override = mat
	parent.add_child(node)
	return node

func make_cylinder(
	parent: Node3D,
	pos: Vector3,
	radius: float,
	height: float,
	color: Color
) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	node.mesh = mesh
	node.position = pos

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.83
	node.material_override = mat
	parent.add_child(node)
	return node

func build(parent: Node3D) -> void:
	castle = Node3D.new()
	castle.name = "EnemyCastle51"
	parent.add_child(castle)
	castle.position = Vector3(22, 0, 0)

	wall_mesh = make_box(
		castle,
		Vector3(0, 1.5, 0),
		Vector3(3.0, 3.0, 12.0),
		stone_color
	)

	battlements = Node3D.new()
	battlements.name = "Battlements"
	castle.add_child(battlements)

	for i in range(9):
		make_box(
			battlements,
			Vector3(
				-0.9,
				3.35,
				-5.2 + float(i) * 1.3
			),
			Vector3(0.8, 0.7, 0.8),
			dark_color
		)

	for side in [-5.5, 5.5]:
		make_box(
			castle,
			Vector3(0, 3.0, side),
			Vector3(3.6, 6.0, 2.4),
			stone_color
		)

		make_box(
			castle,
			Vector3(0, 6.2, side),
			Vector3(4.0, 0.7, 2.8),
			dark_color
		)

		# Tower observation windows.
		for height in [2.1, 4.0]:
			make_box(
				castle,
				Vector3(-1.84, height, side),
				Vector3(0.09, 0.55, 0.30),
				Color(0.10, 0.10, 0.12)
			)

		# Flagpole.
		make_cylinder(
			castle,
			Vector3(0, 7.65, side),
			0.07, 2.6,
			Color(0.36, 0.25, 0.15)
		)

		var flag := Node3D.new()
		flag.position = Vector3(0, 8.4, side)
		castle.add_child(flag)

		make_box(
			flag,
			Vector3(-0.65, 0, 0),
			Vector3(1.3, 0.8, 0.07),
			Color(0.68, 0.15, 0.13)
		)
		flags.append(flag)

	gate = make_box(
		castle,
		Vector3(-1.60, 1.1, 0),
		Vector3(0.15, 2.2, 2.4),
		wood_color
	)

	# Gate reinforcement.
	for z in [-0.75, 0.0, 0.75]:
		make_box(
			gate,
			Vector3(-0.58, 0, z),
			Vector3(0.07, 0.15, 0.15),
			Color(0.19, 0.18, 0.17)
		)

	cracks = Node3D.new()
	cracks.name = "WallCracks"
	castle.add_child(cracks)

	for i in range(12):
		var z := -4.7 + float(i) * 0.82
		var y := 0.7 + float(i % 4) * 0.55

		var crack := make_box(
			cracks,
			Vector3(-1.53, y, z),
			Vector3(0.08, 0.55, 0.055),
			Color(0.16, 0.15, 0.14)
		)
		crack.rotation.x = (
			0.35 if i % 2 == 0 else -0.4
		)

	cracks.visible = false

	rubble = Node3D.new()
	rubble.name = "WallRubble"
	castle.add_child(rubble)

	for i in range(20):
		var rock := make_box(
			rubble,
			Vector3(
				-2.0 - randf_range(0.0, 2.5),
				0.16 + randf_range(0.0, 0.28),
				randf_range(-5.5, 5.5)
			),
			Vector3(
				randf_range(0.3, 0.8),
				randf_range(0.3, 0.65),
				randf_range(0.3, 0.8)
			),
			stone_color.darkened(
				randf_range(0.0, 0.22)
			)
		)
		rock.rotation = Vector3(
			randf_range(-0.4, 0.4),
			randf_range(-1.0, 1.0),
			randf_range(-0.4, 0.4)
		)

	rubble.visible = false

func reset(level: int, supplies: bool) -> void:
	wall_max = 160.0 + float(level) * 35.0
	wall_hp = wall_max
	wall_destroyed = false

	if supplies:
		wall_hp *= 0.70

	if battlements != null:
		battlements.visible = true

	if cracks != null:
		cracks.visible = false

	if rubble != null:
		rubble.visible = false

	if gate != null:
		gate.rotation.z = 0.0
		gate.position.y = 1.1

	if wall_mesh != null:
		wall_mesh.visible = true
		wall_mesh.material_override = wall_material(
			stone_color
		)

	update_damage_visuals()

func wall_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.86
	return mat

func damage(amount: float) -> void:
	if wall_destroyed:
		return

	wall_hp = maxf(0.0, wall_hp - amount)
	update_damage_visuals()

	if wall_hp <= 0.0:
		collapse()

func update_damage_visuals() -> void:
	if wall_max <= 0.0:
		return

	var ratio := wall_hp / wall_max

	if cracks != null:
		cracks.visible = ratio < 0.72

	if wall_mesh != null:
		var darkness := (1.0 - ratio) * 0.35
		wall_mesh.material_override = wall_material(
			stone_color.darkened(darkness)
		)

	if gate != null:
		var opening := clampf(
			(0.45 - ratio) * 2.0,
			0.0, 1.0
		)
		gate.position.y = 1.1 + opening * 1.5

func collapse() -> void:
	if wall_destroyed:
		return

	wall_destroyed = true

	if battlements != null:
		battlements.visible = false

	if rubble != null:
		rubble.visible = true

	if cracks != null:
		cracks.visible = false

	if wall_mesh != null:
		wall_mesh.visible = false

	if gate != null:
		gate.position.y = 3.0

func summary() -> String:
	if wall_destroyed:
		return "SURLAR YIKILDI"

	var ratio := wall_hp / maxf(1.0, wall_max)

	if ratio < 0.35:
		return "SUR AGIR HASAR: %d/%d" % [
			int(wall_hp), int(wall_max)
		]

	if ratio < 0.72:
		return "SUR CATLADI: %d/%d" % [
			int(wall_hp), int(wall_max)
		]

	return "SUR: %d/%d" % [
		int(wall_hp), int(wall_max)
	]
