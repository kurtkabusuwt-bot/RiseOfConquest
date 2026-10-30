
extends Node3D

# RISE OF CONQUEST - SAVAS 4.0 MODULAR
# Godot 4.4.1 / Android

const Units = preload("res://war_units_40.gd")
const Combat = preload("res://war_combat_40.gd")
const Siege = preload("res://war_siege_40.gd")
const WarUI = preload("res://war_ui_40.gd")

const SAVE_PATH := "user://roc_war_31.json"
const TYPES := ["infantry", "archers", "cavalry", "assassin", "siege"]
const POWERS := [10, 15, 30, 42, 55]
const FORMATIONS := ["HAT", "KARE", "KAMA"]
const ORDERS := ["SALDIR", "SAVUN", "HUCUM"]

var game: Node3D
var expansion: Node
var kingdom: Node

var units = Units.new()
var combat = Combat.new()
var siege = Siege.new()
var war_ui = WarUI.new()

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
var enemy_name := ""
var initial_blue := 0
var initial_red := 0

var battlefield: Node3D
var battle_camera: Camera3D
var city_camera: Camera3D
var saved_camera := Transform3D.IDENTITY
var saved_fov := 55.0

var blue_units: Array[Dictionary] = []
var red_units: Array[Dictionary] = []

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
	build_world()
	war_ui.build(self)
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

func change_resources(values: Dictionary) -> void:
	for key in values:
		game.set(
			key,
			maxi(0, resource_value(str(key)) + int(values[key]))
		)
	if game.has_method("update_ui"):
		game.call("update_ui")

func army_count(kind: String) -> int:
	if extra_army.has(kind):
		return int(extra_army[kind])
	return int(expansion.get(kind))

func total_army() -> int:
	var result := 0
	for kind in TYPES:
		result += army_count(str(kind))
	return result

func army_dictionary() -> Dictionary:
	var result := {}
	for kind in TYPES:
		result[str(kind)] = army_count(str(kind))
	return result

func kingdom_bonus() -> float:
	if kingdom != null and kingdom.has_method("military_bonus"):
		return maxf(
			1.0,
			float(kingdom.call("military_bonus"))
		)
	return 1.0

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
			last_report = "Kale 3 gerekli."
			update_panel()
			return
		cost = {"coins": 120, "foods": 70}

	elif kind == "siege":
		if castle < 4:
			last_report = "Kale 4 gerekli."
			update_panel()
			return
		cost = {
			"coins": 100,
			"woods": 160,
			"stones": 110
		}
	else:
		return

	if not can_pay(cost):
		return

	var expenses := {}
	for key in cost:
		expenses[key] = -int(cost[key])

	change_resources(expenses)
	extra_army[kind] = army_count(kind) + 2
	last_report = "2 yeni birlik egitildi: " + kind
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

func toggle_panel() -> void:
	if fighting:
		return
	war_ui.panel.visible = not war_ui.panel.visible
	update_panel()

func update_panel() -> void:
	if expansion == null:
		return

	if war_ui.stats == null:
		return

	war_ui.update(
		army_dictionary(),
		army_power(),
		str(FORMATIONS[formation]),
		str(ORDERS[order]),
		war_wins,
		war_losses,
		conquered,
		last_report
	)

func build_world() -> void:
	battlefield = Node3D.new()
	battlefield.name = "Battlefield40"
	game.add_child(battlefield)
	battlefield.position = Vector3(0, 0, -85)

	units.box(
		battlefield,
		Vector3(0, -0.22, 0),
		Vector3(54, 0.4, 40),
		Color(0.34, 0.38, 0.27)
	)

	for side in [-1.0, 1.0]:
		for i in range(5):
			var x: float = side * 24.0
			var z: float = -15.0 + float(i) * 7.5

			units.box(
				battlefield,
				Vector3(x, 1.5, z),
				Vector3(0.28, 3.0, 0.28),
				Color(0.36, 0.24, 0.15)
			)

			var flag := Color(0.75, 0.18, 0.15)
			if side < 0.0:
				flag = Color(0.16, 0.38, 0.8)

			units.box(
				battlefield,
				Vector3(x + 0.5, 2.3, z),
				Vector3(1.0, 0.75, 0.08),
				flag
			)

	siege.build(battlefield)

	battle_camera = Camera3D.new()
	battlefield.add_child(battle_camera)
	battle_camera.position = Vector3(0, 23, 29)
	battle_camera.look_at(
		battlefield.global_position,
		Vector3.UP
	)
	battle_camera.fov = 60
	battle_camera.current = false
	battlefield.visible = false

