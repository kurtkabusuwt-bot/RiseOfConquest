extends SceneTree

const War = preload("res://war_build_88.gd")
const Progression = preload("res://hero_progression.gd")
const HeroCombat = preload("res://hero_combat.gd")

class Game:
	extends Node3D
	var foods := 10000
	var coins := 0
	var woods := 0
	var stones := 0

class Expansion:
	extends Node
	var infantry := 10
	var archers := 3
	var cavalry := 4
	var castle_level := 4
	func save_expansion(_manual: bool) -> void:
		pass

var failures := 0
var checks := 0
var war: Node

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func close(actual: float, expected: float, message: String) -> void:
	check(is_equal_approx(actual, expected), "%s: got %f, expected %f" % [message, actual, expected])

func _initialize() -> void:
	call_deferred("run")

# Exercise the real movement/target/cooldown/charge/hit pipeline.
func strike(unit: Dictionary, target: Dictionary, distance: float = 1.0, timer: float = 0.0) -> float:
	var soldier: Node3D = unit["root"]
	var enemy: Node3D = target["root"]
	soldier.position = Vector3.ZERO
	enemy.position = Vector3(distance, 0, 0)
	unit["timer"] = timer
	unit["charge_ready"] = false
	target["alive"] = true
	target["kind"] = "archers"
	target["hp"] = 10000.0
	var opponents: Array[Dictionary] = [target]
	var criticals: int = war.combat.critical_hits
	war.combat.update_unit(unit, opponents, 0.0, 0, 0, war.battlefield, Callable(war.siege, "damage"))
	var dealt := 10000.0 - float(target["hp"])
	# Verify active multiplier independently of the preserved random critical mechanic.
	if war.combat.critical_hits > criticals:
		dealt /= 2.1
	return dealt

