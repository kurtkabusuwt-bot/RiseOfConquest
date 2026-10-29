
extends Node3D

# RISE OF CONQUEST - SAVAS 3.2
# 3D gorunur savas ve kamera duzeltmesi

const SAVE_PATH := "user://roc_war_31.json"
const TYPES := ["infantry", "archers", "cavalry", "assassin", "siege"]
const FORMATIONS := ["HAT", "KARE", "KAMA"]
const BASE_POWER := [10, 15, 30, 42, 55]

var game: Node3D
var expansion: Node
var extra_army := {"assassin": 0, "siege": 0}
var formation := 0
var conquered := 0
var war_wins := 0
var war_losses := 0
var last_report := "Henuz savas yapilmadi."

var fighting := false
var battle_clock := 0.0
var battle_duration := 12.0
var enemy_power := 0
var our_power := 0
var current_enemy := ""

var battlefield: Node3D
var friend_units: Array[Node3D] = []
var enemy_units: Array[Node3D] = []
var friend_origins: Array[Vector3] = []
var enemy_origins: Array[Vector3] = []

var city_camera: Camera3D
var old_camera_transform := Transform3D.IDENTITY
var battle_camera: Camera3D

var ui: CanvasLayer
var panel: PanelContainer
var stats_label: Label
var report_label: Label
var battle_label: Label
var battle_button: Button
var formation_button: Button

func _ready() -> void:
	call_deferred("initialize")

func initialize() -> void:
	game = get_tree().current_scene as Node3D
	if game == null:
		return

	expansion = game.get_node_or_null("ConquestExpansion")
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

func army_power() -> int:
	var power := 0
	for i in range(TYPES.size()):
		power += army_count(str(TYPES[i])) * int(BASE_POWER[i])

	power += int(expansion.get("castle_level")) * 5

	match formation:
		0:
			power += army_count("archers") * 2
		1:
			power += army_count("infantry") * 3
		2:
			power += army_count("cavalry") * 5

	power += mini(army_count("assassin"), 20) * 3
	return power

func train_special(kind: String) -> void:
	if fighting:
		return

	var castle := int(expansion.get("castle_level"))
	var cost: Dictionary = {}

	if int(game.get("barracks_count")) <= 0:
		last_report = "Once kisla insa et."
		update_panel()
		return

	if kind == "assassin":
		if castle < 3:
			last_report = "Suikastci icin kale seviye 3 gerekli."
			update_panel()
			return
		cost = {"coins": 120, "foods": 70}
	elif kind == "siege":
		if castle < 4:
			last_report = "Kusatma icin kale seviye 4 gerekli."
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

func make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	return material

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
	battlefield.name = "Battlefield32"
	game.add_child(battlefield)
	battlefield.position = Vector3(0, 0, -75)

	add_box(
		battlefield,
		Vector3(0, -0.2, 0),
		Vector3(42, 0.4, 32),
		Color(0.37, 0.40, 0.28)
	)

	for side in [-1.0, 1.0]:
		for i in range(5):
			var x: float = float(side) * 18.0
			var z: float = -12.0 + float(i) * 6.0
			add_cylinder(
				battlefield,
				Vector3(x, 1.5, z),
				0.25, 3.0,
				Color(0.43, 0.32, 0.20)
			)
			var flag_color := Color(0.68, 0.16, 0.13)
			if side < 0:
				flag_color = Color(0.17, 0.35, 0.70)
			add_box(
				battlefield,
				Vector3(x, 2.35, z),
				Vector3(1.1, 0.8, 0.1),
				flag_color
			)

	add_box(
		battlefield,
		Vector3(0, 0.02, 0),
		Vector3(0.15, 0.04, 29),
		Color(0.72, 0.63, 0.43)
	)

	battle_camera = Camera3D.new()
	battlefield.add_child(battle_camera)
	battle_camera.position = Vector3(0, 19, 24)
	battle_camera.look_at(
		battlefield.global_position,
		Vector3.UP
	)
	battle_camera.fov = 65
	battle_camera.current = false

	battlefield.visible = false

