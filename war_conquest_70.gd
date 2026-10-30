
extends "res://war_conquest_31.gd"

# RISE OF CONQUEST - SIEGE WAR 7.2
# HERO COMBAT INTEGRATION
# Godot 4.4.1 / Android

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
var hero_menu: Node = null

var active_commander: String = ""
var active_secondary: String = ""
var commander_siege_bonus: float = 1.0


func build_world() -> void:
	super.build_world()

	battle_camera.position = Vector3(4, 30, 35)
	battle_camera.look_at(
		battlefield.to_global(Vector3(5, 0, 0)),
		Vector3.UP
	)
	battle_camera.fov = 72.0


func find_hero_system() -> void:
	if game == null:
		return

	hero_combat = game.get_node_or_null(
		"HeroCombat"
	)
	hero_menu = game.get_node_or_null(
		"HeroMenu"
	)


func get_selected_commander() -> String:
	if hero_menu == null:
		return ""

	var name: String = str(
		hero_menu.get("selected_hero")
	)

	if name == "<null>":
		return ""

	return name


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

	if active_commander.is_empty():
		return

	for unit in blue_units:
		var kind: String = str(unit["kind"])
		var bonus: Dictionary = get_unit_bonus(kind)

		if bonus.is_empty():
			continue

		var attack: float = clampf(
			float(bonus.get(
				"attack_multiplier", 1.0
			)),
			1.0,
			2.5
		)

		var defense: float = clampf(
			float(bonus.get(
				"defense_multiplier", 1.0
			)),
			1.0,
			2.5
		)

		var health: float = clampf(
			float(bonus.get(
				"health_multiplier", 1.0
			)),
			1.0,
			2.5
		)

		unit["damage"] = (
			float(unit["damage"]) * attack
		)

		# Current combat module uses HP directly.
		# Defense is represented as extra durability.
		unit["hp"] = (
			float(unit["hp"]) * health * defense
		)

	var siege_bonus: Dictionary = get_unit_bonus(
		"siege"
	)

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
	find_hero_system()

	active_commander = get_selected_commander()
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

	if not active_commander.is_empty():
		last_report += (
			"\nKomutan: " + active_commander
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

	var siege_count: int = 0
	var infantry_count: int = 0
	var archers_count: int = 0

	for unit in blue_units:
		if not bool(unit["alive"]):
			continue

		var kind: String = str(unit["kind"])

		if kind == "siege":
			siege_count += 1
		elif kind == "infantry":
			infantry_count += 1
		elif kind == "archers":
			archers_count += 1

	var damage: float = (
		float(siege_count) * 19.0
	)

	if infantry_count > 0:
		var gate_attackers: int = 0

		for unit in blue_units:
			if not bool(unit["alive"]):
				continue

			if str(unit["kind"]) != "infantry":
				continue

			var soldier: Node3D = unit["root"]

			if soldier.position.x > 13.0:
				gate_attackers += 1

		damage += (
			float(gate_attackers) * 3.5
		)

	if archers_count > 0 and siege_count > 0:
		damage += minf(
			6.0,
			float(archers_count) * 0.7
		)

	if damage <= 0.0:
		return

	damage *= commander_siege_bonus

	var old_hp: float = float(siege.wall_hp)
	siege.damage(damage)

	if siege.has_method("spawn_impact"):
		siege.spawn_impact(
			damage,
			siege_count > 0
		)

	if siege_count > 0:
		impact_count += 1

	last_wall_hp = float(siege.wall_hp)

	if (
		old_hp > 0.0 and
		float(siege.wall_hp) <= 0.0
	):
		breach_announced = true
		last_report = "KALE SURLARI YIKILDI!"
		update_panel()


func finish_battle() -> void:
	var was_fighting: bool = fighting
	var breach: bool = bool(siege.wall_destroyed)
	var wall_remaining: int = int(siege.wall_hp)
	var impacts: int = impact_count
	var commander_name: String = active_commander

	super.finish_battle()

	if not was_fighting:
		return

	last_report += "\nKUSATMA 7.2"

	if not commander_name.is_empty():
		last_report += (
			"\nKomutan: " + commander_name
		)

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

	save_war()
	update_panel()
