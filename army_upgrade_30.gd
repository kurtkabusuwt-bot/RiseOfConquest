
extends Node3D

# RISE OF CONQUEST 3.0 - PACKAGE 2
# Army visual upgrade and mobile command interface.
# Uses the existing army, resources and save system.

var game: Node3D
var expansion: Node
var old_camp: Node3D
var army_root: Node3D
var units: Array[Node3D] = []
var unit_types: Array[String] = []
var commander: Node3D
var formation := 0
var clock := 0.0
var refresh_timer := 0.0
var army_signature := ""
var ui: CanvasLayer
var panel: PanelContainer
var info: Label
var formation_button: Button

const FORMATIONS := ["HAT", "KARE", "KAMA"]
const MAX_VISIBLE := 18

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	game = get_tree().current_scene as Node3D
	if game == null:
		return
	expansion = game.get_node_or_null("ConquestExpansion")
	if expansion == null:
		return

	old_camp = game.get_node_or_null("RoyalArmyCamp20")
	if old_camp == null:
		await get_tree().process_frame
		old_camp = game.get_node_or_null("RoyalArmyCamp20")

	army_root = Node3D.new()
	army_root.name = "RoyalArmy30"
	if old_camp != null:
		old_camp.add_child(army_root)
	else:
		game.add_child(army_root)
		army_root.position = Vector3(10, 0, 5)

	make_commander()
	create_interface()
	refresh_army()

