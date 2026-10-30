extends RefCounted

# RISE OF CONQUEST - COMBAT ENGINE 5.0
# Godot 4.4.1 / Android
# Cavalry charge, shields, ranged tactics,
# assassin critical hits, siege targeting.

var shots: Array[Dictionary] = []

# Optional battle-local modifier. Existing callers retain the original behavior.
var attack_damage_modifier: Callable
var fallen_blue := 0
var fallen_red := 0

var cavalry_charges := 0
var shield_blocks := 0
var critical_hits := 0
var arrows_fired := 0

func reset() -> void:
	for shot in shots:
		var node: Node3D = shot["node"]
		if is_instance_valid(node):
			node.queue_free()

	shots.clear()
	fallen_blue = 0
	fallen_red = 0
	cavalry_charges = 0
	shield_blocks = 0
	critical_hits = 0
	arrows_fired = 0

func alive_count(units: Array[Dictionary]) -> int:
	var count := 0

	for unit in units:
		if bool(unit["alive"]):
			count += 1

	return count

func closest(
	unit: Dictionary,
	opponents: Array[Dictionary]
) -> Dictionary:
	var root: Node3D = unit["root"]
	var best: Dictionary = {}
	var best_score := INF
	var kind: String = str(unit["kind"])

	for enemy in opponents:
		if not bool(enemy["alive"]):
			continue

		var target: Node3D = enemy["root"]
		var distance := root.position.distance_to(
			target.position
		)
		var score := distance

		# Assassins seek archers and siege operators.
		if kind == "assassin":
			if str(enemy["kind"]) == "archers":
				score *= 0.55
			elif str(enemy["kind"]) == "siege":
				score *= 0.65

		# Cavalry prioritizes exposed ranged troops.
		if kind == "cavalry":
			if str(enemy["kind"]) == "archers":
				score *= 0.72

		# Siege troops favor heavy targets.
		if kind == "siege":
			if str(enemy["kind"]) == "cavalry":
				score *= 0.75
			elif str(enemy["kind"]) == "siege":
				score *= 0.70

		if score < best_score:
			best_score = score
			best = enemy

	return best

func hit(
	target: Dictionary,
	damage: float,
	attacker_kind: String = ""
) -> void:
	if not bool(target["alive"]):
		return

	var final_damage := damage
	var target_kind: String = str(target["kind"])

	# Infantry shields absorb some incoming damage.
	if target_kind == "infantry":
		if randf() < 0.38:
			final_damage *= 0.48
			shield_blocks += 1

	# Assassins have a chance to strike critically.
	if attacker_kind == "assassin":
		if randf() < 0.28:
			final_damage *= 2.1
			critical_hits += 1

	# Cavalry is more vulnerable to infantry.
	if attacker_kind == "infantry":
		if target_kind == "cavalry":
			final_damage *= 1.18

	target["hp"] = (
		float(target["hp"]) - final_damage
	)

	if float(target["hp"]) <= 0.0:
		target["alive"] = false
		target["fall"] = 0.0

		if bool(target["friendly"]):
			fallen_blue += 1
		else:
			fallen_red += 1

func shoot(
	parent: Node3D,
	unit: Dictionary,
	target: Dictionary,
	damage: float,
	siege: bool
) -> void:
	var source: Node3D = unit["root"]
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()

	if siege:
		mesh.size = Vector3(0.42, 0.42, 0.42)
	else:
		mesh.size = Vector3(0.08, 0.08, 0.70)
		arrows_fired += 1

	node.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.roughness = 0.7

	if siege:
		mat.albedo_color = Color(
			0.28, 0.26, 0.23
		)
	else:
		mat.albedo_color = Color(
			0.86, 0.70, 0.36
		)

	node.material_override = mat
	parent.add_child(node)

	node.position = (
		source.position + Vector3(0, 1.6, 0)
	)

	shots.append({
		"node": node,
		"target": target,
		"damage": damage,
		"speed": 11.0 if siege else 19.0,
		"kind": "siege" if siege else "archers"
	})

