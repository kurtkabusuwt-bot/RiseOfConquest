Dördüncü dosya: tests/test_build_89.gd — yeni dosya.

extends SceneTree

const AI = preload("res://war_ai_89.gd")
const Combat = preload("res://war_combat_40.gd")
const Abilities = preload("res://hero_abilities.gd")
const Siege = preload("res://war_siege_40.gd")
const War = preload("res://war_build_88.gd")
const Progression = preload("res://hero_progression.gd")
const HeroCombat = preload("res://hero_combat.gd")

class Battle:
	extends Node
	var fighting := true
	var combat = Combat.new()
	var blue_units: Array[Dictionary] = []
	var red_units: Array[Dictionary] = []

class Game:
	extends Node3D
	var foods := 10000
	var coins := 0
	var woods := 0
	var stones := 0

class Expansion:
	extends Node
	var infantry := 8
	var archers := 5
	var cavalry := 4
	var castle_level := 4
	func save_expansion(_manual: bool) -> void: pass

var checks := 0
var failures := 0
var arena: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func close(actual: float, expected: float, label: String) -> void:
	check(is_equal_approx(actual, expected), "%s: got %f expected %f" % [label, actual, expected])

func unit(kind: String, friendly: bool, pos: Vector3) -> Dictionary:
	var node := Node3D.new()
	arena.add_child(node)
	node.position = pos
	var reach := 1.2
	var speed := 2.2
	var damage := 10.0
	var cooldown := 1.0
	match kind:
		"cavalry": reach = 1.8; speed = 3.8; damage = 20.0
		"archers": reach = 12.0; speed = 1.7; damage = 12.0; cooldown = 1.6
		"siege": reach = 14.0; speed = 1.1; damage = 35.0; cooldown = 3.0
		"assassin": speed = 3.3; damage = 23.0; cooldown = 0.7
	return {"root": node, "kind": kind, "friendly": friendly, "alive": true,
		"hp": 100000.0, "damage": damage, "reach": reach, "speed": speed,
		"cooldown": cooldown, "timer": 0.0, "attack": 0.0, "fall": 0.0}

