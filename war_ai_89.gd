
extends RefCounted

# Battle-local tactics only. This module never edits damage, HP, cooldowns or abilities.
const DECISION_INTERVAL := 0.35
const TARGET_LOCK := 0.8
const CELL_SIZE := 4.0
const MIN_X := -23.0
const MAX_X := 23.0
const MIN_Z := -17.0
const MAX_Z := 17.0

var grids: Array[Dictionary] = [{}, {}]
var by_id: Dictionary = {}
var frame_ready := false
var target_evaluations := 0
var candidate_evaluations := 0
var recoveries := 0

func reset() -> void:
	grids = [{}, {}]
	by_id.clear()
	frame_ready = false
	target_evaluations = 0
	candidate_evaluations = 0
	recoveries = 0

func valid(unit: Dictionary) -> bool:
	return not unit.is_empty() and bool(unit.get("alive", false)) and is_instance_valid(unit.get("root"))

func unit_id(unit: Dictionary) -> int:
	return (unit["root"] as Node3D).get_instance_id()

func cell(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x / CELL_SIZE), floori(pos.z / CELL_SIZE))

func prepare_frame(blue: Array[Dictionary], red: Array[Dictionary]) -> void:
	grids = [{}, {}]
	by_id.clear()
	for army in [blue, red]:
		for unit in army:
			if not valid(unit):
				continue
			by_id[unit_id(unit)] = unit
			var side := 0 if bool(unit["friendly"]) else 1
			var key := cell((unit["root"] as Node3D).position)
			if not grids[side].has(key):
				grids[side][key] = []
			grids[side][key].append(unit)
	frame_ready = true

func nearby(pos: Vector3, side: int, fallback: Array[Dictionary]) -> Array[Dictionary]:
	if not frame_ready:
		return fallback
	var result: Array[Dictionary] = []
	var center := cell(pos)
	for x in range(-1, 2):
		for z in range(-1, 2):
			for unit in grids[side].get(center + Vector2i(x, z), []):
				result.append(unit)
	return result

func clamp_position(pos: Vector3) -> Vector3:
	return Vector3(clampf(pos.x, MIN_X, MAX_X), pos.y, clampf(pos.z, MIN_Z, MAX_Z))

func set_home(unit: Dictionary) -> void:
	unit["ai89"] = {}
	state(unit)

func state(unit: Dictionary) -> Dictionary:
	if not unit.has("ai89") or unit["ai89"].is_empty():
		var pos: Vector3 = (unit["root"] as Node3D).position
		unit["ai89"] = {
			"home": pos, "target_id": 0, "decision": 0.0, "lock": 0.0,
			"threat_id": 0, "support": pos, "has_support": false,
			"flank_side": 1.0 if unit_id(unit) % 2 == 0 else -1.0,
			"flank_phase": 0, "flank_goal": pos, "flank_needed": false, "mode": "hold",
			"has_attacked": false, "reset_wait": 0.0, "withdraw": false,
			"last_pos": pos, "wanted_move": false, "stalled": 0.0, "recovery": 0.0
		}
	return unit["ai89"]

func resolve(id: int, opponents: Array[Dictionary]) -> Dictionary:
	if frame_ready:
		var cached: Dictionary = by_id.get(id, {})
		return cached if valid(cached) else {}
	for unit in opponents:
		if valid(unit) and unit_id(unit) == id:
			return unit
	return {}

func support_for(unit: Dictionary, allies: Array[Dictionary]) -> Dictionary:
	var best: Dictionary = {}
	var distance := INF
	var kind := str(unit["kind"])
	var pos: Vector3 = (unit["root"] as Node3D).position
	for ally in allies:
		if not valid(ally) or unit_id(ally) == unit_id(unit):
			continue
		var wanted := str(ally["kind"]) == "infantry"
		if kind == "infantry":
			wanted = str(ally["kind"]) == "archers"
		if not wanted:
			continue
		var d := pos.distance_squared_to((ally["root"] as Node3D).position)
		if d < distance:
			distance = d
			best = ally
	return best

func score(unit: Dictionary, enemy: Dictionary, info: Dictionary) -> float:
	candidate_evaluations += 1
	var pos: Vector3 = (unit["root"] as Node3D).position
	var target: Vector3 = (enemy["root"] as Node3D).position
	var distance := pos.distance_to(target)
	var value := distance
	var enemy_kind := str(enemy["kind"])
	match str(unit["kind"]):
		"infantry":
			if enemy_kind == "infantry" and distance < 10.0:
				value *= 0.70
			elif enemy_kind == "cavalry" and distance < 8.0:
				value *= 0.65
			if bool(info["has_support"]) and target.distance_to(info["support"]) < 5.0:
				value *= 0.55
		"cavalry":
			if enemy_kind == "archers": value *= 0.55
			elif enemy_kind == "siege": value *= 0.60
			elif enemy_kind == "infantry": value *= 1.25
		"archers":
			if enemy_kind == "infantry": value *= 0.85
			if distance <= float(unit["reach"]): value *= 0.80
		"siege":
			if enemy_kind == "siege": value *= 0.55
			elif enemy_kind == "cavalry": value *= 0.75
		"assassin":
			if enemy_kind == "archers": value *= 0.50
			elif enemy_kind == "siege": value *= 0.60
			elif enemy_kind == "infantry": value *= 1.30
	# Nearby dangerous melee units cannot be ignored just because a soft target exists.
	if enemy_kind in ["cavalry", "assassin"] and distance < 3.0:
		value *= 0.80
	return value

