
extends Node3D

# RISE OF CONQUEST - SAVAS 4.0
# 3D savas, hareket, hasar, kusatma, komutan ve arastirma.
# Onceki savas kayitlari korunur.

const SAVE_PATH := "user://roc_war_31.json"
const TYPES := ["infantry", "archers", "cavalry", "assassin", "siege"]
const FORMATIONS := ["HAT", "KARE", "KAMA"]
const ORDERS := ["SALDIR", "SAVUN", "HUCUM"]
const POWERS := [10, 15, 30, 42, 55]

var game: Node3D
var expansion: Node
var kingdom: Node

var extra_army := {"assassin": 0, "siege": 0}
var formation := 0
var order := 0
var conquered := 0
var war_wins := 0
var war_losses := 0
var last_report := "Ordu savasa hazir."

var fighting := false
var battle_time := 0.0
var battle_limit := 35.0
var current_enemy := ""
var enemy_power := 0
var our_power := 0

var initial_blue := 0
var initial_red := 0
var blue_fallen := 0
var red_fallen := 0

var wall_hp := 160.0
var wall_max := 160.0
var wall_destroyed := false
var used_siege_supply := false

var battlefield: Node3D
var battle_camera: Camera3D
var city_camera: Camera3D
var city_transform := Transform3D.IDENTITY
var city_fov := 55.0

var castle_root: Node3D
var castle_wall: Node3D

var blue_units: Array[Dictionary] = []
var red_units: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var effects: Array[Dictionary] = []

var ui: CanvasLayer
var panel: PanelContainer
var stats_label: Label
var report_label: Label
var battle_label: Label
var battle_hud: PanelContainer
var hud_label: Label
var battle_button: Button
var formation_button: Button
var order_button: Button

func _ready() -> void:
	call_deferred("initialize")

func initialize() -> void:
	game = get_tree().current_scene as Node3D
	if game == null:
		return

	expansion = game.get_node_or_null("ConquestExpansion")
	kingdom = game.get_node_or_null("WarExpansion45")

	if expansion == null:
		return

	load_war()
	build_battlefield()
	build_ui()
	update_panel()

func resource_value(key: String) -> int:
	return int(game.get(key))

func can_pay(cost: Dictionary) -> bool:
	for key in cost:
		if resource_value(str(key)) < int(cost[key]):
			last_report = "Yetersiz kaynak: " + str(key)
			update_panel()
			return false
	return true

func pay(cost: Dictionary) -> void:
	for key in cost:
		game.set(key, resource_value(str(key)) - int(cost[key]))
	game.call("update_ui")

func reward(values: Dictionary) -> void:
	for key in values:
		game.set(key, resource_value(str(key)) + int(values[key]))
	game.call("update_ui")

func army_count(kind: String) -> int:
	if extra_army.has(kind):
		return int(extra_army[kind])
	return int(expansion.get(kind))

func total_army() -> int:
	var total := 0
	for kind in TYPES:
		total += army_count(str(kind))
	return total

func kingdom_bonus() -> float:
	if kingdom == null:
		return 1.0
	if not kingdom.has_method("military_bonus"):
		return 1.0
	return float(kingdom.call("military_bonus"))

func army_power() -> int:
	var power := 0

	for i in range(TYPES.size()):
		power += army_count(str(TYPES[i])) * int(POWERS[i])

	power += int(expansion.get("castle_level")) * 5

	match formation:
		0:
			power += army_count("archers") * 2
		1:
			power += army_count("infantry") * 3
		2:
			power += army_count("cavalry") * 5

	power += mini(army_count("assassin"), 20) * 3

	return int(float(power) * kingdom_bonus())

