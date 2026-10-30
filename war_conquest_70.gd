extends "res://war_conquest_31.gd"

# RISE OF CONQUEST - SIEGE WAR 7.3
# DUAL COMMANDERS AND BATTLE XP
# Godot 4.4.1 / Android

const COMMANDER_SAVE := "user://roc_commanders_v1.json"

const UNIT_NAMES := {
	"infantry": "Piyade",
	"cavalry": "Süvari",
	"archers": "Okçu",
	"siege": "Kuşatma",
	"assassin": "Suikastçı"
}

var siege_clock: float = 0.0
var impact_count: int = 0
var breach_announced: bool = false
var last_wall_hp: float = 0.0

var hero_combat: Node = null
var hero_progression: Node = null

var primary_commander := "Fatih Sultan Mehmet"
var secondary_commander := ""
var active_commander := ""
var active_secondary := ""

var commander_siege_bonus := 1.0

var commander_canvas: CanvasLayer
var commander_panel: PanelContainer
var primary_selector: OptionButton
var secondary_selector: OptionButton
var commander_info: Label

var commander_names: Array[String] = []


func _ready() -> void:
	load_commanders()
	super._ready()
	call_deferred("setup_commanders")


func setup_commanders() -> void:
	if game == null:
		game = get_tree().current_scene as Node3D

	if game == null:
		return

	hero_combat = game.get_node_or_null("HeroCombat")
	hero_progression = game.get_node_or_null(
		"HeroProgression"
	)

	if hero_combat == null:
		push_warning("HeroCombat bulunamadi.")
		return

	commander_names.clear()

	for hero_name in hero_combat.HERO_ROLES.keys():
		commander_names.append(str(hero_name))

	commander_names.sort()

	build_commander_ui()