func target(unit: Dictionary, opponents: Array[Dictionary], allies: Array[Dictionary], delta: float, force: bool = false) -> Dictionary:
	if not valid(unit):
		return {}
	var info := state(unit)
	info["decision"] = maxf(0.0, float(info["decision"]) - maxf(0.0, delta))
	info["lock"] = maxf(0.0, float(info["lock"]) - maxf(0.0, delta))
	info["reset_wait"] = maxf(0.0, float(info["reset_wait"]) - maxf(0.0, delta))
	var previous := resolve(int(info["target_id"]), opponents)
	if not force and float(info["decision"]) > 0.0:
		if valid(previous) or (int(info["target_id"]) == 0 and delta > 0.0):
			return previous
	target_evaluations += 1
	# A per-unit offset spreads subsequent decision scans over several frames.
	info["decision"] = DECISION_INTERVAL + float(unit_id(unit) % 5) * 0.01
	var support := support_for(unit, allies)
	info["has_support"] = not support.is_empty()
	if not support.is_empty(): info["support"] = (support["root"] as Node3D).position
	var pos: Vector3 = (unit["root"] as Node3D).position
	var best: Dictionary = {}
	var best_score := INF
	var threat_distance := INF
	info["threat_id"] = 0
	for enemy in opponents:
		if not valid(enemy): continue
		var d := pos.distance_squared_to((enemy["root"] as Node3D).position)
		if str(enemy["kind"]) not in ["archers", "siege"] and d < threat_distance:
			threat_distance = d
			info["threat_id"] = unit_id(enemy)
		var value := score(unit, enemy, info)
		if value < best_score:
			best_score = value
			best = enemy
	if not force and valid(previous) and not best.is_empty() and unit_id(previous) != unit_id(best):
		var in_reach := pos.distance_to((previous["root"] as Node3D).position) <= float(unit["reach"]) + 0.4
		if in_reach or float(info["lock"]) > 0.0 or best_score >= score(unit, previous, info) * 0.75:
			best = previous
	var id := unit_id(best) if not best.is_empty() else 0
	info["flank_needed"] = false
	if id != 0:
		info["flank_needed"] = str(best["kind"]) in ["archers", "siege"]
		if str(unit["kind"]) == "cavalry" and density((best["root"] as Node3D).position, unit, opponents) >= 3:
			info["flank_needed"] = true
	if id != int(info["target_id"]):
		info["target_id"] = id
		info["lock"] = TARGET_LOCK
		info["flank_phase"] = 0
		info["withdraw"] = false
		if id != 0:
			choose_flank(unit, best, opponents, info)
	return best

func density(pos: Vector3, unit: Dictionary, opponents: Array[Dictionary]) -> int:
	var count := 0
	var side := 1 if bool(unit["friendly"]) else 0
	for enemy in nearby(pos, side, opponents):
		if valid(enemy) and pos.distance_squared_to((enemy["root"] as Node3D).position) < 16.0:
			count += 1
	return count

func choose_flank(unit: Dictionary, enemy: Dictionary, opponents: Array[Dictionary], info: Dictionary) -> void:
	var forward := 1.0 if bool(unit["friendly"]) else -1.0
	var pos: Vector3 = (enemy["root"] as Node3D).position
	var left := clamp_position(pos + Vector3(-forward * 3.0, 0, -5.0))
	var right := clamp_position(pos + Vector3(-forward * 3.0, 0, 5.0))
	var left_cost := density(left, unit, opponents) + (2 if left.z <= MIN_Z + 0.5 else 0)
	var right_cost := density(right, unit, opponents) + (2 if right.z >= MAX_Z - 0.5 else 0)
	if left_cost != right_cost:
		info["flank_side"] = -1.0 if left_cost < right_cost else 1.0
	info["flank_goal"] = left if float(info["flank_side"]) < 0.0 else right

func separation(unit: Dictionary, allies: Array[Dictionary]) -> Vector3:
	var pos: Vector3 = (unit["root"] as Node3D).position
	var push := Vector3.ZERO
	var side := 0 if bool(unit["friendly"]) else 1
	for ally in nearby(pos, side, allies):
		if not valid(ally) or unit_id(ally) == unit_id(unit): continue
		var away := pos - (ally["root"] as Node3D).position
		away.y = 0.0
		var distance := away.length()
		if distance >= 1.1: continue
		if distance < 0.001:
			away = Vector3(0, 0, 1.0 if unit_id(unit) > unit_id(ally) else -1.0)
		else:
			away /= distance
		push += away * (1.1 - distance)
	return push.limit_length(1.0)