func train_special(kind: String) -> void:
	if fighting:
		return

	if int(game.get("barracks_count")) <= 0:
		last_report = "Once kisla insa et."
		update_panel()
		return

	var castle := int(expansion.get("castle_level"))
	var cost: Dictionary = {}

	if kind == "assassin":
		if castle < 3:
			last_report = "Suikastci icin kale 3 gerekli."
			update_panel()
			return
		cost = {"coins": 120, "foods": 70}

	elif kind == "siege":
		if castle < 4:
			last_report = "Kusatma icin kale 4 gerekli."
			update_panel()
			return
		cost = {"woods": 160, "stones": 110, "coins": 100}
	else:
		return

	if not can_pay(cost):
		return

	pay(cost)
	extra_army[kind] = army_count(kind) + 2

	last_report = "2 birlik egitildi: " + kind
	save_war()
	update_panel()

func next_formation() -> void:
	if fighting:
		return

	formation = (formation + 1) % FORMATIONS.size()
	save_war()
	update_panel()

func next_order() -> void:
	order = (order + 1) % ORDERS.size()

	if not fighting:
		save_war()

	update_panel()

func make_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.78
	return mat

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
	node.material_override = make_material(color)
	parent.add_child(node)
	return node

func add_cylinder(
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
	node.material_override = make_material(color)
	parent.add_child(node)
	return node

func build_battlefield() -> void:
	battlefield = Node3D.new()
	battlefield.name = "Battlefield40"
	game.add_child(battlefield)
	battlefield.position = Vector3(0, 0, -85)

	add_box(
		battlefield,
		Vector3(0, -0.22, 0),
		Vector3(54, 0.4, 40),
		Color(0.34, 0.38, 0.27)
	)

	for side in [-1.0, 1.0]:
		for i in range(5):
			var x: float = float(side) * 24.0
			var z: float = -15.0 + float(i) * 7.5

			add_cylinder(
				battlefield,
				Vector3(x, 1.5, z),
				0.22, 3.0,
				Color(0.38, 0.25, 0.14)
			)

			var flag_color := Color(0.68, 0.16, 0.14)

			if side < 0:
				flag_color = Color(0.16, 0.36, 0.78)

			add_box(
				battlefield,
				Vector3(x + 0.5, 2.2, z),
				Vector3(1.0, 0.75, 0.08),
				flag_color
			)

	for i in range(8):
		add_box(
			battlefield,
			Vector3(0, 0.012, -15.0 + float(i) * 4.3),
			Vector3(0.08, 0.025, 1.5),
			Color(0.67, 0.58, 0.39)
		)

	build_castle()

	battle_camera = Camera3D.new()
	battlefield.add_child(battle_camera)
	battle_camera.position = Vector3(0, 23, 29)
	battle_camera.look_at(battlefield.global_position)
	battle_camera.fov = 60
	battle_camera.current = false

	battlefield.visible = false

func build_castle() -> void:
	castle_root = Node3D.new()
	battlefield.add_child(castle_root)
	castle_root.position = Vector3(22, 0, 0)

	var stone := Color(0.48, 0.48, 0.46)
	var dark := Color(0.32, 0.31, 0.30)

	add_box(
		castle_root,
		Vector3(0, 1.4, 0),
		Vector3(3.0, 2.8, 12.0),
		stone
	)

	castle_wall = Node3D.new()
	castle_root.add_child(castle_wall)

	for i in range(9):
		add_box(
			castle_wall,
			Vector3(-0.9, 3.1, -5.3 + float(i) * 1.3),
			Vector3(0.8, 0.8, 0.8),
			dark
		)

	for z in [-5.6, 5.6]:
		add_box(
			castle_root,
			Vector3(0, 3.0, z),
			Vector3(3.6, 6.0, 2.4),
			stone
		)

		add_box(
			castle_root,
			Vector3(0, 6.2, z),
			Vector3(4.0, 0.7, 2.8),
			dark
		)

	add_box(
		castle_root,
		Vector3(-1.55, 1.15, 0),
		Vector3(0.15, 2.3, 2.4),
		Color(0.24, 0.16, 0.09)
	)

func create_soldier(kind: String, friendly: bool) -> Dictionary:
	var root := Node3D.new()
	battlefield.add_child(root)

	var armor := Color(0.18, 0.38, 0.79)

	if not friendly:
		armor = Color(0.77, 0.17, 0.14)

	var steel := Color(0.69, 0.70, 0.73)
	var leather := Color(0.31, 0.22, 0.15)
	var skin := Color(0.72, 0.55, 0.39)

	var body := Node3D.new()
	root.add_child(body)

	var left_leg := Node3D.new()
	left_leg.position = Vector3(-0.16, 0.7, 0)
	body.add_child(left_leg)

	var right_leg := Node3D.new()
	right_leg.position = Vector3(0.16, 0.7, 0)
	body.add_child(right_leg)

	add_box(
		left_leg, Vector3(0, -0.34, 0),
		Vector3(0.19, 0.7, 0.21), leather
	)

	add_box(
		right_leg, Vector3(0, -0.34, 0),
		Vector3(0.19, 0.7, 0.21), leather
	)

	add_box(
		body, Vector3(0, 1.1, 0),
		Vector3(0.53, 0.78, 0.38), armor
	)

	add_cylinder(
		body, Vector3(0, 1.7, 0),
		0.23, 0.36, skin
	)

	add_box(
		body, Vector3(0, 1.92, 0),
		Vector3(0.51, 0.17, 0.46), steel
	)

	var left_arm := Node3D.new()
	left_arm.position = Vector3(-0.35, 1.42, 0)
	body.add_child(left_arm)

	var right_arm := Node3D.new()
	right_arm.position = Vector3(0.35, 1.42, 0)
	body.add_child(right_arm)

	add_box(
		left_arm, Vector3(0, -0.33, 0),
		Vector3(0.18, 0.65, 0.19), armor
	)

	add_box(
		right_arm, Vector3(0, -0.33, 0),
		Vector3(0.18, 0.65, 0.19), armor
	)

	if kind == "infantry":
		add_box(
			left_arm,
			Vector3(-0.1, -0.45, -0.18),
			Vector3(0.55, 0.66, 0.12),
			steel
		)

	if kind == "archers":
		add_box(
			right_arm,
			Vector3(0, -0.55, -0.2),
			Vector3(0.08, 1.2, 0.10),
			leather
		)
	elif kind == "siege":
		add_box(
			right_arm,
			Vector3(0, -0.7, -0.15),
			Vector3(0.18, 1.3, 0.16),
			leather
		)

		add_box(
			right_arm,
			Vector3(0, -1.3, -0.15),
			Vector3(0.55, 0.30, 0.35),
			steel
		)
	else:
		add_box(
			right_arm,
			Vector3(0, -0.65, -0.1),
			Vector3(0.09, 1.0, 0.13),
			steel
		)

	if kind == "assassin":
		add_box(
			body,
			Vector3(0, 1.91, 0.06),
			Vector3(0.62, 0.32, 0.53),
			Color(0.13, 0.13, 0.17)
		)

	if kind == "cavalry":
		add_box(
			root,
			Vector3(0, 0.72, 0.1),
			Vector3(0.72, 0.75, 1.25),
			leather
		)

		add_box(
			root,
			Vector3(0, 1.14, -0.44),
			Vector3(0.42, 0.72, 0.37),
			leather
		)

		body.position.y = 0.75

	var hp := 80.0
	var damage := 10.0
	var speed := 2.1
	var reach := 1.15
	var cooldown := 1.0

	match kind:
		"archers":
			hp = 55.0
			damage = 12.0
			speed = 1.6
			reach = 12.0
			cooldown = 1.6

		"cavalry":
			hp = 115.0
			damage = 20.0
			speed = 3.8
			reach = 1.8
			cooldown = 1.1

		"assassin":
			hp = 65.0
			damage = 23.0
			speed = 3.3
			reach = 1.2
			cooldown = 0.7

		"siege":
			hp = 150.0
			damage = 35.0
			speed = 1.0
			reach = 14.0
			cooldown = 3.0

	if friendly:
		damage *= kingdom_bonus()

	return {
		"root": root,
		"body": body,
		"left_leg": left_leg,
		"right_leg": right_leg,
		"left_arm": left_arm,
		"right_arm": right_arm,
		"kind": kind,
		"friendly": friendly,
		"hp": hp,
		"damage": damage,
		"speed": speed,
		"reach": reach,
		"cooldown": cooldown,
		"timer": randf_range(0.0, cooldown),
		"phase": randf_range(0.0, TAU),
		"alive": true,
		"fall": 0.0,
		"attack_anim": 0.0,
		"moving": false
	}

func clear_battle() -> void:
	for unit in blue_units:
		var root: Node3D = unit["root"]
		if is_instance_valid(root):
			root.queue_free()

	for unit in red_units:
		var root: Node3D = unit["root"]
		if is_instance_valid(root):
			root.queue_free()

	for shot in projectiles:
		var node: Node3D = shot["node"]
		if is_instance_valid(node):
			node.queue_free()

	for fx in effects:
		var node: Node3D = fx["node"]
		if is_instance_valid(node):
			node.queue_free()

	blue_units.clear()
	red_units.clear()
	projectiles.clear()
	effects.clear()

func deploy_armies() -> void:
	clear_battle()

	var remaining := 25

	for i in range(TYPES.size()):
		var kind: String = str(TYPES[i])
		var count := mini(army_count(kind), remaining)

		for j in range(count):
			blue_units.append(create_soldier(kind, true))

		remaining -= count

	var enemy_count := mini(25, 12 + conquered * 2)

	for i in range(enemy_count):
		var kind: String = str(TYPES[i % 4])
		red_units.append(create_soldier(kind, false))

	for i in range(blue_units.size()):
		var unit: Dictionary = blue_units[i]
		var root: Node3D = unit["root"]

		var x := -13.0 + float(i % 5) * 1.55
		var z := -9.0 + float(int(i / 5)) * 2.1

		if formation == 1:
			x = -14.0 + float(i % 4) * 1.7
			z = -8.0 + float(int(i / 4)) * 1.5

		elif formation == 2:
			var row := int(sqrt(float(i)))
			x = -14.0 + float(row) * 1.7
			z = -8.0 + float(i - row * row - row) * 1.6

		root.position = Vector3(x, 0, z)

	for i in range(red_units.size()):
		var unit: Dictionary = red_units[i]
		var root: Node3D = unit["root"]

		root.position = Vector3(
			12.0 + float(i % 4) * 1.5,
			0,
			-8.0 + float(int(i / 4)) * 1.8
		)

	initial_blue = blue_units.size()
	initial_red = red_units.size()

	blue_fallen = 0
	red_fallen = 0

	wall_max = 160.0 + float(conquered) * 35.0
	wall_hp = wall_max
	wall_destroyed = false

	castle_wall.visible = true

func open_battle_view() -> void:
	battlefield.visible = true

	city_camera = get_viewport().get_camera_3d()

	if city_camera != null:
		city_transform = city_camera.global_transform
		city_fov = city_camera.fov

		city_camera.global_transform = battle_camera.global_transform
		city_camera.fov = battle_camera.fov
	else:
		battle_camera.make_current()

	panel.visible = false
	battle_hud.visible = true

func keep_battle_camera() -> void:
	if city_camera == null:
		return

	if not is_instance_valid(city_camera):
		return

	city_camera.global_transform = battle_camera.global_transform

func close_battle_view() -> void:
	if city_camera != null and is_instance_valid(city_camera):
		city_camera.global_transform = city_transform
		city_camera.fov = city_fov
		city_camera.make_current()
	else:
		battle_camera.current = false

	battlefield.visible = false
	battle_hud.visible = false

func begin_battle() -> void:
	if fighting:
		return

	if total_army() < 5:
		last_report = "En az 5 asker gerekli."
		update_panel()
		return

	if not can_pay({"foods": 35}):
		return

	pay({"foods": 35})

	var targets := [
		"Sinir Karakolu",
		"Orman Hisari",
		"Tas Kalesi",
		"Kuzey Garnizonu",
		"Kraliyet Kalesi"
	]

	current_enemy = str(targets[conquered % targets.size()])
	enemy_power = 100 + conquered * 90 + war_wins * 15
	our_power = army_power()

	used_siege_supply = false

	if kingdom != null:
		var supplies := int(kingdom.get("siege_supplies"))

		if supplies > 0:
			kingdom.set("siege_supplies", supplies - 1)
			kingdom.call("save_data")
			used_siege_supply = true

	fighting = true
	battle_time = 0.0
	order = 0

	deploy_armies()

	if used_siege_supply:
		wall_hp *= 0.70

	open_battle_view()

	last_report = "Savas basladi: " + current_enemy
	update_panel()

func closest_enemy(
	unit: Dictionary,
	opponents: Array[Dictionary]
) -> Dictionary:
	var root: Node3D = unit["root"]
	var best: Dictionary = {}
	var best_distance := 99999.0

	for enemy in opponents:
		if not bool(enemy["alive"]):
			continue

		var target: Node3D = enemy["root"]
		var distance := root.position.distance_to(target.position)

		if distance < best_distance:
			best_distance = distance
			best = enemy

	return best

func count_alive(units: Array[Dictionary]) -> int:
	var count := 0

	for unit in units:
		if bool(unit["alive"]):
			count += 1

	return count

func create_effect(pos: Vector3, color: Color) -> void:
	var node := Node3D.new()
	battlefield.add_child(node)
	node.position = pos

	for i in range(4):
		var particle := add_box(
			node,
			Vector3(
				randf_range(-0.3, 0.3),
				randf_range(0.2, 1.0),
				randf_range(-0.3, 0.3)
			),
			Vector3(0.12, 0.12, 0.12),
			color
		)

		particle.rotation.z = randf_range(-1.0, 1.0)

	effects.append({
		"node": node,
		"life": 0.45
	})

func damage_wall(amount: float) -> void:
	if wall_destroyed:
		return

	wall_hp = maxf(0.0, wall_hp - amount)

	create_effect(
		Vector3(20.3, 2.0, randf_range(-4.0, 4.0)),
		Color(0.75, 0.58, 0.36)
	)

	if wall_hp <= 0.0:
		wall_destroyed = true
		castle_wall.visible = false

		create_effect(
			Vector3(20.0, 2.0, 0),
			Color(1.0, 0.45, 0.12)
		)

func launch_projectile(
	from: Vector3,
	to: Vector3,
	friendly: bool,
	damage: float,
	target: Dictionary,
	siege: bool
) -> void:
	var node := Node3D.new()
	battlefield.add_child(node)
	node.position = from

	var color := Color(0.81, 0.66, 0.31)
	var size := Vector3(0.10, 0.10, 0.8)

	if siege:
		color = Color(0.28, 0.26, 0.24)
		size = Vector3(0.48, 0.48, 0.48)

	add_box(node, Vector3.ZERO, size, color)

	projectiles.append({
		"node": node,
		"destination": to,
		"speed": 18.0 if not siege else 11.0,
		"friendly": friendly,
		"damage": damage,
		"target": target,
		"siege": siege
	})

func deal_damage(target: Dictionary, amount: float) -> void:
	if not bool(target["alive"]):
		return

	target["hp"] = float(target["hp"]) - amount

	var root: Node3D = target["root"]

	create_effect(
		root.position + Vector3(0, 1.2, 0),
		Color(1.0, 0.53, 0.15)
	)

	if float(target["hp"]) <= 0.0:
		target["alive"] = false
		target["fall"] = 0.0

		if bool(target["friendly"]):
			blue_fallen += 1
		else:
			red_fallen += 1

func update_unit(
	unit: Dictionary,
	opponents: Array[Dictionary],
	delta: float
) -> void:
	var root: Node3D = unit["root"]
	var body: Node3D = unit["body"]
	var left_leg: Node3D = unit["left_leg"]
	var right_leg: Node3D = unit["right_leg"]
	var left_arm: Node3D = unit["left_arm"]
	var right_arm: Node3D = unit["right_arm"]

	if not bool(unit["alive"]):
		unit["fall"] = minf(
			float(unit["fall"]) + delta * 2.0,
			1.0
		)

		var fall: float = float(unit["fall"])
		root.rotation.z = lerpf(
			root.rotation.z, 1.35, fall
		)
		root.position.y = -fall * 0.35
		return

	unit["timer"] = float(unit["timer"]) - delta

	unit["attack_anim"] = maxf(
		0.0,
		float(unit["attack_anim"]) - delta * 3.0
	)

	var target := closest_enemy(unit, opponents)

	if target.is_empty():
		return

	var target_root: Node3D = target["root"]
	var direction := target_root.position - root.position
	direction.y = 0.0

	var distance := direction.length()
	var reach: float = float(unit["reach"])
	var kind: String = str(unit["kind"])
	var friendly: bool = bool(unit["friendly"])

	var move_allowed := true

	if friendly and order == 1:
		move_allowed = distance > reach + 3.0

	var move_speed: float = float(unit["speed"])

	if friendly and order == 2:
		move_speed *= 1.4

	if distance > reach and move_allowed:
		var step := minf(
			distance - reach,
			move_speed * delta
		)

		root.position += direction.normalized() * step
		unit["moving"] = true
	else:
		unit["moving"] = false

	if direction.length() > 0.01:
		root.rotation.y = atan2(
			-direction.x, -direction.z
		)

	var phase: float = (
		battle_time * 9.0 + float(unit["phase"])
	)

	if bool(unit["moving"]):
		left_leg.rotation.x = sin(phase) * 0.55
		right_leg.rotation.x = -sin(phase) * 0.55
		left_arm.rotation.x = -sin(phase) * 0.24
		right_arm.rotation.x = sin(phase) * 0.24
	else:
		left_leg.rotation.x = lerpf(
			left_leg.rotation.x, 0.0, delta * 8.0
		)
		right_leg.rotation.x = lerpf(
			right_leg.rotation.x, 0.0, delta * 8.0
		)
		left_arm.rotation.x = lerpf(
			left_arm.rotation.x, 0.0, delta * 8.0
		)

	var attack_pose: float = float(unit["attack_anim"])

	if attack_pose > 0.0:
		right_arm.rotation.x = -attack_pose * 1.7

	body.rotation.z = sin(phase * 0.35) * 0.025

	if float(unit["timer"]) > 0.0:
		return

	if distance > reach + 0.4:
		return

	unit["timer"] = float(unit["cooldown"])
	unit["attack_anim"] = 1.0

	var damage: float = float(unit["damage"])

	if friendly and formation == 1 and kind == "infantry":
		damage *= 1.12

	if friendly and formation == 2 and kind == "cavalry":
		damage *= 1.25

	if friendly and order == 2:
		damage *= 1.15

	if friendly and order == 1:
		damage *= 0.85

	if kind == "archers" or kind == "siege":
		launch_projectile(
			root.position + Vector3(0, 1.7, 0),
			target_root.position + Vector3(0, 1.0, 0),
			friendly,
			damage,
			target,
			kind == "siege"
		)

		if kind == "siege" and friendly:
			damage_wall(damage * 0.6)
	else:
		deal_damage(target, damage)

func update_projectiles(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var shot: Dictionary = projectiles[i]
		var node: Node3D = shot["node"]

		if not is_instance_valid(node):
			projectiles.remove_at(i)
			continue

		var target: Dictionary = shot["target"]
		var destination: Vector3 = shot["destination"]

		if bool(target["alive"]):
			var target_root: Node3D = target["root"]
			destination = (
				target_root.position + Vector3(0, 1.0, 0)
			)

		var direction := destination - node.position
		var distance := direction.length()
		var speed: float = float(shot["speed"])

		if distance <= speed * delta + 0.3:
			if bool(target["alive"]):
				deal_dam