func create_fighter(kind: String, friendly: bool) -> Node3D:
	var fighter := Node3D.new()
	battlefield.add_child(fighter)

	var armor := Color(0.19, 0.38, 0.75)
	if not friendly:
		armor = Color(0.73, 0.18, 0.15)

	var steel := Color(0.68, 0.70, 0.74)
	var wood := Color(0.41, 0.27, 0.15)

	if kind == "siege":
		add_box(
			fighter, Vector3(0, 0.55, 0),
			Vector3(1.3, 0.35, 1.4), wood
		)
		add_box(
			fighter, Vector3(0, 1.35, 0),
			Vector3(0.18, 1.5, 0.18), wood
		)
		add_box(
			fighter, Vector3(0, 2.0, -0.35),
			Vector3(0.6, 0.2, 0.6), steel
		)
		return fighter

	var height_offset := 0.0

	if kind == "cavalry":
		add_box(
			fighter, Vector3(0, 0.8, 0),
			Vector3(0.65, 0.65, 1.2), wood
		)
		add_box(
			fighter, Vector3(0, 1.2, -0.48),
			Vector3(0.4, 0.65, 0.35), wood
		)
		height_offset = 0.65

	add_box(
		fighter,
		Vector3(0, 0.95 + height_offset, 0),
		Vector3(0.5, 0.75, 0.38),
		armor
	)

	add_cylinder(
		fighter,
		Vector3(0, 1.55 + height_offset, 0),
		0.22, 0.38, steel
	)

	if kind == "assassin":
		add_box(
			fighter,
			Vector3(0, 1.85, 0),
			Vector3(0.6, 0.35, 0.48),
			Color(0.12, 0.12, 0.16)
		)

	if kind == "archers":
		add_box(
			fighter,
			Vector3(0.4, 1.0, -0.1),
			Vector3(0.1, 1.3, 0.12),
			wood
		)
	else:
		add_box(
			fighter,
			Vector3(0.42, 1.0 + height_offset, -0.1),
			Vector3(0.1, 1.2, 0.12),
			steel
		)

	if kind == "infantry":
		add_box(
			fighter,
			Vector3(-0.42, 1.0, -0.1),
			Vector3(0.38, 0.65, 0.12),
			armor
		)

	return fighter

func clear_fighters() -> void:
	for unit in friend_units:
		if is_instance_valid(unit):
			unit.queue_free()

	for unit in enemy_units:
		if is_instance_valid(unit):
			unit.queue_free()

	friend_units.clear()
	enemy_units.clear()
	friend_origins.clear()
	enemy_origins.clear()

func deploy_armies() -> void:
	clear_fighters()

	var remaining := 20

	for i in range(TYPES.size()):
		var kind: String = str(TYPES[i])
		var count := mini(army_count(kind), remaining)

		for j in range(count):
			var fighter := create_fighter(kind, true)
			friend_units.append(fighter)

		remaining -= count

	for i in range(20):
		var enemy_kind: String = str(TYPES[i % 4])
		enemy_units.append(
			create_fighter(enemy_kind, false)
		)

	for i in range(friend_units.size()):
		var x := -13.0 + float(i % 5) * 1.8
		var z := -8.0 + float(int(i / 5)) * 2.1

		if formation == 1:
			x = -13.0 + float(i % 4) * 2.0
			z = -7.0 + float(int(i / 4)) * 1.7
		elif formation == 2:
			var row := int(sqrt(float(i)))
			x = -13.0 + float(i - row * row - row) * 1.5
			z = -8.0 + float(row) * 2.0

		var unit := friend_units[i]
		unit.position = Vector3(x, 0, z)
		unit.rotation.y = -PI * 0.5
		friend_origins.append(unit.position)

	for i in range(enemy_units.size()):
		var x := 13.0 - float(i % 5) * 1.7
		var z := -8.0 + float(int(i / 5)) * 2.1

		var unit := enemy_units[i]
		unit.position = Vector3(x, 0, z)
		unit.rotation.y = PI * 0.5
		enemy_origins.append(unit.position)