func clear_armies() -> void:
	combat.reset()

	for unit in blue_units:
		var root: Node3D = unit["root"]
		if is_instance_valid(root):
			root.queue_free()

	for unit in red_units:
		var root: Node3D = unit["root"]
		if is_instance_valid(root):
			root.queue_free()

	blue_units.clear()
	red_units.clear()

func deploy() -> void:
	clear_armies()

	var remaining := 25

	for kind in TYPES:
		var count := mini(
			army_count(str(kind)),
			remaining
		)

		for i in range(count):
			blue_units.append(
				units.create(
					battlefield,
					str(kind),
					true,
					kingdom_bonus()
				)
			)

		remaining -= count

	var enemy_count := mini(25, 12 + conquered * 2)

	for i in range(enemy_count):
		red_units.append(
			units.create(
				battlefield,
				str(TYPES[i % 4]),
				false
			)
		)

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

	for unit in blue_units + red_units:
		combat.ai.set_home(unit)

	initial_blue = blue_units.size()
	initial_red = red_units.size()

func open_battle_camera() -> void:
	battlefield.visible = true
	city_camera = get_viewport().get_camera_3d()

	if city_camera != null:
		saved_camera = city_camera.global_transform
		saved_fov = city_camera.fov
		city_camera.global_transform = battle_camera.global_transform
		city_camera.fov = battle_camera.fov
	else:
		battle_camera.make_current()

	war_ui.panel.visible = false
	war_ui.hud.visible = true

func close_battle_camera() -> void:
	if city_camera != null and is_instance_valid(city_camera):
		city_camera.global_transform = saved_camera
		city_camera.fov = saved_fov
		city_camera.make_current()
	else:
		battle_camera.current = false

	battlefield.visible = false
	war_ui.hud.visible = false

func begin_battle() -> void:
	if fighting:
		return

	if total_army() < 5:
		last_report = "En az 5 asker gerekli."
		update_panel()
		return

	if not can_pay({"foods": 35}):
		return

	change_resources({"foods": -35})

	var targets := [
		"Sinir Karakolu",
		"Orman Hisari",
		"Tas Kalesi",
		"Kuzey Garnizonu",
		"Kraliyet Kalesi"
	]

	enemy_name = str(targets[conquered % targets.size()])

	var has_supplies := false

	if kingdom != null and kingdom.has_method("save_data"):
		var supplies := int(kingdom.get("siege_supplies"))
		if supplies > 0:
			has_supplies = true
			kingdom.set("siege_supplies", supplies - 1)
			kingdom.call("save_data")

	battle_time = 0.0
	order = 0
	deploy()
	siege.reset(conquered, has_supplies)

	fighting = true
	open_battle_camera()

	last_report = "Savas basladi: " + enemy_name
	update_panel()

func _process(delta: float) -> void:
	if not fighting:
		return

	battle_time += delta

	if city_camera != null and is_instance_valid(city_camera):
		city_camera.global_transform = battle_camera.global_transform

	combat.prepare_frame(blue_units, red_units)

	for unit in blue_units:
		var moving: bool = combat.update_unit(
			unit, red_units, delta,
			order, formation,
			battlefield,
			Callable(siege, "damage"),
			blue_units
		)
		units.animate(unit, delta, battle_time, moving)

	for unit in red_units:
		var moving: bool = combat.update_unit(
			unit, blue_units, delta,
			0, 0, battlefield,
			Callable(siege, "damage"),
			red_units
		)
		units.animate(unit, delta, battle_time, moving)

	combat.update_shots(delta)

	var blue_alive: int = combat.alive_count(blue_units)
	var red_alive: int = combat.alive_count(red_units)

	war_ui.battle_status(
		enemy_name,
		blue_alive,
		red_alive,
		siege.summary(),
		str(ORDERS[order]),
		battle_time
	)

	if (
		blue_alive == 0 or
		red_alive == 0 or
		battle_time >= battle_limit
	):
		finish_battle()

