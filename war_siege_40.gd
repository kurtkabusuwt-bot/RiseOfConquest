
extends RefCounted

# RISE OF CONQUEST - SIEGE SYSTEM 4.0

var wall_hp := 160.0
var wall_max := 160.0
var wall_destroyed := false
var battlements: Node3D

func box(
	parent: Node3D,
	pos: Vector3,
	size: Vector3,
	color: Color
) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	node.material_override = mat
	parent.add_child(node)

func build(parent: Node3D) -> void:
	var castle := Node3D.new()
	castle.name = "EnemyCastle40"
	parent.add_child(castle)
	castle.position = Vector3(22, 0, 0)

	var stone := Color(0.48, 0.48, 0.46)
	var dark := Color(0.32, 0.31, 0.30)

	box(
		castle, Vector3(0, 1.5, 0),
		Vector3(3.0, 3.0, 12.0), stone
	)

	battlements = Node3D.new()
	castle.add_child(battlements)

	for i in range(9):
		box(
			battlements,
			Vector3(-0.9, 3.35, -5.2 + float(i) * 1.3),
			Vector3(0.8, 0.7, 0.8), dark
		)

	for side in [-5.5, 5.5]:
		box(
			castle, Vector3(0, 3.0, side),
			Vector3(3.6, 6.0, 2.4), stone
		)
		box(
			castle, Vector3(0, 6.2, side),
			Vector3(4.0, 0.7, 2.8), dark
		)

	box(
		castle, Vector3(-1.6, 1.1, 0),
		Vector3(0.15, 2.2, 2.4),
		Color(0.26, 0.17, 0.10)
	)

func reset(level: int, supplies: bool) -> void:
	wall_max = 160.0 + float(level) * 35.0
	wall_hp = wall_max
	wall_destroyed = false

	if supplies:
		wall_hp *= 0.70

	if battlements != null:
		battlements.visible = true

func damage(amount: float) -> void:
	if wall_destroyed:
		return

	wall_hp = maxf(0.0, wall_hp - amount)

	if wall_hp <= 0.0:
		wall_destroyed = true
		if battlements != null:
			battlements.visible = false

func summary() -> String:
	if wall_destroyed:
		return "SURLAR YIKILDI"
	return "SUR: %d/%d" % [int(wall_hp), int(wall_max)]
