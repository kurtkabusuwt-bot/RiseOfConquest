
extends RefCounted

# RISE OF CONQUEST - COMBAT ENGINE 4.0

var shots: Array[Dictionary] = []
var fallen_blue := 0
var fallen_red := 0

func reset() -> void:
	for shot in shots:
		var node: Node3D = shot["node"]
		if is_instance_valid(node):
			node.queue_free()
	shots.clear()
	fallen_blue = 0
	fallen_red = 0

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
	var best_distance := INF

	for enemy in opponents:
		if not bool(enemy["alive"]):
			continue
		var target: Node3D = enemy["root"]
		var distance := root.position.distance_to(target.position)
		if distance < best_distance:
			best_distance = distance
			best = enemy

	return best

func hit(target: Dictionary, damage: float) -> void:
	if not bool(target["alive"]):
		return

	target["hp"] = float(target["hp"]) - damage

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

	node.mesh = mesh

	var mat := StandardMaterial3D.new()
	if siege:
		mat.albedo_color = Color(0.26, 0.25, 0.23)
	else:
		mat.albedo_color = Color(0.84, 0.68, 0.36)

	node.material_override = mat
	parent.add_child(node)
	node.position = source.position + Vector3(0, 1.6, 0)

	shots.append({
		"node": node,
		"target": target,
		"damage": damage,
		"speed": 11.0 if siege else 19.0
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
		var destination := (
			target_root.position + Vector3(0, 1.0, 0)
		)
		var direction := destination - node.position
		var distance := direction.length()
		var step := float(shot["speed"]) * delta

		if distance <= step + 0.2:
			hit(target, float(shot["damage"]))
			node.queue_free()
			shots.remove_at(i)
		else:
			node.position += direction.normalized() * step
			if distance > 0.1:
				node.look_at(destination, Vector3.UP)

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
	var direction := enemy_root.position - root.position
	direction.y = 0.0

	var distance := direction.length()
	var reach: float = float(unit["reach"])
	var friendly: bool = bool(unit["friendly"])
	var kind: String = str(unit["kind"])
	var moving := false

	var speed: float = float(unit["speed"])

	if friendly and order == 2:
		speed *= 1.4

	var should_advance := distance > reach

	if friendly and order == 1:
		should_advance = distance > reach + 3.0

	if should_advance and distance > 0.01:
		var step := minf(
			speed * delta,
			maxf(0.0, distance - reach)
		)
		root.position += direction.normalized() * step
		moving = step > 0.001

	if distance > 0.01:
		root.rotation.y = atan2(
			-direction.x, -direction.z
		)

	if distance > reach + 0.4:
		return moving

	if float(unit["timer"]) > 0.0:
		return moving

	unit["timer"] = float(unit["cooldown"])
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

	if kind == "archers" or kind == "siege":
		shoot(
			parent, unit, target, damage,
			kind == "siege"
		)
		if friendly and kind == "siege":
			siege_callback.call(damage * 0.6)
	else:
		hit(target, damage)

	return moving
