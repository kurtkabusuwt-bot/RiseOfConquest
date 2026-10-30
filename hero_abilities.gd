extends RefCounted

# Build 88.1: exact active bonuses in both slots; 7.3 passive scaling is unchanged.
const ABILITIES := {
	"Fatih Sultan Mehmet": {"name": "Şahi Topu", "cooldown": 45.0, "duration": 8.0,
		"description": "8 saniye boyunca +%30 kuşatma hasarı."},
	"Halid bin Velid": {"name": "Süvari Hücumu", "cooldown": 40.0, "duration": 6.0,
		"description": "6 saniye boyunca +%25 süvari saldırısı."},
	"Hasan Sabbah": {"name": "Gizli Hançer", "cooldown": 50.0, "duration": 0.0,
		"description": "Yaşayan her suikastçının sonraki vuruşuna +%35 hasar."}
}

var commanders: Array[String] = []
var remaining: Array[float] = [0.0, 0.0]
var active_time: Array[float] = [0.0, 0.0]
# Per slot and per unit: a failed attack never consumes a pending strike.
var pending: Array[Dictionary] = [{}, {}]

func reset(primary: String, secondary: String) -> void:
	commanders.assign([primary, secondary if secondary != primary else ""])
	remaining.assign([0.0, 0.0])
	active_time.assign([0.0, 0.0])
	pending = [{}, {}]

func definition(slot: int) -> Dictionary:
	if slot < 0 or slot >= commanders.size():
		return {}
	return ABILITIES.get(commanders[slot], {})

func ready(slot: int) -> bool:
	return not definition(slot).is_empty() and remaining[slot] <= 0.0 and pending[slot].is_empty()

func update(delta: float) -> void:
	for slot in range(remaining.size()):
		remaining[slot] = maxf(0.0, remaining[slot] - maxf(0.0, delta))
		active_time[slot] = maxf(0.0, active_time[slot] - maxf(0.0, delta))
		for id in pending[slot].keys():
			var unit: Dictionary = pending[slot][id]
			if not bool(unit["alive"]) or not is_instance_valid(unit["root"]):
				pending[slot].erase(id)

func cast(war: Node, slot: int) -> bool:
	if not war.fighting or not ready(slot):
		return false
	if war.combat.alive_count(war.blue_units) == 0:
		return false
	var hero := commanders[slot]
	if hero == "Hasan Sabbah":
		for unit in war.blue_units:
			if bool(unit["alive"]) and str(unit["kind"]) == "assassin":
				var soldier: Node3D = unit["root"]
				pending[slot][soldier.get_instance_id()] = unit
		if pending[slot].is_empty():
			return false
	var ability := definition(slot)
	active_time[slot] = float(ability["duration"])
	remaining[slot] = float(ability["cooldown"])
	return true

func timed_bonus(hero: String, bonus: float) -> float:
	for slot in range(commanders.size()):
		if commanders[slot] == hero and active_time[slot] > 0.0:
			return 1.0 + bonus
	return 1.0

# Called only after combat has a living target in range and its attack timer is ready.
# Projectile damage is captured here at launch, never multiplied again at impact.
func attack_damage(unit: Dictionary, damage: float) -> float:
	if not bool(unit["friendly"]) or not bool(unit["alive"]) or damage <= 0.0:
		return damage
	match str(unit["kind"]):
		"siege":
			return damage * timed_bonus("Fatih Sultan Mehmet", 0.30)
		"cavalry":
			return damage * timed_bonus("Halid bin Velid", 0.25)
		"assassin":
			var soldier: Node3D = unit["root"]
			var id := soldier.get_instance_id()
			for slot in range(commanders.size()):
				if commanders[slot] == "Hasan Sabbah" and pending[slot].has(id):
					pending[slot].erase(id)
					return damage * 1.35
	return damage

# All friendly wall-damage paths converge here once, including periodic siege attacks.
func wall_damage(damage: float) -> float:
	return damage * timed_bonus("Fatih Sultan Mehmet", 0.30)