func build_commander_ui() -> void:
	commander_canvas = CanvasLayer.new()
	commander_canvas.layer = 65
	add_child(commander_canvas)

	var toggle := Button.new()
	toggle.text = "KOMUTANLAR"
	toggle.position = Vector2(12, 205)
	toggle.custom_minimum_size = Vector2(165, 45)
	commander_canvas.add_child(toggle)
	toggle.pressed.connect(toggle_commander_panel)

	commander_panel = PanelContainer.new()
	commander_panel.position = Vector2(190, 65)
	commander_panel.custom_minimum_size = Vector2(360, 0)
	commander_canvas.add_child(commander_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	commander_panel.add_child(content)

	var heading := Label.new()
	heading.text = "ORDU KOMUTANLARI"
	heading.add_theme_font_size_override(
		"font_size", 24
	)
	content.add_child(heading)

	var first_label := Label.new()
	first_label.text = "ANA KOMUTAN"
	content.add_child(first_label)

	primary_selector = OptionButton.new()
	primary_selector.custom_minimum_size = Vector2(320, 45)
	content.add_child(primary_selector)

	var second_label := Label.new()
	second_label.text = "YARDIMCI KOMUTAN"
	content.add_child(second_label)

	secondary_selector = OptionButton.new()
	secondary_selector.custom_minimum_size = Vector2(320, 45)
	content.add_child(secondary_selector)

	secondary_selector.add_item("Yok")

	for hero_name in commander_names:
		primary_selector.add_item(hero_name)
		secondary_selector.add_item(hero_name)

	for i in range(commander_names.size()):
		if commander_names[i] == primary_commander:
			primary_selector.select(i)

		if commander_names[i] == secondary_commander:
			secondary_selector.select(i + 1)

	commander_info = Label.new()
	commander_info.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
	content.add_child(commander_info)

	var save_button := Button.new()
	save_button.text = "KOMUTANLARI ATA"
	save_button.custom_minimum_size.y = 45
	content.add_child(save_button)
	save_button.pressed.connect(assign_commanders)

	var close_button := Button.new()
	close_button.text = "KAPAT"
	content.add_child(close_button)
	close_button.pressed.connect(toggle_commander_panel)

	commander_panel.visible = false
	update_commander_info()


func toggle_commander_panel() -> void:
	if fighting:
		return

	if commander_panel == null:
		return

	commander_panel.visible = not commander_panel.visible


func assign_commanders() -> void:
	if fighting:
		return

	if commander_names.is_empty():
		return

	var first_index := primary_selector.selected
	var second_index := secondary_selector.selected

	if first_index < 0:
		return

	var first_name := commander_names[first_index]
	var second_name := ""

	if second_index > 0:
		second_name = commander_names[second_index - 1]

	if first_name == second_name:
		commander_info.text = (
			"Ayni kahraman iki goreve atanamaz."
		)
		return

	primary_commander = first_name
	secondary_commander = second_name

	save_commanders()
	update_commander_info()


func update_commander_info() -> void:
	if commander_info == null:
		return

	var second_name := secondary_commander

	if second_name.is_empty():
		second_name = "Atanmadi"

	commander_info.text = (
		"Ana komutan: " + primary_commander +
		"\nYardimci: " + second_name +
		"\nYardimci bonusu: %50"
	)


func save_commanders() -> void:
	var file := FileAccess.open(
		COMMANDER_SAVE,
		FileAccess.WRITE
	)

	if file == null:
		return

	var data := {
		"primary": primary_commander,
		"secondary": secondary_commander
	}

	file.store_string(JSON.stringify(data))
	file.close()


func load_commanders() -> void:
	if not FileAccess.file_exists(COMMANDER_SAVE):
		return

	var file := FileAccess.open(
		COMMANDER_SAVE,
		FileAccess.READ
	)

	if file == null:
		return

	var parsed: Variant = JSON.parse_string(
		file.get_as_text()
	)
	file.close()

	if not (parsed is Dictionary):
		return

	primary_commander = str(
		parsed.get(
			"primary",
			"Fatih Sultan Mehmet"
		)
	)

	secondary_commander = str(
		parsed.get("secondary", "")
	)


func build_world() -> void:
	super.build_world()

	battle_camera.position = Vector3(4, 30, 35)
	battle_camera.look_at(
		battlefield.to_global(Vector3(5, 0, 0)),
		Vector3.UP
	)
	battle_camera.fov = 72.0


func get_unit_bonus(kind: String) -> Dictionary:
	if hero_combat == null:
		return {}

	if active_commander.is_empty():
		return {}

	if not UNIT_NAMES.has(kind):
		return {}

	var unit_name: String = UNIT_NAMES[kind]

	if not active_secondary.is_empty():
		return hero_combat.get_two_commander_bonuses(
			active_commander,
			active_secondary,
			unit_name
		)

	return hero_combat.get_army_bonuses(
		active_commander,
		unit_name
	)


func apply_commander_bonuses() -> void:
	if hero_combat == null:
		return

	for unit in blue_units:
		var kind: String = str(unit["kind"])
		var bonus: Dictionary = get_unit_bonus(kind)

		if bonus.is_empty():
			continue

		var attack := clampf(
			float(bonus.get(
				"attack_multiplier", 1.0
			)),
			1.0,
			2.5
		)

		var defense := clampf(
			float(bonus.get(
				"defense_multiplier", 1.0
			)),
			1.0,
			2.5
		)

		var health := clampf(
			float(bonus.get(
				"health_multiplier", 1.0
			)),
			1.0,
			2.5
		)

		unit["damage"] = (
			float(unit["damage"]) * attack
		)

		unit["hp"] = (
			float(unit["hp"]) * health * defense
		)

	var siege_bonus := get_unit_bonus("siege")

	if not siege_bonus.is_empty():
		commander_siege_bonus = clampf(
			float(siege_bonus.get(
				"attack_multiplier", 1.0
			)),
			1.0,
			2.5
		)


func deploy() -> void:
	super.deploy()
	apply_commander_bonuses()


func begin_battle() -> void:
	if fighting:
		return

	if hero_combat == null and game != null:
		hero_combat = game.get_node_or_null(
			"HeroCombat"
		)

	active_commander = primary_commander
	active_secondary = secondary_commander

	if active_secondary == active_commander:
		active_secondary = ""

	commander_siege_bonus = 1.0

	super.begin_battle()

	if not fighting:
		return

	battle_limit = 75.0
	siege_clock = 0.0
	impact_count = 0
	breach_announced = false
	last_wall_hp = float(siege.wall_hp)

	last_report += (
		"\nAna komutan: " + active_commander
	)

	if not active_secondary.is_empty():
		last_report += (
			"\nYardimci: " + active_secondary
		)

	update_panel()


func _process(delta: float) -> void:
	if not fighting:
		return

	siege_clock += delta

	if siege_clock >= 2.5:
		siege_clock = 0.0
		perform_siege_attack()

	super._process(delta)

	if siege.has_method("update_effects"):
		siege.update_effects(delta)

	if fighting and bool(siege.wall_destroyed):
		if not breach_announced:
			breach_announced = true
			last_report = (
				"SURLAR YIKILDI! Gecit acildi."
			)
			update_panel()


func perform_siege_attack() -> void:
	if bool(siege.wall_destroyed):
		return

	var siege_count := 0
	var infantry_count := 0
	var archers_count := 0

	for unit in blue_units:
		if not bool(unit["alive"]):
			continue

		var kind := str(unit["kind"])

		if kind == "siege":
			siege_count += 1
		elif kind == "infantry":
			infantry_count += 1
		elif kind == "archers":
			archers_count += 1

	var damage := float(siege_count) * 19.0

	if infantry_count > 0:
		var gate_attackers := 0

		for unit in blue_units:
			if not bool(unit["alive"]):
				continue

			if str(unit["kind"]) != "infantry":
				continue

			var soldier: Node3D = unit["root"]

			if soldier.position.x > 13.0:
				gate_attackers += 1

		damage += float(gate_attackers) * 3.5

	if archers_count > 0 and siege_count > 0:
		damage += minf(
			6.0,
			float(archers_count) * 0.7
		)

	if damage <= 0.0:
		return

	damage *= commander_siege_bonus

	var old_hp := float(siege.wall_hp)
	siege.damage(damage)

	if siege.has_method("spawn_impact"):
		siege.spawn_impact(
			damage,
			siege_count > 0
		)

	if siege_count > 0:
		impact_count += 1

	last_wall_hp = float(siege.wall_hp)

	if old_hp > 0.0 and float(siege.wall_hp) <= 0.0:
		breach_announced = true
		last_report = "KALE SURLARI YIKILDI!"
		update_panel()


func award_hero_experience(victory: bool) -> String:
	if hero_progression == null:
		return "Kahraman deneyim sistemi bulunamadi."

	var primary_xp := 150 if victory else 50
	var secondary_xp := 90 if victory else 30

	var report := ""

	if not active_commander.is_empty():
		var levels: int = hero_progression.add_xp(
			active_commander,
			primary_xp
		)

		report += (
			"\n%s: +%d XP" %
			[active_commander, primary_xp]
		)

		if levels > 0:
			report += (
				" | +%d seviye" % levels
			)

	if not active_secondary.is_empty():
		var levels: int = hero_progression.add_xp(
			active_secondary,
			secondary_xp
		)

		report += (
			"\n%s: +%d XP" %
			[active_secondary, secondary_xp]
		)

		if levels > 0:
			report += (
				" | +%d seviye" % levels
			)

	return report


func finish_battle() -> void:
	if not fighting:
		return

	var breach := bool(siege.wall_destroyed)
	var wall_remaining := int(siege.wall_hp)
	var impacts := impact_count

	var previous_wins := war_wins

	super.finish_battle()

	var victory := war_wins > previous_wins

	last_report += "\nKUSATMA 7.3"
	last_report += (
		"\nMancinik atisi: %d" % impacts
	)

	if breach:
		last_report += "\nSur: YIKILDI"
	else:
		last_report += (
			"\nSur dayanikliligi: %d" %
			wall_remaining
		)

	last_report += "\nKOMUTAN DENEYIMLERI"
	last_report += award_hero_experience(victory)

	save_war()
	update_panel()
