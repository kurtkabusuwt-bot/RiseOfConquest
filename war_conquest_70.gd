
extends "res://war_conquest_31.gd"

# RISE OF CONQUEST - SIEGE WAR 7.1
# Godot 4.4.1 / Android

var siege_clock: float = 0.0
var impact_count: int = 0
var breach_announced: bool = false
var last_wall_hp: float = 0.0

func build_world() -> void:
	super.build_world()

	battle_camera.position = Vector3(4, 30, 35)
	battle_camera.look_at(
		battlefield.to_global(Vector3(5, 0, 0)),
		Vector3.UP
	)
	battle_camera.fov = 72.0

func begin_battle() -> void:
	super.begin_battle()

	if not fighting:
		return

	battle_limit = 75.0
	siege_clock = 0.0
	impact_count = 0
	breach_announced = false
	last_wall_hp = float(siege.wall_hp)

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
			last_report = "SURLAR YIKILDI! Gecit acildi."
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

	var damage: float = float(siege_count) * 19.0

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

		damage += float(gate_attackers) * 3.5

	if archers_count > 0 and siege_count > 0:
		damage += minf(
			6.0,
			float(archers_count) * 0.7
		)

	if damage <= 0.0:
		return

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

	if old_hp > 0.0 and float(siege.wall_hp) <= 0.0:
		breach_announced = true
		last_report = "KALE SURLARI YIKILDI!"
		update_panel()

func finish_battle() -> void:
	var was_fighting: bool = fighting
	var breach: bool = bool(siege.wall_destroyed)
	var wall_remaining: int = int(siege.wall_hp)
	var impacts: int = impact_count

	super.finish_battle()

	if not was_fighting:
		return

	last_report += "\nKUSATMA 7.1"
	last_report += "\nMancinik atisi: %d" % impacts

	if breach:
		last_report += "\nSur: YIKILDI"
	else:
		last_report += "\nSur dayanikliligi: %d" % wall_remaining

	save_war()
	update_panel()
