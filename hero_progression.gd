
extends Node

# RISE OF CONQUEST - HERO PROGRESSION 1.0
const SAVE_FILE := "user://hero_progression_v1.json"
const MAX_LEVEL := 60
const MAX_STARS := 6

var heroes: Dictionary = {}


func _ready() -> void:
	load_data()


func get_hero(hero_name: String) -> Dictionary:
	if not heroes.has(hero_name):
		heroes[hero_name] = {
			"level": 1,
			"xp": 0,
			"stars": 1,
			"skill_points": 0,
			"skills": [0, 0, 0, 0]
		}
	return heroes[hero_name]


func xp_needed(level: int) -> int:
	return 100 + (level - 1) * 45


func add_xp(hero_name: String, amount: int) -> int:
	if amount <= 0:
		return 0

	var hero: Dictionary = get_hero(hero_name)
	var levels_gained := 0
	hero["xp"] = int(hero["xp"]) + amount

	while int(hero["level"]) < MAX_LEVEL and int(hero["xp"]) >= xp_needed(int(hero["level"])):
		hero["xp"] = int(hero["xp"]) - xp_needed(int(hero["level"]))
		hero["level"] = int(hero["level"]) + 1
		hero["skill_points"] = int(hero["skill_points"]) + 1
		levels_gained += 1

	if int(hero["level"]) >= MAX_LEVEL:
		hero["xp"] = 0

	save_data()
	return levels_gained


func upgrade_star(hero_name: String) -> bool:
	var hero: Dictionary = get_hero(hero_name)
	var stars := int(hero["stars"])

	if stars >= MAX_STARS:
		return false

	if int(hero["level"]) < stars * 10:
		return false

	hero["stars"] = stars + 1
	save_data()
	return true


func upgrade_skill(hero_name: String, index: int) -> bool:
	if index < 0 or index >= 4:
		return false

	var hero: Dictionary = get_hero(hero_name)

	if int(hero["skill_points"]) <= 0:
		return false

	var skills: Array = hero["skills"]

	if int(skills[index]) >= 5:
		return false

	skills[index] = int(skills[index]) + 1
	hero["skill_points"] = int(hero["skill_points"]) - 1
	save_data()
	return true


func save_data() -> void:
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(heroes))
		file.close()


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return

	var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null:
		return

	var parsed: Variant = JSON.parse_string(
		file.get_as_text()
	)
	file.close()

	if parsed is Dictionary:
		heroes = parsed
