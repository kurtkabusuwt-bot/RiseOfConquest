extends Node

# RISE OF CONQUEST - KINGDOM MODULE LOADER 100
# Attach this script to one Node under main.tscn when ready.
# Loads modules 03-50; modules 01 and 02 remain in existing GitHub files.

var modules: Dictionary = {}

func _ready() -> void:
    _install_modules()

func _install_modules() -> void:
    _install("resource_fields", "res://03_resource_fields_100.gd")
    _install("resource_gathering", "res://04_resource_gathering_100.gd")
    _install("neutral_camps", "res://05_neutral_camps_100.gd")
    _install("landmarks", "res://06_landmarks_100.gd")
    _install("fog_of_war", "res://07_fog_of_war_100.gd")
    _install("map_markers", "res://08_map_markers_100.gd")
    _install("map_search", "res://09_map_search_100.gd")
    _install("city_relocation", "res://10_city_relocation_100.gd")
    _install("troop_roster", "res://11_troop_roster_100.gd")
    _install("troop_training", "res://12_troop_training_100.gd")
    _install("army_formations", "res://13_army_formations_100.gd")
    _install("army_march", "res://14_army_march_100.gd")
    _install("battle_resolver", "res://15_battle_resolver_100.gd")
    _install("commander_skills", "res://16_commander_skills_100.gd")
    _install("siege_system", "res://17_siege_system_100.gd")
    _install("hospital", "res://18_hospital_100.gd")
    _install("rally_system", "res://19_rally_system_100.gd")
    _install("battle_reports", "res://20_battle_reports_100.gd")
    _install("alliance_core", "res://21_alliance_core_100.gd")
    _install("alliance_roles", "res://22_alliance_roles_100.gd")
    _install("alliance_territory", "res://23_alliance_territory_100.gd")
    _install("alliance_flags", "res://24_alliance_flags_100.gd")
    _install("alliance_fortress", "res://25_alliance_fortress_100.gd")
    _install("alliance_resources", "res://26_alliance_resources_100.gd")
    _install("diplomacy", "res://27_diplomacy_100.gd")
    _install("alliance_help", "res://28_alliance_help_100.gd")
    _install("alliance_missions", "res://29_alliance_missions_100.gd")
    _install("kingdom_throne", "res://30_kingdom_throne_100.gd")
    _install("building_queues", "res://31_building_queues_100.gd")
    _install("construction_timers", "res://32_construction_timers_100.gd")
    _install("research_tree", "res://33_research_tree_100.gd")
    _install("economy", "res://34_economy_100.gd")
    _install("trading", "res://35_trading_100.gd")
    _install("hero_growth", "res://36_hero_growth_100.gd")
    _install("equipment", "res://37_equipment_100.gd")
    _install("quests", "res://38_quests_100.gd")
    _install("daily_rewards", "res://39_daily_rewards_100.gd")
    _install("civilization_bonus", "res://40_civilization_bonus_100.gd")
    _install("citizens", "res://41_citizens_100.gd")
    _install("npc_requests", "res://42_npc_requests_100.gd")
    _install("weather_cycle", "res://43_weather_cycle_100.gd")
    _install("camera_bookmarks", "res://44_camera_bookmarks_100.gd")
    _install("battle_hud_state", "res://45_battle_hud_state_100.gd")
    _install("notifications", "res://46_notifications_100.gd")
    _install("player_profile", "res://47_player_profile_100.gd")
    _install("save_integrity", "res://48_save_integrity_100.gd")
    _install("performance", "res://49_performance_100.gd")
    _install("kingdom_dashboard", "res://50_kingdom_dashboard_100.gd")

func _install(key: String, path: String) -> void:
    if modules.has(key):
        return
    var script: Script = load(path) as Script
    if script == null:
        push_warning("Missing kingdom module: " + path)
        return
    var instance := Node.new()
    instance.name = key
    instance.set_script(script)
    add_child(instance)
    modules[key] = instance

func get_module(key: String) -> Node:
    return modules.get(key) as Node

func export_all() -> Dictionary:
    var data := {}
    for key in modules.keys():
        data[key] = modules[key].call("export_state")
    return data

func import_all(data: Dictionary) -> void:
    for key in data.keys():
        if modules.has(key) and data[key] is Dictionary:
            modules[key].call("import_state", data[key])