func update_shots(delta: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var shot: Dictionary = shots[i]
		var node: MeshInstance3D = shot["node"]
		var target: Dictionary = shot["target"]

		if not is_instance_valid(node):
			shots.remove_at(i)
			continue

		if not bool(target["alive"]):
			node.queue_free()
			shots.remove_at(i)
			continue

		var target_root: Node3D = target["root"]
		var destination: Vector3 = (
			target_root.position +
			Vector3(0, 1.0, 0)
		)

		var direction := destination - node.position
		var distance := direction.length()
		var step := float(shot["speed"]) * delta

		if distance <= step + 0.2:
			hit(
				target,
				float(shot["damage"]),
				str(shot["kind"])
			)
			node.queue_free()
			shots.remove_at(i)
		else:
			node.position += (
				direction.normalized() * step
			)
			if distance > 0.1:
				node.look_at(
					destination, Vector3.UP
				)

func update_unit(
	unit: Dictionary,
	opponents: Array[Dictionary],
	delta: float,
	order: int,
	formation: int,
	parent: Node3D,
	siege_callback: Callable
) -> bool:
	if not bool(unit["alive"]):
		return false

	unit["timer"] = float(unit["timer"]) - delta

	var target := closest(unit, opponents)
	if target.is_empty():
		return false

	var root: Node3D = unit["root"]
	var enemy_root: Node3D = target["root"]

	var direction := (
		enemy_root.position - root.position
	)
	direction.y = 0.0

	var distance := direction.length()
	var reach: float = float(unit["reach"])
	var friendly: bool = bool(unit["friendly"])
	var kind: String = str(unit["kind"])

	var speed: float = float(unit["speed"])
	var moving := false

	if friendly and order == 2:
		speed *= 1.35

	# Cavalry accelerates into a charge.
	if kind == "cavalry" and distance > 4.0:
		speed *= 1.45
		unit["charge_ready"] = true

	# Assassins approach their targets quickly.
	if kind == "assassin" and distance > 2.0:
		speed *= 1.20

	# Archers retreat when an enemy gets too close.
	if kind == "archers" and distance < 4.0:
		if distance > 0.01:
			var retreat := direction.normalized()
			var escape_step := speed * delta * 0.7
			var new_pos: Vector3 = (
				root.position - retreat * escape_step
			)

			# Keep troops inside the battle arena.
			new_pos.x = clampf(
				new_pos.x, -23.0, 23.0
			)
			new_pos.z = clampf(
				new_pos.z, -17.0, 17.0
			)

			moving = (
				new_pos.distance_to(root.position)
				> 0.001
			)
			root.position = new_pos

	else:
		var should_advance := distance > reach

		if friendly and order == 1:
			should_advance = (
				distance > reach + 3.0
			)

		if should_advance and distance > 0.01:
			var step := minf(
				speed * delta,
				maxf(0.0, distance - reach)
			)

			root.position += (
				direction.normalized() * step
			)
			moving = step > 0.001

	if distance > 0.01:
		root.rotation.y = atan2(
			-direction.x,
			-direction.z
		)

	if distance > reach + 0.4:
		return moving

	if float(unit["timer"]) > 0.0:
		return moving

	var cooldown: float = float(unit["cooldown"])

	# Archer line formation improves fire rate.
	if friendly and kind == "archers":
		if formation == 0:
			cooldown *= 0.78

	# Defensive infantry maintains a steady stance.
	if friendly and kind == "infantry":
		if order == 1:
			cooldown *= 0.90

	unit["timer"] = cooldown
	unit["attack"] = 1.0

	var damage: float = float(unit["damage"])

	if friendly:
		if formation == 1 and kind == "infantry":
			damage *= 1.12

		if formation == 2 and kind == "cavalry":
			damage *= 1.25

		if order == 2:
			damage *= 1.15
		elif order == 1:
			damage *= 0.85

	# Charge damage applies once per approach.
	if kind == "cavalry":
		if bool(unit.get("charge_ready", false)):
			damage *= 1.85
			cavalry_charges += 1
			unit["charge_ready"] = false

	# Keep the wall branch unmodified here: Siege.damage applies its bonus once.
	var wall_damage := damage * 0.6
	if attack_damage_modifier.is_valid():
		damage = float(attack_damage_modifier.call(unit, damage))

	if kind == "archers" or kind == "siege":
		shoot(
			parent,
			unit,
			target,
			damage,
			kind == "siege"
		)

		if friendly and kind == "siege":
			siege_callback.call(wall_damage)
	else:
		hit(target, damage, kind)

	return moving