func run() -> void:
	var game := Game.new()
	root.add_child(game)
	current_scene = game
	var expansion := Expansion.new()
	expansion.name = "ConquestExpansion"
	game.add_child(expansion)
	var progression := Progression.new()
	progression.name = "HeroProgression"
	game.add_child(progression)
	progression.heroes.clear()
	var hero_combat := HeroCombat.new()
	hero_combat.name = "HeroCombat"
	game.add_child(hero_combat)
	war = War.new()
	game.add_child(war)
	await process_frame
	war.set_process(false)
	check(war.ability_buttons.size() == 2, "Both mobile buttons built")
	war.primary_commander = "Fatih Sultan Mehmet"
	war.secondary_commander = "Halid bin Velid"
	war.extra_army = {"assassin": 2, "siege": 2}
	war.begin_battle()
	check(war.fighting and war.battle_limit == 75.0, "7.3 battle starts")
	check(war.ability_panel.visible, "HUD visible in battle")
	check(float(war.blue_units[0]["damage"]) > 10.0, "7.3 commander progression bonuses preserved")
	var cavalry: Dictionary = {}
	var siege_unit: Dictionary = {}
	var assassins: Array[Dictionary] = []
	for unit in war.blue_units:
		match str(unit["kind"]):
			"cavalry": cavalry = unit
			"siege": siege_unit = unit
			"assassin": assassins.append(unit)
	var target: Dictionary = war.red_units[0]
	var wall_before: float = war.siege.wall_hp
	var hp_before: float = target["hp"]
	war.cast_ability(0)
	war.cast_ability(1)
	close(war.siege.wall_hp, wall_before, "Activation causes no instant wall damage")
	close(float(target["hp"]), hp_before, "Activation causes no instant unit damage")
	close(war.abilities.remaining[0], 45.0, "Fatih cooldown")
	close(war.abilities.remaining[1], 40.0, "Halid independent cooldown")
	close(war.abilities.active_time[0], 8.0, "Fatih active duration")
	close(war.abilities.active_time[1], 6.0, "Halid active duration")
	check(war.ability_buttons[0].text.contains("AKTİF 8 sn") and war.ability_buttons[0].text.contains("BEKLEME 45 sn"), "HUD shows active and cooldown together")
	check(not war.abilities.cast(war, 0), "Repeated tap cannot stack bonus")
	var base_cavalry: float = cavalry["damage"]
	close(strike(cavalry, target), base_cavalry * 1.25, "Secondary Halid gives exact 25 percent once")
	close(strike(cavalry, target), base_cavalry * 1.25, "Repeated hits do not compound bonus")
	close(float(cavalry["damage"]), base_cavalry, "Base stats never mutated")
	cavalry["timer"] = 0.0
	cavalry["charge_ready"] = true
	target["hp"] = 10000.0
	var charge_targets: Array[Dictionary] = [target]
	var charges_before: int = war.combat.cavalry_charges
	war.combat.update_unit(cavalry, charge_targets, 0.0, 2, 2, war.battlefield, Callable(war.siege, "damage"))
	close(10000.0 - float(target["hp"]), base_cavalry * 1.25 * 1.15 * 1.85 * 1.25, "Active bonus composes once with formation, order and charge")
	check(war.combat.cavalry_charges == charges_before + 1, "Existing charge accounting preserved")
	var infantry: Dictionary = war.blue_units[0]
	close(strike(infantry, target), float(infantry["damage"]), "Wrong unit type unbuffed")
	var enemy_cavalry: Dictionary = war.red_units[2]
	close(strike(enemy_cavalry, target), float(enemy_cavalry["damage"]), "Enemy cavalry unbuffed")
	# Siege callback and projectile are separate damage branches: both receive 1.30 once.
	wall_before = war.siege.wall_hp
	strike(siege_unit, target)
	var base_siege: float = siege_unit["damage"]
	close(wall_before - war.siege.wall_hp, base_siege * 0.6 * 1.30, "Wall callback not multiplied twice")
	check(war.combat.shots.size() == 1, "Real siege projectile launched")
	close(float(war.combat.shots[0]["damage"]), base_siege * 1.30, "Projectile snapshots bonus once")
	war.abilities.update(6.0)
	close(strike(cavalry, target), base_cavalry, "Halid expires at six seconds")
	close(war.abilities.active_time[0], 2.0, "Fatih remains active independently")
	war.abilities.update(2.0)
	var projectile_hp: float = target["hp"]
	war.combat.update_shots(10.0)
	close(projectile_hp - float(target["hp"]), base_siege * 1.30, "Delayed projectile retains launch bonus, no second impact bonus")
	wall_before = war.siege.wall_hp
	war.siege.damage(10.0)
	close(wall_before - war.siege.wall_hp, 10.0, "Wall bonus expires at eight seconds")
	war.abilities.update(37.0)
	war.update_ability_ui()
	check(war.ability_buttons[0].text.ends_with("HAZIR") and not war.ability_buttons[0].disabled, "HUD ready after cooldown")
	war.cast_ability(0)
	wall_before = war.siege.wall_hp
	var siege_count := 0
	var archers_count := 0
	for unit in war.blue_units:
		if unit["kind"] == "siege": siege_count += 1
		if unit["kind"] == "archers": archers_count += 1
	var periodic: float = (float(siege_count) * 19.0 + minf(6.0, float(archers_count) * 0.7)) * war.commander_siege_bonus
	war.perform_siege_attack()
	close(wall_before - war.siege.wall_hp, periodic * 1.30, "7.3 periodic siege damage receives one bonus")
	# Hasan: one eligible hit for EACH living assassin, not one shared hit for the army.
	war.abilities.reset("Hasan Sabbah", "Halid bin Velid")
	war.cast_ability(0)
	war.cast_ability(1)
	close(war.abilities.remaining[0], 50.0, "Hasan cooldown")
	check(war.abilities.pending[0].size() == 2, "Each assassin armed independently")
	check(war.ability_buttons[0].text.contains("İLK VURUŞ: 2 birlik"), "HUD shows armed assassin count")
	var assassin: Dictionary = assassins[0]
	var base_assassin: float = assassin["damage"]
	close(strike(assassin, target, 10.0), 0.0, "Out of range cannot hit")
	check(war.abilities.pending[0].size() == 2, "Movement does not consume first hit")
	close(strike(assassin, target, 1.0, 5.0), 0.0, "Attack timer blocks hit")
	check(war.abilities.pending[0].size() == 2, "Attack cooldown does not consume first hit")
	var empty: Array[Dictionary] = []
	war.combat.update_unit(assassin, empty, 0.0, 0, 0, war.battlefield, Callable(war.siege, "damage"))
	check(war.abilities.pending[0].size() == 2, "No target does not consume first hit")
	target["alive"] = false
	var dead_targets: Array[Dictionary] = [target]
	war.combat.update_unit(assassin, dead_targets, 0.0, 0, 0, war.battlefield, Callable(war.siege, "damage"))
	check(war.abilities.pending[0].size() == 2, "Dead target cannot consume first hit")
	strike(war.red_units[3], target)
	check(war.abilities.pending[0].size() == 2, "Enemy assassin cannot consume friendly bonus")
	strike(cavalry, target)
	check(war.abilities.pending[0].size() == 2, "Other types cannot consume assassin bonus")
	close(strike(assassin, target), base_assassin * 1.35, "First eligible hit gets exact 35 percent")
	close(strike(assassin, target), base_assassin, "Second hit is unbuffed")
	close(strike(assassins[1], target), float(assassins[1]["damage"]) * 1.35, "Second assassin has own first hit")
	check(war.abilities.pending[0].is_empty(), "All first hits consumed")
	war.abilities.update(50.0)
	war.cast_ability(0)
	assassins[1]["alive"] = false
	war.abilities.update(0.0)
	check(war.abilities.pending[0].size() == 1, "Dead unit's pending effect removed")
	war.abilities.update(50.0)
	check(not war.abilities.ready(0), "Unconsumed first hit cannot be stacked by recasting")
	assassin["alive"] = false
	war.abilities.update(0.0)
	check(war.abilities.ready(0), "Dead pending units cannot permanently lock button")
	check(not war.abilities.cast(war, 0), "No living assassins rejects activation")
	close(war.abilities.remaining[0], 0.0, "Failed activation consumes no cooldown")
	assassin["alive"] = true
	war.abilities.reset("Halid bin Velid", "Hasan Sabbah")
	war.cast_ability(1)
	close(strike(assassin, target), base_assassin * 1.35, "Secondary Hasan also gives exact requested bonus")
	war.abilities.reset("Hasan Sabbah", "Hasan Sabbah")
	check(war.abilities.definition(1).is_empty(), "Duplicate commander rejected")
	check(not war.abilities.cast(war, -1) and not war.abilities.cast(war, 5), "Invalid slots rejected")
	# Deterministic lethal infantry attack still flows through the old casualty accounting.
	var soldier: Node3D = infantry["root"]
	var enemy: Node3D = target["root"]
	soldier.position = Vector3.ZERO
	enemy.position = Vector3(1, 0, 0)
	infantry["timer"] = 0.0
	target["hp"] = 1.0
	var opponents: Array[Dictionary] = [target]
	var fallen_before: int = war.combat.fallen_red
	war.combat.update_unit(infantry, opponents, 0.0, 0, 0, war.battlefield, Callable(war.siege, "damage"))
	check(not target["alive"] and war.combat.fallen_red == fallen_before + 1, "Kills still count casualties")
	# Force a defeat to verify existing XP, losses, saves and idempotent finishing.
	for unit in war.blue_units: unit["alive"] = false
	var army_before: int = expansion.infantry
	war.finish_battle()
	check(not war.ability_panel.visible, "Battle end hides HUD")
	check(not war.combat.attack_damage_modifier.is_valid() and not war.siege.damage_modifier.is_valid(), "Battle end disconnects modifiers")
	check(war.abilities.pending[0].is_empty() and war.abilities.active_time == [0.0, 0.0], "Battle end clears effects")
	check(not war.abilities.cast(war, 0), "No casts outside battle")
	check(expansion.infantry < army_before, "Existing unit losses preserved")
	var xp: int = progression.get_hero("Fatih Sultan Mehmet")["xp"]
	check(xp == 50, "Primary defeat XP preserved")
	check(int(progression.get_hero("Halid bin Velid")["xp"]) == 30, "Secondary defeat XP preserved")
	check(FileAccess.file_exists("user://roc_war_31.json"), "Existing war save written")
	check(FileAccess.file_exists("user://hero_progression_v1.json"), "Progression save written")
	war.finish_battle()
	check(int(progression.get_hero("Fatih Sultan Mehmet")["xp"]) == xp, "Finish cannot award XP twice")
	expansion.infantry = 10
	war.begin_battle()
	check(war.fighting and war.abilities.remaining == [0.0, 0.0], "New battle resets cooldowns")
	war.primary_commander = "Hasan Sabbah"
	check(war.abilities.commanders[0] == "Fatih Sultan Mehmet", "Mid-battle selection cannot change snapshot")
	war.finish_battle()
	expansion.infantry = 0
	expansion.archers = 0
	expansion.cavalry = 0
	war.extra_army = {"assassin": 0, "siege": 0}
	war.begin_battle()
	check(not war.fighting and not war.ability_panel.visible, "Rejected battle keeps HUD hidden")
	game.queue_free()
	await process_frame
	print("Build 88.1 checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
