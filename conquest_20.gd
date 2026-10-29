
extends Node3D

# RISE OF CONQUEST 3.0
# Army camp, patrols, banners, torches and victory effects.
# Existing gameplay and saves remain unchanged.

var expansion: Node
var game: Node3D
var camp: Node3D
var patrols: Array[Node3D] = []
var flags: Array[Node3D] = []
var fires: Array[OmniLight3D] = []
var particles: Array[Node3D] = []
var clock := 0.0
var last_victories := 0
var troop_count := -1
var troop_timer := 0.0
var effect_timer := 0.0

func _ready() -> void:
	call_deferred("initialize")

func initialize() -> void:
	game = get_tree().current_scene as Node3D
	if game == null:
		return
	expansion = game.get_node_or_null("ConquestExpansion")
	if expansion == null:
		return

	camp = Node3D.new()
	camp.name = "RoyalArmyCamp20"
	game.add_child(camp)
	camp.position = Vector3(10, 0, 5)

	create_camp()
	create_patrols()
	last_victories = int(expansion.victories)
	refresh_army()

func material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = 0.72
	return mat

func cube(parent: Node3D, name_text: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = name_text
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = pos
	part.material_override = material(color)
	parent.add_child(part)
	return part

func cylinder(parent: Node3D, name_text: String, radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = name_text
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	part.mesh = mesh
	part.position = pos
	part.material_override = material(color)
	parent.add_child(part)
	return part

func sphere(parent: Node3D, name_text: String, radius: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = name_text
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	part.mesh = mesh
	part.position = pos
	part.material_override = material(color)
	parent.add_child(part)
	return part

func create_camp() -> void:
	var earth := Color(0.32, 0.29, 0.22)
	var stone := Color(0.48, 0.47, 0.42)
	var wood := Color(0.28, 0.17, 0.10)
	var gold := Color(0.82, 0.66, 0.30)
	var red := Color(0.49, 0.09, 0.12)

	cube(camp, "CampGround", Vector3(15, 0.15, 15), Vector3(0, 0.03, 0), earth)

	for i in range(9):
		var x := -6.0 + float(i) * 1.5
		cube(camp, "TrainingFloor", Vector3(0.13, 0.03, 13), Vector3(x, 0.12, 0), stone)

	for side in [-1, 1]:
		for i in range(5):
			var z := -5.5 + float(i) * 2.7
			cylinder(camp, "Palisade", 0.22, 2.5, Vector3(float(side) * 7.1, 1.3, z), wood)
			cube(camp, "PalisadeTip", Vector3(0.45, 0.3, 0.45), Vector3(float(side) * 7.1, 2.7, z), wood)

	for i in range(3):
		var x := -4.2 + float(i) * 4.2
		var tent := Node3D.new()
		tent.name = "SoldierTent"
		tent.position = Vector3(x, 0, -4.8)
		camp.add_child(tent)
		cube(tent, "TentBase", Vector3(3.2, 1.2, 2.8), Vector3(0, 0.7, 0), Color(0.60, 0.51, 0.35))
		var roof := cube(tent, "TentRoof", Vector3(3.6, 0.3, 3.0), Vector3(0, 1.55, 0), red)
		roof.rotation.z = 0.08
		cube(tent, "TentDoor", Vector3(0.8, 1.0, 0.08), Vector3(0, 0.65, 1.45), wood)

	for i in range(4):
		var x := -5.5 + float(i) * 3.7
		make_banner(Vector3(x, 0, 6.2), red, gold)

	make_torch(Vector3(-6.0, 0, -1.0))
	make_torch(Vector3(6.0, 0, -1.0))
	make_torch(Vector3(-6.0, 0, 5.0))
	make_torch(Vector3(6.0, 0, 5.0))

	cube(camp, "CommandTable", Vector3(2.0, 0.2, 1.3), Vector3(0, 1.0, 2.2), wood)
	for x in [-0.75, 0.75]:
		for z in [-0.45, 0.45]:
			cube(camp, "TableLeg", Vector3(0.16, 0.9, 0.16), Vector3(x, 0.5, 2.2 + z), wood)

func make_banner(pos: Vector3, cloth: Color, trim: Color) -> void:
	var banner := Node3D.new()
	banner.position = pos
	camp.add_child(banner)
	cylinder(banner, "Pole", 0.065, 4.5, Vector3(0, 2.25, 0), Color(0.30, 0.24, 0.16))
	cube(banner, "GoldTip", Vector3(0.23, 0.25, 0.23), Vector3(0, 4.58, 0), trim)
	cube(banner, "Flag", Vector3(1.6, 0.95, 0.08), Vector3(0.8, 3.7, 0), cloth)
	cube(banner, "FlagEmblem", Vector3(0.32, 0.32, 0.10), Vector3(0.8, 3.7, 0), trim)
	flags.append(banner)

func make_torch(pos: Vector3) -> void:
	var torch := Node3D.new()
	torch.position = pos
	camp.add_child(torch)
	cylinder(torch, "WoodPole", 0.09, 2.0, Vector3(0, 1.0, 0), Color(0.25, 0.15, 0.09))
	sphere(torch, "Flame", 0.24, Vector3(0, 2.18, 0), Color(1.0, 0.38, 0.06))
	var light := OmniLight3D.new()
	light.position = Vector3(0, 2.2, 0)
	light.light_color = Color(1.0, 0.49, 0.17)
	light.light_energy = 0.65
	light.omni_range = 5.5
	torch.add_child(light)
	fires.append(light)

func create_soldier(pos: Vector3, archer: bool = false) -> Node3D:
	var soldier := Node3D.new()
	soldier.position = pos
	camp.add_child(soldier)

	var armor := Color(0.29, 0.34, 0.43)
	if archer:
		armor = Color(0.30, 0.40, 0.27)

	cube(soldier, "Body", Vector3(0.55, 0.8, 0.35), Vector3(0, 1.15, 0), armor)
	sphere(soldier, "Head", 0.25, Vector3(0, 1.85, 0), Color(0.73, 0.53, 0.37))
	cylinder(soldier, "Helmet", 0.27, 0.25, Vector3(0, 2.03, 0), Color(0.45, 0.47, 0.49))
	cube(soldier, "LeftLeg", Vector3(0.18, 0.65, 0.20), Vector3(-0.16, 0.42, 0), armor)
	cube(soldier, "RightLeg", Vector3(0.18, 0.65, 0.20), Vector3(0.16, 0.42, 0), armor)
	cube(soldier, "LeftArm", Vector3(0.17, 0.65, 0.19), Vector3(-0.37, 1.18, 0), armor)
	cube(soldier, "RightArm", Vector3(0.17, 0.65, 0.19), Vector3(0.37, 1.18, 0), armor)

	if archer:
		cube(soldier, "Bow", Vector3(0.06, 1.2, 0.08), Vector3(0.52, 1.18, 0), Color(0.48, 0.27, 0.11))
	else:
		cube(soldier, "Sword", Vector3(0.09, 1.1, 0.12), Vector3(0.48, 1.05, 0), Color(0.72, 0.74, 0.77))
		cube(soldier, "Shield", Vector3(0.55, 0.7, 0.12), Vector3(-0.48, 1.15, -0.05), Color(0.53, 0.12, 0.13))

	return soldier

func create_patrols() -> void:
	for i in range(4):
		var soldier := create_soldier(Vector3(-5.0 + float(i) * 2.6, 0, 3.5))
		patrols.append(soldier)

func refresh_army() -> void:
	if expansion == null:
		return

	var total := int(expansion.infantry) + int(expansion.archers) + int(expansion.cavalry)
	var desired := mini(16, total)
	if desired == troop_count:
		return

	for child in camp.get_children():
		if child.name.begins_with("ArmyUnit"):
			child.queue_free()

	troop_count = desired
	for i in range(desired):
		var row := int(i / 4)
		var column := i % 4
		var unit := create_soldier(Vector3(-4.4 + float(column) * 2.9, 0, -1.8 + float(row) * 1.25), i % 3 == 0)
		unit.name = "ArmyUnit%d" % i

func battle_effect() -> void:
	for i in range(9):
		var burst := Node3D.new()
		burst.position = Vector3(randf_range(-4.0, 4.0), randf_range(0.7, 2.5), randf_range(-2.0, 3.0))
		camp.add_child(burst)
		sphere(burst, "VictorySpark", 0.13, Vector3.ZERO, Color(1.0, 0.72, 0.18))
		particles.append(burst)
	effect_timer = 2.0

func _process(delta: float) -> void:
	if camp == null or expansion == null:
		return

	clock += delta
	troop_timer += delta

	for i in range(patrols.size()):
		var soldier := patrols[i]
		var phase := clock * 0.65 + float(i) * 1.57
		soldier.position.x = sin(phase) * 4.8
		soldier.position.z = 3.5 + cos(phase) * 0.8
		soldier.rotation.y = phase + PI * 0.5

	for i in range(flags.size()):
		flags[i].rotation.y = sin(clock * 1.4 + float(i)) * 0.09

	for i in range(fires.size()):
		fires[i].light_energy = 0.55 + sin(clock * 9.0 + float(i)) * 0.15

	if troop_timer >= 2.0:
		troop_timer = 0.0
		refresh_army()

	var victories := int(expansion.victories)
	if victories > last_victories:
		battle_effect()
	last_victories = victories

	if effect_timer > 0.0:
		effect_timer -= delta
		for i in range(particles.size()):
			if is_instance_valid(particles[i]):
				particles[i].position.y += delta * (0.8 + float(i) * 0.1)
		if effect_timer <= 0.0:
			for p in particles:
				if is_instance_valid(p):
					p.queue_free()
			particles.clear()