func open_battle_view() -> void:
	battlefield.visible = true

	# Mevcut aktif kamerayi kullan.
	# Yeni kamera aktif edilmiyor; boylece
	# sehir kamera sistemi goruntuyu geri alamaz.
	city_camera = get_viewport().get_camera_3d()

	if city_camera != null:
		old_camera_transform = city_camera.global_transform
		city_camera.global_transform = battle_camera.global_transform
		city_camera.fov = 65
	else:
		battle_camera.make_current()

	if panel != null:
		panel.visible = false

func keep_battle_camera() -> void:
	if city_camera == null:
		return
	if not is_instance_valid(city_camera):
		return

	# Savas boyunca ayni kamerayi sahada tut.
	city_camera.global_transform = battle_camera.global_transform

func close_battle_view() -> void:
	if city_camera != null and is_instance_valid(city_camera):
		city_camera.global_transform = old_camera_transform
		city_camera.make_current()
	else:
		battle_camera.current = false

	battlefield.visible = false

func begin_battle() -> void:
	if fighting:
		return

	if total_army() < 5:
		last_report = "Savas icin en az 5 asker gerekli."
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

	fighting = true
	battle_clock = 0.0

	deploy_armies()
	open_battle_view()

	last_report = "Savas basladi: " + current_enemy
	update_panel()

func apply_losses(victory: bool) -> String:
	var losses: Array[String] = []
	var divisor := 16 if victory else 7

	for kind in TYPES:
		var unit_kind: String = str(kind)
		var count := army_count(unit_kind)
		var lost := mini(
			count,
			int(ceil(float(count) / float(divisor)))
		)

		if lost <= 0:
			continue

		if extra_army.has(unit_kind):
			extra_army[unit_kind] = maxi(0, count - lost)
		else:
			expansion.set(unit_kind, maxi(0, count - lost))

		losses.append(unit_kind + ": -" + str(lost))

	if losses.is_empty():
		return "Kayip yok."

	return ", ".join(PackedStringArray(losses))

func finish_battle() -> void:
	fighting = false
	close_battle_view()

	var victory := our_power >= enemy_power
	var losses := apply_losses(victory)

	if victory:
		war_wins += 1
		conquered += 1

		var coins := 120 + conquered * 30
		var stones := 55 + conquered * 12

		reward({
			"coins": coins,
			"stones": stones,
			"woods": 45
		})

		last_report = "ZAFER! " + current_enemy + " fethedildi.\n"
		last_report += "Odul: %d altin, %d tas, 45 odun.\n" % [
			coins, stones
		]
	else:
		war_losses += 1
		last_report = "YENILGI! " + current_enemy + " alinamadi.\n"

	last_report += "Bizim guc: %d | Dusman: %d\n" % [
		our_power, enemy_power
	]
	last_report += "Kayiplar: " + losses

	save_war()
	expansion.call("save_expansion", false)
	update_panel()

	if panel != null:
		panel.visible = true

