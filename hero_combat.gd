
extends Node

# RISE OF CONQUEST - HERO COMBAT 1.0
# Godot 4.4.1
# Calculates commander stats and army bonuses.
# Does not modify combat damage until called by the war system.

const UNIT_TYPES := ["Piyade", "Süvari", "Okçu", "Kuşatma", "Suikastçı"]
const HERO_ROLES := {
	"Fatih Sultan Mehmet": "Kuşatma", "Yavuz Sultan Selim": "Süvari",
	"Kanuni Sultan Süleyman": "Kuşatma", "Barbaros Hayreddin Paşa": "Kuşatma",
	"İdris-i Bitlisî": "Piyade", "Julius Caesar": "Piyade",
	"Scipio Africanus": "Piyade", "Augustus": "Piyade",
	"Marcus Aurelius": "Piyade", "Trajan": "Kuşatma",
	"Ragnar Lodbrok": "Piyade", "Björn Ironside": "Piyade",
	"Ivar the Boneless": "Okçu", "Harald": "Süvari", "Lagertha": "Piyade",
	"Cengiz Han": "Süvari", "Subutay": "Süvari",
	"Kubilay Han": "Süvari", "Cebe Noyan": "Okçu", "Batu Han": "Süvari",
	"Qin Shi Huang": "Kuşatma", "Guan Yu": "Süvari",
	"Zhuge Liang": "Kuşatma", "Sun Tzu": "Okçu", "Hua Mulan": "Okçu",
	"Halid bin Velid": "Süvari", "Selahaddin Eyyubi": "Süvari",
	"Tarık bin Ziyad": "Piyade", "Harun Reşid": "Okçu",
	"Amr bin Âs": "Piyade", "Hasan Sabbah": "Suikastçı",
	"Raşidüddin Sinan": "Suikastçı", "Kiyâ Büzürgümmîd": "Suikastçı",
	"Nûreddin Muhammed II": "Suikastçı", "Rükneddin Hürşah": "Suikastçı"
}
const LEGENDARY := [
	"Fatih Sultan Mehmet", "Yavuz Sultan Selim", "Kanuni Sultan Süleyman",
	"Julius Caesar", "Augustus", "Ragnar Lodbrok", "Björn Ironside",
	"Cengiz Han", "Subutay", "Qin Shi Huang", "Guan Yu",
	"Halid bin Velid", "Selahaddin Eyyubi", "Hasan Sabbah"
]

@onready var progression: Node = get_node_or_null("../HeroProgression")


func get_hero_stats(hero_name: String) -> Dictionary:
	if not HERO_ROLES.has(hero_name):
		return {}
	var hero := _get_progress(hero_name)
	var level: int = clampi(int(hero.get("level", 1)), 1, 60)
	var stars: int = clampi(int(hero.get("stars", 1)), 1, 6)
	var skills: Array = hero.get("skills", [0, 0, 0, 0])
	var legendary: bool = hero_name in LEGENDARY
	var base: float = 1.15 if legendary else 1.0
	var skill_attack: int = _skill_value(skills, 0)
	var skill_defense: int = _skill_value(skills, 1)
	var skill_health: int = _skill_value(skills, 2)
	var skill_command: int = _skill_value(skills, 3)
	var attack: int = roundi((40.0 + level * 4.0 + stars * 12.0) * base * (1.0 + skill_attack * 0.04))
	var defense: int = roundi((35.0 + level * 3.0 + stars * 10.0) * base * (1.0 + skill_defense * 0.04))
	var health: int = roundi((350.0 + level * 35.0 + stars * 100.0) * base * (1.0 + skill_health * 0.04))
	var capacity: int = 500 + level * 50 + stars * 200 + skill_command * 150
	return {
		"name": hero_name,
		"rarity": "Efsanevi" if legendary else "Nadir",
		"specialty": HERO_ROLES[hero_name],
		"level": level,
		"stars": stars,
		"attack": attack,
		"defense": defense,
		"health": health,
		"capacity_bonus": capacity,
		"power": attack * 3 + defense * 2 + health / 10 + capacity / 5
	}


func get_army_bonuses(hero_name: String, unit_type: String) -> Dictionary:
	if not UNIT_TYPES.has(unit_type):
		return {}
	var stats := get_hero_stats(hero_name)
	if stats.is_empty():
		return {}
	var hero := _get_progress(hero_name)
	var skills: Array = hero.get("skills", [0, 0, 0, 0])
	var level: int = int(stats["level"])
	var stars: int = int(stats["stars"])
	var specialty_match: bool = str(stats["specialty"]) == unit_type
	var specialty_bonus: float = 0.10 if specialty_match else 0.0
	return {
		"attack_multiplier": 1.0 + level * 0.002 + stars * 0.01 + _skill_value(skills, 0) * 0.02 + specialty_bonus,
		"defense_multiplier": 1.0 + level * 0.0015 + stars * 0.008 + _skill_value(skills, 1) * 0.02 + specialty_bonus * 0.5,
		"health_multiplier": 1.0 + level * 0.0015 + stars * 0.008 + _skill_value(skills, 2) * 0.02 + specialty_bonus * 0.5,
		"capacity_bonus": int(stats["capacity_bonus"]),
		"specialty_match": specialty_match
	}


func get_two_commander_bonuses(primary: String, secondary: String, unit_type: String) -> Dictionary:
	var first := get_army_bonuses(primary, unit_type)
	if first.is_empty():
		return {}
	if secondary == primary or secondary.is_empty():
		return first
	var second := get_army_bonuses(secondary, unit_type)
	if second.is_empty():
		return first
	# Secondary commander contributes half of their bonus.
	return {
		"attack_multiplier": float(first["attack_multiplier"]) + (float(second["attack_multiplier"]) - 1.0) * 0.5,
		"defense_multiplier": float(first["defense_multiplier"]) + (float(second["defense_multiplier"]) - 1.0) * 0.5,
		"health_multiplier": float(first["health_multiplier"]) + (float(second["health_multiplier"]) - 1.0) * 0.5,
		"capacity_bonus": int(first["capacity_bonus"]) + roundi(int(second["capacity_bonus"]) * 0.5),
		"specialty_match": bool(first["specialty_match"]) or bool(second["specialty_match"])
	}


func _get_progress(hero_name: String) -> Dictionary:
	if progression != null and progression.has_method("get_hero"):
		return progression.get_hero(hero_name)
	return {"level": 1, "stars": 1, "skills": [0, 0, 0, 0]}


func _skill_value(skills: Array, index: int) -> int:
	if index >= skills.size():
		return 0
	return clampi(int(skills[index]), 0, 5)