func apply_losses(victory: bool) -> String:
	var ratio := 0.0

	if initial_blue > 0:
		ratio = (
			float(combat.fallen_blue) /
			float(initial_blue)
		)

	if not victory:
		ratio = maxf(ratio, 0.18)

	var result: Array[String] = []

	for kind in TYPES:
		var key: String = str(kind)
		var count := army_count(key)
		var lost := mini(
			count,
			int(ceil(float(count) * ratio))
		)

		if lost <= 0:
			continue

		if extra_army.has(key):
			extra_army[key] = maxi(0, count - lost)
		else:
			expansion.set(key, maxi(0, count - lost))

		result.append(key + ": -" + str(lost))

	if result.is_empty():
		return "Kayip yok."

	return ", ".join(PackedStringArray(result))

func finish_battle() -> void:
	if not fighting:
		return

	fighting = false
	close_battle_camera()

	var blue_alive: int = combat.alive_count(blue_units)
	var red_alive: int = combat.alive_count(red_units)

	var victory := false

	if blue_alive > 0 and red_alive == 0:
		victory = true
	elif blue_alive > 0 and red_alive > 0:
		var blue_ratio := (
			float(blue_alive) /
			maxf(1.0, float(initial_blue))
		)
		var red_ratio := (
			float(red_alive) /
			maxf(1.0, float(initial_red))
		)
		victory = blue_ratio > red_ratio

	var losses := apply_losses(victory)

	if victory:
		war_wins += 1
		conquered += 1

		var coins := 120 + conquered * 30
		var stones := 55 + conquered * 12

		change_resources({
			"coins": coins,
			"stones": stones,
			"woods": 45
		})

		last_report = (
			"ZAFER! " + enemy_name + " fethedildi.\n"
		)
		last_report += (
			"Odul: %d altin, %d tas, 45 odun.\n" %
			[coins, stones]
		)
	else:
		war_losses += 1
		last_report = (
			"YENILGI! " + enemy_name + " alinamadi.\n"
		)

	last_report += (
		"Mavi kayip: %d | Kirmizi kayip: %d\n" %
		[combat.fallen_blue, combat.fallen_red]
	)

	last_report += (
		"Kalan asker: %d / %d\n" %
		[blue_alive, red_alive]
	)

	last_report += siege.summary() + "\n"
	last_report += "Ordu kayiplari: " + losses

	save_war()
	expansion.call("save_expansion", false)
	update_panel()
	war_ui.panel.visible = true

func save_war() -> void:
	var data := {
		"extra_army": extra_army,
		"formation": formation,
		"order": order,
		"conquered": conquered,
		"wins": war_wins,
		"losses": war_losses,
		"report": last_report
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify(data))
	file.close()

func load_war() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if not (parsed is Dictionary):
		return

	var data: Dictionary = parsed
	var saved_army: Variant = data.get("extra_army", {})

	if saved_army is Dictionary:
		for kind in extra_army:
			extra_army[kind] = maxi(
				0,
				int(saved_army.get(kind, 0))
			)

	formation = clampi(
		int(data.get("formation", 0)), 0, 2
	)
	order = clampi(
		int(data.get("order", 0)), 0, 2
	)
	conquered = maxi(
		0, int(data.get("conquered", 0))
	)
	war_wins = maxi(
		0, int(data.get("wins", 0))
	)
	war_losses = maxi(
		0, int(data.get("losses", 0))
	)
	last_report = str(data.get("report", last_report))