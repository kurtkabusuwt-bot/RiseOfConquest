extends Node
# Build 101 bridge: separate sandboxed kingdom data from the existing city.
# This intentionally does not modify the old economy or combat state.
signal loaded
const SAVE_FILE := "user://kingdom_build101.json"
const MODULE_FILES := ["res://build101/01_terrain_registry_101.gd", "res://build101/02_region_control_101.gd", "res://build101/03_river_routes_101.gd", "res://build101/04_mountain_passes_101.gd", "res://build101/05_forest_zones_101.gd", "res://build101/06_resource_spawns_101.gd", "res://build101/07_resource_harvest_101.gd", "res://build101/08_resource_respawn_101.gd", "res://build101/09_neutral_patrols_101.gd", "res://build101/10_barbarian_camps_101.gd", "res://build101/11_fortresses_101.gd", "res://build101/12_holy_sites_101.gd", "res://build101/13_city_registry_101.gd", "res://build101/14_city_teleport_101.gd", "res://build101/15_city_shields_101.gd", "res://build101/16_march_orders_101.gd", "res://build101/17_march_paths_101.gd", "res://build101/18_march_speed_101.gd", "res://build101/19_scout_reports_101.gd", "res://build101/20_fog_exploration_101.gd", "res://build101/21_troop_training_101.gd", "res://build101/22_troop_upgrades_101.gd", "res://build101/23_army_slots_101.gd", "res://build101/24_army_morale_101.gd", "res://build101/25_battle_encounters_101.gd", "res://build101/26_battle_damage_101.gd", "res://build101/27_siege_engines_101.gd", "res://build101/28_wall_integrity_101.gd", "res://build101/29_hospital_capacity_101.gd", "res://build101/30_healing_queue_101.gd", "res://build101/31_rally_groups_101.gd", "res://build101/32_reinforcements_101.gd", "res://build101/33_battle_reports_101.gd", "res://build101/34_alliance_members_101.gd", "res://build101/35_alliance_territory_101.gd", "res://build101/36_alliance_flags_101.gd", "res://build101/37_alliance_help_101.gd", "res://build101/38_alliance_diplomacy_101.gd", "res://build101/39_kingdom_throne_101.gd", "res://build101/40_construction_queues_101.gd", "res://build101/41_research_queue_101.gd", "res://build101/42_trade_caravans_101.gd", "res://build101/43_economy_ledger_101.gd", "res://build101/44_hero_assignments_101.gd", "res://build101/45_hero_equipment_101.gd", "res://build101/46_quest_progress_101.gd", "res://build101/47_daily_rewards_101.gd", "res://build101/48_npc_requests_101.gd", "res://build101/49_notification_feed_101.gd", "res://build101/50_performance_budget_101.gd"]
var modules: Dictionary = {}
var kingdom_core: Node = null
var ready_to_use := false
func _ready() -> void:
    call_deferred("_initialize")
func _initialize() -> void:
    var core_script: Script = load("res://kingdom_core_100.gd") as Script
    if core_script != null:
        kingdom_core = Node.new()
        kingdom_core.name = "KingdomCore100"
        kingdom_core.set_script(core_script)
        add_child(kingdom_core)
    for path in MODULE_FILES:
        var script: Script = load(path) as Script
        if script == null:
            push_warning("Build101 missing: " + path)
            continue
        var instance := Node.new()
        instance.set_script(script)
        instance.name = path.get_file().get_basename()
        add_child(instance)
        modules[instance.domain_id] = instance
    load_all()
    ready_to_use = true
    loaded.emit()
    print("Build101 loaded modules: ", modules.size())
func get_module(id: String) -> Node:
    return modules.get(id) as Node
func save_all() -> bool:
    var snapshot: Dictionary = {"version": 101, "modules": {}}
    for key in modules.keys():
        snapshot["modules"][key] = modules[key].export_state()
    var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(snapshot))
    file.close()
    return true
func load_all() -> bool:
    if not FileAccess.file_exists(SAVE_FILE):
        return false
    var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
    if file == null:
        return false
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not (parsed is Dictionary):
        return false
    if int(parsed.get("version", 0)) != 101:
        return false
    var saved: Variant = parsed.get("modules", {})
    if not (saved is Dictionary):
        return false
    for key in saved.keys():
        if modules.has(key) and saved[key] is Dictionary:
            modules[key].import_state(saved[key])
    return true
func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST and ready_to_use:
        save_all()
func get_status() -> Dictionary:
    return {"modules": modules.size(), "core": kingdom_core != null, "ready": ready_to_use}
