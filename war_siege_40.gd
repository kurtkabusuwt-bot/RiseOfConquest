
extends RefCounted

# RISE OF CONQUEST - SIEGE EFFECTS 7.0
# Godot 4.4.1 / Android

var wall_hp := 160.0
var wall_max := 160.0
var wall_destroyed := false

var castle: Node3D
var wall_mesh: MeshInstance3D
var gate: MeshInstance3D
var battlements: Node3D
var cracks: Node3D
var rubble: Node3D
var effects_root: Node3D

var fragments: Array[Dictionary] = []
var effect_time := 0.0

const STONE := Color(0.52, 0.51, 0.48)
const DARK := Color(0.25, 0.24, 0.23)
const WOOD := Color(0.32, 0.19, 0.11)

func box(
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
	mat.roughness = 0.9
	node.material_override = mat

	parent.add_child(node)
	return node

func build(parent: Node3D) -> void:
	castle = Node3D.new()
	castle.name = "EnemyCastle70"
	parent.add_child(castle)
	castle.position = Vector3(22, 0, 0)

	effects_root = Node3D.new()
	effects_root.name = "SiegeEffects70"
	castle.add_child(effects_root)

	wall_mesh = box(
		castle,
		Vector3(0, 1.6, 0),
		Vector3(3, 3.2, 11),
		STONE
	)

	battlements = Node3D.new()
	castle.add_child(battlements)

	for i in range(9):
		box(
			battlements,
			Vector3(-1.1, 3.5, -5.0 + float(i) * 1.25),
			Vector3(0.9, 0.7, 0.85),
			DARK
		)

	for side in [-5.5, 5.5]:
		box(
			castle,
			Vector3(0, 3.0, side),
			Vector3(3.5, 6.0, 2.4),
			STONE
		)
		box(
			castle,
			Vector3(0, 6.3, side),
			Vector3(4, 0.7, 2.8),
			DARK
		)

		var pole := box(
			castle,
			Vector3(0, 7.6, side),
			Vector3(0.1, 2.1, 0.1),
			WOOD
		)
		pole.name = "FlagPole"

		box(
			castle,
			Vector3(-0.7, 8.0, side),
			Vector3(1.4, 0.8, 0.08),
			Color(0.72, 0.16, 0.14)
		)

	gate = box(
		castle,
		Vector3(-1.58, 1.15, 0),
		Vector3(0.18, 2.3, 2.5),
		WOOD
	)

	cracks = Node3D.new()
	castle.add_child(cracks)

	for i in range(15):
		var z := -4.8 + float(i) * 0.68
		var y := 0.5 + float(i % 5) * 0.5

		var crack := box(
			cracks,
			Vector3(-1.55, y, z),
			Vector3(0.09, 0.48, 0.065),
			Color(0.12, 0.11, 0.10)
		)
		crack.rotation.x = 0.4 if i % 2 == 0 else -0.4

	rubble = Node3D.new()
	castle.add_child(rubble)

	for i in range(30):
		var rock := box(
			rubble,
			Vector3(
				-2.0 - randf_range(0.0, 3.0),
				randf_range(0.12, 0.42),
				randf_range(-5.2, 5.2)
			),
			Vector3(
				randf_range(0.35, 0.9),
				randf_range(0.25, 0.7),
				randf_range(0.35, 0.9)
			),
			STONE.darkened(randf_range(0.0, 0.25))
		)
		rock.rotation.y = randf_range(-1.5, 1.5)

	rubble.visible = false
	cracks.visible = false

func reset(level: int, supplies: bool) -> void:
	wall_max = 160.0 + float(level) * 35.0
	wall_hp = wall_max
	wall_destroyed = false
	effect_time = 0.0

	if supplies:
		wall_hp *= 0.70

	clear_effects()

	wall_mesh.visible = true
	battlements.visible = true
	cracks.visible = false
	rubble.visible = false
	gate.position.y = 1.15
	gate.rotation.z = 0.0

	set_wall_color(STONE)
	update_damage_visuals()

func set_wall_color(color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	wall_mesh.material_override = mat

func damage(amount: float) -> void:
	if wall_destroyed:
		return

	wall_hp = maxf(0.0, wall_hp - maxf(0.0, amount))
	update_damage_visuals()

	if wall_hp <= 0.0:
		collapse()

func update_damage_visuals() -> void:
	var ratio := wall_hp / maxf(1.0, wall_max)

	cracks.visible = ratio < 0.75 and not wall_destroyed
	set_wall_color(
		STONE.darkened((1.0 - ratio) * 0.45)
	)

	var opening := clampf(
		(0.55 - ratio) * 2.0,
		0.0,
		1.0
	)
	gate.position.y = 1.15 + opening * 1.7

func spawn_impact(
	power: float,
	heavy: bool
) -> void:
	if castle == null or wall_destroyed:
		return

	var count := 5
	if heavy:
		count = 12

	for i in range(count):
		var size := randf_range(0.12, 0.32)
		var color := STONE

		if i % 3 == 0:
			color = Color(0.65, 0.60, 0.49)

		var piece := box(
			effects_root,
			Vector3(
				-1.8,
				randf_range(0.8, 3.0),
				randf_range(-4.0, 4.0)
			),
			Vector3(size, size, size),
			color
		)

		fragments.append({
			"node": piece,
			"velocity": Vector3(
				randf_range(-4.0, -1.0),
				randf_range(2.0, 5.0),
				randf_range(-3.0, 3.0)
			),
			"life": randf_range(0.7, 1.4)
		})

func collapse() -> void:
	if wall_destroyed:
		return

	# Spawn fragments before hiding the wall.
	spawn_impact(80.0, true)

	wall_destroyed = true
	wall_hp = 0.0

	wall_mesh.visible = false
	battlements.visible = false
	cracks.visible = false
	rubble.visible = true

	gate.position.y = 3.6
	gate.rotation.z = -0.25

	# Extra debris on collapse.
	for i in range(25):
		var size := randf_range(0.2, 0.6)
		var piece := box(
			effects_root,
			Vector3(
				-1.8,
				randf_range(1.0, 3.5),
				randf_range(-5.0, 5.0)
			),
			Vector3(size, size, size),
			STONE.darkened(randf_range(0.0, 0.3))
		)

		fragments.append({
			"node": piece,
			"velocity": Vector3(
				randf_range(-5.0, -1.0),
				randf_range(2.0, 7.0),
				randf_range(-4.0, 4.0)
			),
			"life": randf_range(1.0, 2.0)
		})

func update_effects(delta: float) -> void:
	for i in range(fragments.size() - 1, -1, -1):
		var fx: Dictionary = fragments[i]
		var node: MeshInstance3D = fx["node"]

		if not is_instance_valid(node):
			fragments.remove_at(i)
			continue

		var velocity: Vector3 = fx["velocity"]
		velocity.y -= 12.0 * delta

		node.position += velocity * delta
		node.rotation += Vector3(
			1.2 * delta,
			1.8 * delta,
			0.9 * delta
		)

		fx["velocity"] = velocity
		fx["life"] = float(fx["life"]) - delta

		if float(fx["life"]) <= 0.0 or node.position.y < 0.0:
			node.queue_free()
			fragments.remove_at(i)

func clear_effects() -> void:
	for fx in fragments:
		var node: MeshInstance3D = fx["node"]
		if is_instance_valid(node):
			node.queue_free()
	fragments.clear()

func summary() -> String:
	if wall_destroyed:
		return "SURLAR YIKILDI | GECIT ACILDI"

	var ratio := wall_hp / maxf(1.0, wall_max)

	if ratio < 0.35:
		return "AGIR HASAR: %d/%d" % [
			int(wall_hp), int(wall_max)
		]

	if ratio < 0.75:
		return "SUR CATLADI: %d/%d" % [
			int(wall_hp), int(wall_max)
		]

	return "SUR: %d/%d" % [
		int(wall_hp), int(wall_max)
	]