func mat(color: Color, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = 0.78
	return m

func box_part(
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
	part.material_override = mat(color)
	parent.add_child(part)
	return part

func cylinder_part(
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
	part.material_override = mat(color)
	parent.add_child(part)
	return part

func make_unit(kind: String) -> Node3D:
	var unit := Node3D.new()
	army_root.add_child(unit)

	var armor := Color(0.34, 0.39, 0.47)
	var cloth := Color(0.58, 0.13, 0.15)

	if kind == "archer":
		armor = Color(0.31, 0.43, 0.29)
		cloth = Color(0.37, 0.32, 0.18)
	elif kind == "cavalry":
		armor = Color(0.43, 0.43, 0.49)
		cloth = Color(0.57, 0.17, 0.12)

	var offset := 0.0
	if kind == "cavalry":
		offset = 0.65
		box_part(unit, "HorseBody",
			Vector3(0, 0.85, 0),
			Vector3(0.65, 0.85, 1.35),
			Color(0.39, 0.25, 0.16))
		box_part(unit, "HorseNeck",
			Vector3(0, 1.2, -0.57),
			Vector3(0.38, 0.9, 0.4),
			Color(0.39, 0.25, 0.16))
		box_part(unit, "HorseHead",
			Vector3(0, 1.62, -0.69),
			Vector3(0.42, 0.4, 0.56),
			Color(0.42, 0.27, 0.17))
		for x in [-0.23, 0.23]:
			for z in [-0.43, 0.43]:
				box_part(unit, "HorseLeg",
					Vector3(x, 0.35, z),
					Vector3(0.16, 0.7, 0.18),
					Color(0.30, 0.19, 0.12))

	box_part(unit, "Torso",
		Vector3(0, 1.13 + offset, 0),
		Vector3(0.52, 0.78, 0.38), armor)
	box_part(unit, "Cape",
		Vector3(0, 1.1 + offset, 0.23),
		Vector3(0.48, 0.78, 0.08), cloth)

	cylinder_part(unit, "Head",
		Vector3(0, 1.75 + offset, 0),
		0.23, 0.36, Color(0.73, 0.55, 0.40))
	cylinder_part(unit, "Helmet",
		Vector3(0, 1.98 + offset, 0),
		0.27, 0.27, Color(0.55, 0.57, 0.61))

	for side in [-1.0, 1.0]:
		box_part(unit, "Arm",
			Vector3(side * 0.35, 1.14 + offset, 0),
			Vector3(0.16, 0.62, 0.18), armor)
		if kind != "cavalry":
			box_part(unit, "Leg",
				Vector3(side * 0.15, 0.40, 0),
				Vector3(0.18, 0.75, 0.2), armor)

	if kind == "archer":
		box_part(unit, "Bow",
			Vector3(0.5, 1.15, -0.15),
			Vector3(0.08, 1.15, 0.1),
			Color(0.54, 0.31, 0.14))
		box_part(unit, "Quiver",
			Vector3(-0.24, 1.25, 0.29),
			Vector3(0.25, 0.55, 0.22),
			Color(0.40, 0.23, 0.12))
	else:
		box_part(unit, "Sword",
			Vector3(0.52, 1.18 + offset, -0.1),
			Vector3(0.09, 1.12, 0.13),
			Color(0.73, 0.76, 0.81))
		box_part(unit, "Shield",
			Vector3(-0.5, 1.13 + offset, -0.1),
			Vector3(0.5, 0.68, 0.14),
			Color(0.56, 0.12, 0.15))

	return unit

func make_commander() -> void:
	commander = make_unit("infantry")
	commander.name = "RoyalCommander"
	commander.position = Vector3(0, 0, 3.2)
	commander.scale = Vector3.ONE * 1.2
	box_part(commander, "GoldenCrest",
		Vector3(0, 2.2, 0),
		Vector3(0.15, 0.4, 0.36),
		Color(0.95, 0.72, 0.24))
	box_part(commander, "CommanderBanner",
		Vector3(0, 1.4, 0.32),
		Vector3(0.34, 0.6, 0.08),
		Color(0.83, 0.64, 0.24))

func get_counts() -> Array[int]:
	return [
		maxi(0, int(expansion.get("infantry"))),
		maxi(0, int(expansion.get("archers"))),
		maxi(0, int(expansion.get("cavalry")))
	]

func refresh_army() -> void:
	if expansion == null or army_root == null:
		return

	var counts := get_counts()
	var signature := str(counts)
	if signature == army_signature:
		update_info()
		return
	army_signature = signature

	for unit in units:
		if is_instance_valid(unit):
			unit.queue_free()
	units.clear()
	unit_types.clear()

	var remaining := MAX_VISIBLE
	var kinds := ["infantry", "archer", "cavalry"]

	for i in range(3):
		var count := mini(counts[i], remaining)
		for j in range(count):
			var unit := make_unit(kinds[i])
			units.append(unit)
			unit_types.append(kinds[i])
		remaining -= count

	apply_formation()
	update_info()

func apply_formation() -> void:
	for i in range(units.size()):
		var col := i % 6
		var row := int(i / 6)
		var x := 0.0
		var z := 0.0

		if formation == 0:
			x = (float(col) - 2.5) * 1.55
			z = float(row) * 1.7 - 2.4
		elif formation == 1:
			var square_col := i % 4
			var square_row := int(i / 4)
			x = (float(square_col) - 1.5) * 1.7
			z = float(square_row) * 1.4 - 3.0
		else:
			var wedge_row := int(sqrt(float(i)))
			var first := wedge_row * wedge_row
			var in_row := i - first
			x = (float(in_row) - float(wedge_row)) * 1.3
			z = float(wedge_row) * 1.5 - 3.2

		units[i].position = Vector3(x, 0, z)

func next_formation() -> void:
	formation = (formation + 1) % FORMATIONS.size()
	apply_formation()
	update_info()

func train_unit(kind: String) -> void:
	if expansion == null:
		return
	expansion.call("train", kind)
	army_signature = ""
	refresh_army()

func create_interface() -> void:
	ui = CanvasLayer.new()
	ui.layer = 35
	add_child(ui)

	var open_button := Button.new()
	open_button.text = "ORDU 3.0"
	open_button.position = Vector2(12, 100)
	open_button.custom_minimum_size = Vector2(145, 46)
	ui.add_child(open_button)
	open_button.pressed.connect(toggle_panel)

	panel = PanelContainer.new()
	panel.position = Vector2(12, 153)
	panel.custom_minimum_size = Vector2(295, 0)
	ui.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "KRALIYET ORDUSU"
	content.add_child(heading)

	info = Label.new()
	content.add_child(info)

	formation_button = Button.new()
	formation_button.text = "FORMASYON DEGISTIR"
	content.add_child(formation_button)
	formation_button.pressed.connect(next_formation)

	for item in [
		["5 PIYADE EGIT", "infantry"],
		["5 OKCU EGIT", "archer"],
		["5 SUVARI EGIT", "cavalry"]
	]:
		var button := Button.new()
		button.text = item[0]
		content.add_child(button)
		button.pressed.connect(train_unit.bind(item[1]))

	var close_button := Button.new()
	close_button.text = "KAPAT"
	content.add_child(close_button)
	close_button.pressed.connect(toggle_panel)

	panel.visible = false

func toggle_panel() -> void:
	if panel != null:
		panel.visible = not panel.visible
		update_info()

func update_info() -> void:
	if info == null or expansion == null:
		return
	var counts := get_counts()
	info.text = "Piyade: %d | Okcu: %d\nSuvari: %d | Guc: %d\nFormasyon: %s" % [
		counts[0],
		counts[1],
		counts[2],
		int(expansion.call("army_power")),
		FORMATIONS[formation]
	]

func _process(delta: float) -> void:
	if army_root == null or expansion == null:
		return

	clock += delta
	refresh_timer += delta

	if commander != null:
		commander.rotation.y = sin(clock * 0.45) * 0.25

	for i in range(units.size()):
		if not is_instance_valid(units[i]):
			continue
		var unit := units[i]
		unit.rotation.y = sin(clock * 0.6 + float(i) * 0.4) * 0.08

	if refresh_timer >= 2.0:
		refresh_timer = 0.0
		refresh_army()