func move(unit: Dictionary, enemy: Dictionary, opponents: Array[Dictionary], allies: Array[Dictionary], delta: float, order: int, speed: float) -> bool:
	var soldier: Node3D = unit["root"]
	var pos := soldier.position
	var info := state(unit)
	var forward := 1.0 if bool(unit["friendly"]) else -1.0
	var goal := pos
	var kind := str(unit["kind"])
	var reach := float(unit["reach"])
	info["mode"] = "hold"
	var threat := resolve(int(info["threat_id"]), opponents)
	if valid(enemy):
		var destination: Vector3 = (enemy["root"] as Node3D).position
		var distance := pos.distance_to(destination)
		if distance > reach:
			goal = destination - (destination - pos).normalized() * reach
			info["mode"] = "advance"
		if kind in ["archers", "siege"]:
			var danger_radius := 4.0 if kind == "archers" else 5.0
			if valid(threat) and pos.distance_to((threat["root"] as Node3D).position) < danger_radius:
				var away := pos - (threat["root"] as Node3D).position
				if away.length_squared() < 0.001: away = Vector3(-forward, 0, 0)
				goal = pos + away.normalized() * danger_radius
				speed *= 0.7 if kind == "archers" else 0.85
				info["mode"] = "retreat"
			elif bool(info["has_support"]):
				var cover: Vector3 = info["support"]
				var behind := cover - Vector3(forward * 2.5, 0, 0)
				if (pos.x - behind.x) * forward > 0.5:
					goal = Vector3(behind.x, pos.y, pos.z)
					info["mode"] = "cover"
		if kind in ["cavalry", "assassin"]:
			var soft := str(enemy["kind"]) in ["archers", "siege"]
			if bool(info["flank_needed"]) and distance > 4.5 and int(info["flank_phase"]) == 0:
				goal = info["flank_goal"]
				info["mode"] = "flank"
				if pos.distance_to(goal) < 1.0:
					info["flank_phase"] = 1
			if kind == "cavalry" and soft and bool(info["has_attacked"]) and float(info["reset_wait"]) <= 0.0 and distance < 3.0:
				info["withdraw"] = true
				info["reset_wait"] = 7.0
			if bool(info["withdraw"]):
				if distance < 5.2:
					goal = destination + Vector3(-forward * 5.5, 0, float(info["flank_side"]) * 1.5)
					info["mode"] = "charge_reset"
				else:
					info["withdraw"] = false
		if order == 1:
			# Both sides obey the same defensive leash, independent of target distance.
			var home: Vector3 = info["home"]
			goal = home + (goal - home).limit_length(3.5)
			if kind == "infantry" and distance > reach + 3.0:
				goal = home
				info["mode"] = "guard"
			if kind == "infantry" and bool(info["has_support"]) and valid(threat):
				var cover: Vector3 = info["support"]
				if (threat["root"] as Node3D).position.distance_to(cover) < 6.0:
					goal = home + (cover + Vector3(forward * 2.0, 0, 0) - home).limit_length(3.5)
					info["mode"] = "protect"
	var offset := separation(unit, allies)
	var wanted := goal.distance_to(pos) > 0.05 or offset.length_squared() > 0.01
	# Compare with expected per-frame travel, not a fixed threshold that mislabels slow siege troops.
	var progress_threshold := maxf(0.00001, minf(0.02, speed * maxf(0.0, delta) * 0.1))
	if wanted and bool(info["wanted_move"]) and pos.distance_to(info["last_pos"]) < progress_threshold:
		info["stalled"] = float(info["stalled"]) + maxf(0.0, delta)
	else:
		info["stalled"] = 0.0
	if float(info["stalled"]) >= 1.0:
		info["recovery"] = 0.65
		info["stalled"] = 0.0
		info["flank_side"] = -float(info["flank_side"])
		recoveries += 1
	info["last_pos"] = pos
	info["wanted_move"] = wanted
	var velocity := (goal - pos).limit_length(1.0)
	velocity = (velocity + offset * 0.75).limit_length(1.0)
	var recovering := float(info["recovery"]) > 0.0
	if recovering:
		velocity = Vector3(-forward * 0.25, 0, float(info["flank_side"])).normalized()
		info["recovery"] = maxf(0.0, float(info["recovery"]) - maxf(0.0, delta))
		info["mode"] = "recover"
	var travel := velocity * maxf(0.0, speed) * maxf(0.0, delta)
	if not recovering and offset.length_squared() < 0.000001:
		travel = travel.limit_length(pos.distance_to(goal))
	var next := clamp_position(pos + travel)
	# Separation/recovery must not pull defenders beyond their home leash either.
	if order == 1:
		var home: Vector3 = info["home"]
		next = clamp_position(home + (next - home).limit_length(3.5))
	soldier.position = next
	return next.distance_squared_to(pos) > 0.000001

func attack_committed(unit: Dictionary) -> void:
	state(unit)["has_attacked"] = true