func opponents(items: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.assign(items)
	return result

func no_wall(_amount: float) -> void: pass

func step(combat: RefCounted, actor: Dictionary, enemies: Array[Dictionary], dt: float, order: int = 0, allies: Array[Dictionary] = []) -> void:
	combat.update_unit(actor, enemies, dt, order, 0, arena, no_wall, allies)

func run() -> void:
	arena = Node3D.new()
	root.add_child(arena)
	for friendly in [true, false]:
		test_selection(friendly)
		test_defense_and_cover(friendly)
		test_ranged(friendly)
		test_flank_and_charge(friendly)
	test_stability()
	test_separation_and_recovery()
	test_abilities()
	test_crowd()
	await test_battle_integration()
	arena.queue_free()
	await process_frame
	print("Build 89.1 checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)

func test_selection(friendly: bool) -> void:
	var forward := 1.0 if friendly else -1.0
	for kind in ["infantry", "cavalry", "archers", "siege", "assassin"]:
		var ai := AI.new()
		var actor := unit(kind, friendly, Vector3.ZERO)
		var infantry := unit("infantry", not friendly, Vector3(forward * 6.0, 0, 0))
		var archer := unit("archers", not friendly, Vector3(forward * 8.0, 0, 0))
		var siege := unit("siege", not friendly, Vector3(forward * 9.0, 0, 0))
		var cavalry := unit("cavalry", not friendly, Vector3(forward * 10.0, 0, 0))
		var expected := "infantry" if kind in ["infantry", "archers"] else "archers"
		if kind == "siege": expected = "siege"
		var chosen := ai.target(actor, opponents([infantry, archer, siege, cavalry]), [], 0.1)
		check(chosen["kind"] == expected, "%s target priority, side %s" % [kind, friendly])
		check(ai.target(actor, [], [], 1.0).is_empty(), "No target clears cached target")
		(archer["root"] as Node3D).free()
		var valid := ai.target(actor, opponents([archer, infantry]), [], 1.0)
		check(not valid.is_empty() and valid["kind"] == "infantry", "Freed enemy root is ignored")

func test_defense_and_cover(friendly: bool) -> void:
	var forward := 1.0 if friendly else -1.0
	var combat := Combat.new()
	var actor := unit("infantry", friendly, Vector3.ZERO)
	var archer := unit("archers", friendly, Vector3(-forward * 2.0, 0, 0))
	var distant := unit("infantry", not friendly, Vector3(forward * 15.0, 0, 0))
	var home: Vector3 = (actor["root"] as Node3D).position
	combat.ai.set_home(actor)
	for i in range(40): step(combat, actor, opponents([distant]), 0.1, 1, opponents([actor, archer]))
	close((actor["root"] as Node3D).position.distance_to(home), 0.0, "Defensive infantry does not chase")
	for i in range(10): step(combat, actor, opponents([distant]), 0.1, 2)
	check((actor["root"] as Node3D).position.x * forward > 1.0, "Charge order advances infantry")
	(actor["root"] as Node3D).position = Vector3.ZERO
	combat.ai.set_home(actor)
	var charger := unit("cavalry", not friendly, Vector3(forward, 0, 1))
	var threats := opponents([charger, distant])
	var choice := combat.ai.target(actor, threats, opponents([actor, archer]), 1.0)
	check(choice["kind"] == "cavalry", "Infantry responds to nearby cavalry threatening archers")
	step(combat, actor, threats, 0.1, 1, opponents([actor, archer]))
	check(actor["ai89"]["mode"] == "protect", "Infantry positions to protect ranged ally")
	check((actor["root"] as Node3D).position.distance_to(home) <= 3.5001, "Defense leash also applies to protection")
	for kind in ["archers", "siege"]:
		var ranged := unit(kind, friendly, Vector3(forward * 3.0, 0, 0))
		var guard := unit("infantry", friendly, Vector3.ZERO)
		step(combat, ranged, opponents([distant]), 0.2, 0, opponents([ranged, guard]))
		check((ranged["root"] as Node3D).position.x * forward < 3.0, "Ranged ally moves behind infantry")

func test_ranged(friendly: bool) -> void:
	var forward := 1.0 if friendly else -1.0
	for kind in ["archers", "siege"]:
		var combat := Combat.new()
		var actor := unit(kind, friendly, Vector3.ZERO)
		var threat := unit("infantry", not friendly, Vector3(forward * 2.0, 0, 0))
		var before: float = (actor["root"] as Node3D).position.distance_to((threat["root"] as Node3D).position)
		step(combat, actor, opponents([threat]), 0.1)
		check((actor["root"] as Node3D).position.distance_to((threat["root"] as Node3D).position) > before, "%s retreats from melee" % kind)
		check(combat.shots.size() == 1, "%s keeps firing while retreating" % kind)
		(actor["root"] as Node3D).position = Vector3(-22.99, 0, 16.99)
		(threat["root"] as Node3D).position = Vector3(-21, 0, 16.5)
		for i in range(20):
			step(combat, actor, opponents([threat]), 0.1)
			var pos: Vector3 = (actor["root"] as Node3D).position
			check(pos.x >= -23.0 and pos.x <= 23.0 and absf(pos.z) <= 17.0, "Ranged retreat remains inside arena")
		combat.reset()
		(actor["root"] as Node3D).position = Vector3.ZERO
		(threat["root"] as Node3D).position = Vector3(forward * 8, 0, 0)
		threat["kind"] = "archers"
		step(combat, actor, opponents([threat]), 0.1)
		close((actor["root"] as Node3D).position.length(), 0.0, "Ranged unit holds position at suitable range")
		combat.reset()

func test_flank_and_charge(friendly: bool) -> void:
	var forward := 1.0 if friendly else -1.0
	for kind in ["cavalry", "assassin"]:
		var combat := Combat.new()
		var actor := unit(kind, friendly, Vector3(-forward * 8, 0, 0))
		var target := unit("archers", not friendly, Vector3.ZERO)
		var dense := opponents([target])
		for i in range(5): dense.append(unit("infantry", not friendly, Vector3(-forward * 3, 0, 4 + float(i) * 0.1)))
		step(combat, actor, dense, 0.1)
		check(actor["ai89"]["mode"] == "flank", "%s chooses flank for soft target" % kind)
		check(float(actor["ai89"]["flank_side"]) < 0.0, "Flank avoids denser upper approach")
		check((actor["root"] as Node3D).position.z < 0.0, "Actual movement follows flank")
		if kind == "cavalry":
			check(bool(actor["charge_ready"]), "Existing distance rule arms charge")
			var hit := false
			for i in range(100):
				step(combat, actor, opponents([target]), 0.1)
				if float(target["hp"]) < 100000.0:
					hit = true
					break
			check(hit and combat.cavalry_charges == 1, "Flanking cavalry eventually lands one charged hit")
			close(100000.0 - float(target["hp"]), 20.0 * 1.85, "Original charge multiplier preserved")
			step(combat, actor, opponents([target]), 0.1)
			check(actor["ai89"]["mode"] == "charge_reset", "Cavalry creates distance after initial attack")
		combat.reset()
	var heavy_combat := Combat.new()
	var horse := unit("cavalry", friendly, Vector3(-forward * 10, 0, 0))
	var packed := opponents([])
	for i in range(4): packed.append(unit("infantry", not friendly, Vector3(0, 0, float(i) * 0.2)))
	step(heavy_combat, horse, packed, 0.1)
	check(horse["ai89"]["mode"] == "flank", "Dense melee formation also triggers alternative cavalry approach")

func test_stability() -> void:
	var ai := AI.new()
	var actor := unit("assassin", true, Vector3.ZERO)
	var first := unit("archers", false, Vector3(8, 0, 0))
	var rival := unit("archers", false, Vector3(8.1, 0, 0))
	var enemies := opponents([first, rival])
	check(ai.target(actor, enemies, [], 0.1) == first, "Initial target is best candidate")
	(rival["root"] as Node3D).position.x = 7.5
	check(ai.target(actor, enemies, [], 0.4) == first, "Target lock prevents immediate switching")
	check(ai.target(actor, enemies, [], 1.0) == first, "Hysteresis rejects tiny score improvement")
	(rival["root"] as Node3D).position.x = 2.5
	check(ai.target(actor, enemies, [], 1.0) == rival, "Substantially better target can replace distant target")
	rival["alive"] = false
	check(ai.target(actor, enemies, [], 0.01) == first, "Dead target replaced without waiting for decision interval")
	var scans: int = ai.target_evaluations
	for i in range(10): ai.target(actor, enemies, [], 0.01)
	check(ai.target_evaluations == scans, "Stable target avoids per-frame rescoring")
	var near := unit("infantry", false, Vector3(0.5, 0, 0))
	(actor["root"] as Node3D).position = Vector3(7.5, 0, 0)
	check(ai.target(actor, opponents([first, near]), [], 1.0) == first, "Target in attack range is retained")
	var combat := Combat.new()
	(actor["root"] as Node3D).position = Vector3(100, 0, -100)
	step(combat, actor, [], 0.1)
	var pos: Vector3 = (actor["root"] as Node3D).position
	check(pos.x <= 23 and pos.z >= -17, "No-target path still enforces bounds")

func test_separation_and_recovery() -> void:
	var combat := Combat.new()
	var first := unit("infantry", true, Vector3.ZERO)
	var second := unit("infantry", true, Vector3.ZERO)
	var enemy := unit("infantry", false, Vector3(15, 0, 0))
	var allies := opponents([first, second])
	var enemies := opponents([enemy])
	for i in range(10):
		combat.prepare_frame(allies, enemies)
		step(combat, first, enemies, 0.1, 1, allies)
		step(combat, second, enemies, 0.1, 1, allies)
	check((first["root"] as Node3D).position.distance_to((second["root"] as Node3D).position) > 0.5, "Coincident allied infantry separate")
	combat.reset()
	var attempted_escape := false
	for i in range(10):
		(first["root"] as Node3D).position = Vector3.ZERO
		step(combat, first, enemies, 0.2)
		attempted_escape = attempted_escape or first["ai89"]["mode"] == "recover"
	check(combat.ai.recoveries > 0, "Blocked movement triggers bounded recovery")
	check(attempted_escape, "Stuck unit attempts lateral escape")
	var slow_combat := Combat.new()
	var slow := unit("siege", true, Vector3(-20, 0, 0))
	var distant := unit("archers", false, Vector3(20, 0, 0))
	for i in range(180): step(slow_combat, slow, opponents([distant]), 1.0 / 60.0)
	check(slow_combat.ai.recoveries == 0, "Slow valid siege movement is not mistaken for being stuck")
	check((slow["root"] as Node3D).position.x > -18, "Slow siege progresses steadily")
	var lag_combat := Combat.new()
	var lag_actor := unit("infantry", true, Vector3.ZERO)
	var close_target := unit("archers", false, Vector3(2, 0, 0))
	step(lag_combat, lag_actor, opponents([close_target]), 2.0)
	close((lag_actor["root"] as Node3D).position.x, 0.8, "Large frame delta cannot overshoot desired attack position")
	check(float(close_target["hp"]) < 100000.0, "Attack still resolves after a slow frame")

func test_abilities() -> void:
	var battle := Battle.new()
	arena.add_child(battle)
	var abilities := Abilities.new()
	var assassin := unit("assassin", true, Vector3.ZERO)
	var target := unit("archers", false, Vector3(10, 0, 0))
	battle.blue_units = opponents([assassin])
	battle.red_units = opponents([target])
	battle.combat.attack_damage_modifier = Callable(abilities, "attack_damage")
	abilities.reset("Hasan Sabbah", "")
	check(abilities.cast(battle, 0), "Hasan activation succeeds")
	step(battle.combat, assassin, [], 0.1)
	step(battle.combat, assassin, battle.red_units, 0.1)
	check(abilities.pending[0].size() == 1, "No target and flanking movement do not consume first hit")
	(target["root"] as Node3D).position = (assassin["root"] as Node3D).position + Vector3(1, 0, 0)
	assassin["timer"] = 0.0
	var criticals: int = battle.combat.critical_hits
	step(battle.combat, assassin, battle.red_units, 0.0)
	var factor := 2.1 if battle.combat.critical_hits > criticals else 1.0
	close(100000.0 - float(target["hp"]), 23.0 * 1.35 * factor, "Hasan bonus remains on first eligible hit")
	check(abilities.pending[0].is_empty(), "Eligible hit consumes exactly one assassin right")
	var before: float = target["hp"]
	criticals = battle.combat.critical_hits
	assassin["timer"] = 0.0
	step(battle.combat, assassin, battle.red_units, 0.0)
	factor = 2.1 if battle.combat.critical_hits > criticals else 1.0
	close(before - float(target["hp"]), 23.0 * factor, "Second hit gets no first-hit bonus")
	var siege_unit := unit("siege", true, Vector3.ZERO)
	(target["root"] as Node3D).position = Vector3(10, 0, 0)
	battle.blue_units = opponents([siege_unit])
	abilities.reset("Fatih Sultan Mehmet", "Halid bin Velid")
	check(abilities.cast(battle, 0), "Fatih activation succeeds")
	var siege := Siege.new()
	siege.build(arena)
	siege.reset(0, false)
	siege.damage_modifier = Callable(abilities, "wall_damage")
	battle.combat.update_unit(siege_unit, battle.red_units, 0.1, 0, 0, arena, Callable(siege, "damage"))
	close(160.0 - siege.wall_hp, 35.0 * 0.6 * 1.3, "Fatih wall bonus still applied once with tactical AI")
	close(float(battle.combat.shots[-1]["damage"]), 35.0 * 1.3, "Fatih projectile bonus still applied once")
	battle.combat.reset()
	var cavalry := unit("cavalry", true, Vector3(-8, 0, 0))
	(target["root"] as Node3D).position = Vector3.ZERO
	target["hp"] = 100000.0
	battle.blue_units = opponents([cavalry])
	check(abilities.cast(battle, 1), "Halid activation succeeds")
	for i in range(100):
		step(battle.combat, cavalry, battle.red_units, 0.1)
		if float(target["hp"]) < 100000.0: break
	close(100000.0 - float(target["hp"]), 20.0 * 1.85 * 1.25, "Halid and cavalry charge compose once")
	battle.combat.reset()
	battle.queue_free()

func test_crowd() -> void:
	var combat := Combat.new()
	var blue: Array[Dictionary] = []
	var red: Array[Dictionary] = []
	var kinds := ["infantry", "archers", "cavalry", "assassin", "siege"]
	for i in range(50):
		blue.append(unit(kinds[i % 5], true, Vector3(-8 + float(i % 10) * 0.1, 0, -5 + float(i / 10))))
		red.append(unit(kinds[i % 5], false, Vector3(8 - float(i % 10) * 0.1, 0, -5 + float(i / 10))))
	var started := Time.get_ticks_usec()
	for frame in range(120):
		combat.prepare_frame(blue, red)
		for actor in blue: step(combat, actor, red, 1.0 / 60.0, 0, blue)
		for actor in red: step(combat, actor, blue, 1.0 / 60.0, 0, red)
		combat.update_shots(1.0 / 60.0)
	for actor in blue + red:
		var pos: Vector3 = (actor["root"] as Node3D).position
		check(is_finite(pos.x) and is_finite(pos.z) and absf(pos.x) <= 23 and absf(pos.z) <= 17, "Crowd unit has finite bounded position")
	check(combat.ai.target_evaluations < 120 * 100 / 4, "Crowd target scoring is throttled")
	print("Crowd 100 units / 120 frames: ", (Time.get_ticks_usec() - started) / 1000.0,
		" ms; target scans: ", combat.ai.target_evaluations, "; candidates: ", combat.ai.candidate_evaluations)
	combat.reset()

func test_battle_integration() -> void:
	var game := Game.new()
	root.add_child(game)
	current_scene = game
	var expansion := Expansion.new()
	expansion.name = "ConquestExpansion"
	game.add_child(expansion)
	var progression := Progression.new()
	progression.name = "HeroProgression"
	game.add_child(progression)
	var hero := HeroCombat.new()
	hero.name = "HeroCombat"
	game.add_child(hero)
	var war := War.new()
	game.add_child(war)
	await process_frame
	war.set_process(false)
	war.extra_army = {"siege": 2, "assassin": 2}
	war.begin_battle()
	check(war.fighting and war.blue_units.size() == 21, "Real 7.3 deployment still works")
	var infantry: Dictionary = war.blue_units[0]
	var home: Vector3 = infantry["ai89"]["home"]
	close((infantry["root"] as Node3D).position.distance_to(home), 0.0, "Home position captured after formation placement")
	war.cast_ability(0)
	for i in range(30):
		if war.fighting: war._process(0.1)
	check(war.combat.ai.frame_ready and war.combat.ai.target_evaluations > 0, "Actual battle loop prepares spatial data and runs tactical AI")
	check(bool(infantry["ai89"]["has_support"]), "Actual battle passes friendly allies into AI")
	for actor in war.blue_units + war.red_units:
		var pos: Vector3 = (actor["root"] as Node3D).position
		check(absf(pos.x) <= 23 and absf(pos.z) <= 17, "Real battle keeps both armies in arena")
	war.finish_battle()
	game.queue_free()
	await process_frame
