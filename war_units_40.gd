extends RefCounted

# RISE OF CONQUEST - 3D UNITS 4.0

func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.8
	return result

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
	node.material_override = material(color)
	parent.add_child(node)
	return node

func create(
	parent: Node3D,
	kind: String,
	friendly: bool,
	bonus: float = 1.0
) -> Dictionary:
	var root := Node3D.new()
	parent.add_child(root)

	var armor := Color(0.15, 0.36, 0.80)
	if not friendly:
		armor = Color(0.77, 0.17, 0.15)

	var steel := Color(0.70, 0.72, 0.75)
	var leather := Color(0.30, 0.22, 0.15)
	var skin := Color(0.75, 0.56, 0.41)

	var body := Node3D.new()
	root.add_child(body)

	var legs: Array[Node3D] = []
	var arms: Array[Node3D] = []

	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.16, 0.72, 0)
		body.add_child(leg)
		box(
			leg, Vector3(0, -0.35, 0),
			Vector3(0.20, 0.70, 0.23), leather
		)
		legs.append(leg)

		var arm := Node3D.new()
		arm.position = Vector3(side * 0.37, 1.43, 0)
		body.add_child(arm)
		box(
			arm, Vector3(0, -0.31, 0),
			Vector3(0.20, 0.63, 0.22), armor
		)
		arms.append(arm)

	box(
		body, Vector3(0, 1.15, 0),
		Vector3(0.56, 0.82, 0.40), armor
	)
	box(
		body, Vector3(0, 1.73, 0),
		Vector3(0.35, 0.36, 0.33), skin
	)
	box(
		body, Vector3(0, 1.95, 0),
		Vector3(0.54, 0.18, 0.48), steel
	)

	match kind:
		"infantry":
			box(
				arms[0], Vector3(-0.12, -0.4, -0.18),
				Vector3(0.54, 0.66, 0.12), steel
			)
			box(
				arms[1], Vector3(0, -0.67, -0.08),
				Vector3(0.10, 1.0, 0.13), steel
			)
		"archers":
			box(
				arms[1], Vector3(0, -0.6, -0.15),
				Vector3(0.09, 1.1, 0.11), leather
			)
		"cavalry":
			box(
				root, Vector3(0, 0.72, 0.12),
				Vector3(0.77, 0.78, 1.3), leather
			)
			box(
				root, Vector3(0, 1.13, -0.47),
				Vector3(0.45, 0.75, 0.40), leather
			)
			body.position.y = 0.72
		"assassin":
			box(
				body, Vector3(0, 1.94, 0),
				Vector3(0.63, 0.34, 0.52),
				Color(0.12, 0.12, 0.17)
			)
			box(
				arms[1], Vector3(0, -0.55, -0.12),
				Vector3(0.08, 0.80, 0.10), steel
			)
		"siege":
			box(
				arms[1], Vector3(0, -0.72, -0.13),
				Vector3(0.17, 1.35, 0.17), leather
			)
			box(
				arms[1], Vector3(0, -1.30, -0.13),
				Vector3(0.58, 0.33, 0.36), steel
			)

	var hp := 80.0
	var damage := 10.0
	var speed := 2.2
	var reach := 1.2
	var cooldown := 1.0

	match kind:
		"archers":
			hp = 55.0
			damage = 12.0
			speed = 1.7
			reach = 12.0
			cooldown = 1.6
		"cavalry":
			hp = 115.0
			damage = 20.0
			speed = 3.8
			reach = 1.8
		"assassin":
			hp = 65.0
			damage = 23.0
			speed = 3.3
			cooldown = 0.7
		"siege":
			hp = 150.0
			damage = 35.0
			speed = 1.1
			reach = 14.0
			cooldown = 3.0

	return {
		"root": root,
		"body": body,
		"legs": legs,
		"arms": arms,
		"kind": kind,
		"friendly": friendly,
		"hp": hp,
		"damage": damage * bonus,
		"speed": speed,
		"reach": reach,
		"cooldown": cooldown,
		"timer": randf_range(0.0, cooldown),
		"phase": randf_range(0.0, TAU),
		"attack": 0.0,
		"alive": true,
		"fall": 0.0
	}

func animate(
	unit: Dictionary,
	delta: float,
	time: float,
	moving: bool
) -> void:
	var root: Node3D = unit["root"]
	var body: Node3D = unit["body"]

	if not bool(unit["alive"]):
		unit["fall"] = minf(
			1.0, float(unit["fall"]) + delta * 2.0
		)
		var fall: float = float(unit["fall"])
		root.rotation.z = fall * 1.35
		root.position.y = -fall * 0.3
		return

	var legs: Array = unit["legs"]
	var arms: Array = unit["arms"]
	var phase := time * 9.0 + float(unit["phase"])
	var stride := 0.0

	if moving:
		stride = sin(phase) * 0.5

	legs[0].rotation.x = lerpf(
		legs[0].rotation.x, stride, minf(1.0, delta * 10.0)
	)
	legs[1].rotation.x = lerpf(
		legs[1].rotation.x, -stride, minf(1.0, delta * 10.0)
	)

	arms[0].rotation.x = -stride * 0.45
	arms[1].rotation.x = stride * 0.45

	unit["attack"] = maxf(
		0.0, float(unit["attack"]) - delta * 3.0
	)
	arms[1].rotation.x -= float(unit["attack"]) * 1.5
	body.rotation.z = sin(phase * 0.3) * 0.02