func _process(delta: float) -> void:
	if not fighting:
		return

	battle_clock += delta
	keep_battle_camera()

	var progress := clampf(
		battle_clock / battle_duration,
		0.0, 1.0
	)

	# Ilk 7 saniye ilerleme, sonra carpismalar.
	var march := minf(battle_clock / 7.0, 1.0)

	for i in range(friend_units.size()):
		var unit := friend_units[i]
		if not is_instance_valid(unit):
			continue

		var origin := friend_origins[i]
		unit.position.x = origin.x + march * 7.0

		var bounce := absf(
			sin(battle_clock * 10.0 + float(i))
		) * 0.10

		if battle_clock >= 7.0:
			bounce = absf(
				sin(battle_clock * 17.0 + float(i))
			) * 0.22
			unit.rotation.z = sin(
				battle_clock * 9.0 + float(i)
			) * 0.12

		unit.position.y = bounce

	for i in range(enemy_units.size()):
		var unit := enemy_units[i]
		if not is_instance_valid(unit):
			continue

		var origin := enemy_origins[i]
		unit.position.x = origin.x - march * 7.0

		var bounce := absf(
			sin(battle_clock * 10.0 + float(i))
		) * 0.10

		if battle_clock >= 7.0:
			bounce = absf(
				sin(battle_clock * 17.0 + float(i))
			) * 0.22
			unit.rotation.z = sin(
				battle_clock * 9.0 + float(i)
			) * 0.12

		unit.position.y = bounce

	if battle_label != null:
		if battle_clock < 7.0:
			battle_label.text = "ORDULAR ILERLIYOR - %d%%" % [
				int(progress * 100.0)
			]
		else:
			battle_label.text = "CARPISMA - %d%%" % [
				int(progress * 100.0)
			]

	if battle_clock >= battle_duration:
		finish_battle()

func make_button(
	parent: VBoxContainer,
	title: String,
	action: Callable
) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(0, 42)
	parent.add_child(button)
	button.pressed.connect(action)
	return button

func build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 40
	add_child(ui)

	var open_button := Button.new()
	open_button.text = "SAVAS 3.2"
	open_button.position = Vector2(12, 45)
	open_button.custom_minimum_size = Vector2(145, 44)
	ui.add_child(open_button)
	open_button.pressed.connect(toggle_panel)

	panel = PanelContainer.new()
	panel.position = Vector2(165, 50)
	panel.custom_minimum_size = Vector2(320, 0)
	ui.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "SAVAS VE FETIH KOMUTANLIGI"
	content.add_child(heading)

	stats_label = Label.new()
	content.add_child(stats_label)

	formation_button = make_button(
		content,
		"FORMASYON DEGISTIR",
		next_formation
	)

	make_button(
		content,
		"2 SUIKASTCI EGIT",
		func(): train_special("assassin")
	)

	make_button(
		content,
		"2 KUSATMA BIRLIGI EGIT",
		func(): train_special("siege")
	)

	battle_button = make_button(
		content,
		"FETIH SAVASI BASLAT",
		begin_battle
	)

	battle_label = Label.new()
	content.add_child(battle_label)

	report_label = Label.new()
	report_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	report_label.custom_minimum_size = Vector2(310, 0)
	content.add_child(report_label)

	make_button(content, "KAPAT", toggle_panel)
	panel.visible = false

func toggle_panel() -> void:
	if fighting:
		return

	panel.visible = not panel.visible
	update_panel()

func update_panel() -> void:
	if stats_label == null or expansion == null:
		return

	stats_label.text = "PIYADE %d | OKCU %d | SUVARI %d\n" % [
		army_count("infantry"),
		army_count("archers"),
		army_count("cavalry")
	]

	stats_label.text += "SUIKASTCI %d | KUSATMA %d\n" % [
		army_count("assassin"),
		army_count("siege")
	]

	stats_label.text += "GUC %d | FORMASYON %s\n" % [
		army_power(),
		FORMATIONS[formation]
	]

	stats_label.text += "FETIH %d | ZAFER %d | YENILGI %d" % [
		conquered,
		war_wins,
		war_losses
	]

	report_label.text = last_report

	if not fighting:
		battle_label.text = "Ordu savasa hazir."

	if battle_button != null:
		battle_button.disabled = fighting

	if formation_button != null:
		formation_button.disabled = fighting

func save_war() -> void:
	var data := {
		"extra_army": extra_army,
		"formation": formation,
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

	var parsed: Variant = JSON.parse_string(
		file.get_as_text()
	)
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
		int(data.get("formation", 0)),
		0, 2
	)
	conquered = maxi(0, int(data.get("conquered", 0)))
	war_wins = maxi(0, int(data.get("wins", 0)))
	war_losses = maxi(0, int(data.get("losses", 0)))
	last_report = str(data.get("report", last_report))
