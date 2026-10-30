extends Node

# Build 102: lightweight registry for 200 on-demand simulation rules.
# Attach through the Build102Bridge node; modules are not all Nodes.
signal rule_executed(rule_id: String, result: Dictionary)
const SAVE_PATH := "user://roc_build102_rules.json"
var state: Dictionary = {}
var scripts: Dictionary = {}
var instances: Dictionary = {}

func _ready() -> void:
    _register_rules()
    load_state()

func _register_rules() -> void:
    scripts["terrain_height"] = "res://build102/001_terrain_height_102.gd"
    scripts["biome"] = "res://build102/002_biome_102.gd"
    scripts["climate"] = "res://build102/003_climate_102.gd"
    scripts["river"] = "res://build102/004_river_102.gd"
    scripts["lake"] = "res://build102/005_lake_102.gd"
    scripts["mountain"] = "res://build102/006_mountain_102.gd"
    scripts["forest"] = "res://build102/007_forest_102.gd"
    scripts["desert"] = "res://build102/008_desert_102.gd"
    scripts["road"] = "res://build102/009_road_102.gd"
    scripts["bridge"] = "res://build102/010_bridge_102.gd"
    scripts["passage"] = "res://build102/011_passage_102.gd"
    scripts["region"] = "res://build102/012_region_102.gd"
    scripts["province"] = "res://build102/013_province_102.gd"
    scripts["frontier"] = "res://build102/014_frontier_102.gd"
    scripts["fog"] = "res://build102/015_fog_102.gd"
    scripts["discovery"] = "res://build102/016_discovery_102.gd"
    scripts["waypoint"] = "res://build102/017_waypoint_102.gd"
    scripts["landmark"] = "res://build102/018_landmark_102.gd"
    scripts["spawn"] = "res://build102/019_spawn_102.gd"
    scripts["world_event"] = "res://build102/020_world_event_102.gd"
    scripts["season"] = "res://build102/021_season_102.gd"
    scripts["weather"] = "res://build102/022_weather_102.gd"
    scripts["temperature"] = "res://build102/023_temperature_102.gd"
    scripts["daylight"] = "res://build102/024_daylight_102.gd"
    scripts["visibility"] = "res://build102/025_visibility_102.gd"
    scripts["travel_cost"] = "res://build102/026_travel_cost_102.gd"
    scripts["tile_claim"] = "res://build102/027_tile_claim_102.gd"
    scripts["tile_reserve"] = "res://build102/028_tile_reserve_102.gd"
    scripts["map_search"] = "res://build102/029_map_search_102.gd"
    scripts["map_bookmark"] = "res://build102/030_map_bookmark_102.gd"
    scripts["map_ping"] = "res://build102/031_map_ping_102.gd"
    scripts["region_reward"] = "res://build102/032_region_reward_102.gd"
    scripts["hazard"] = "res://build102/033_hazard_102.gd"
    scripts["terrain_bonus"] = "res://build102/034_terrain_bonus_102.gd"
    scripts["map_statistics"] = "res://build102/035_map_statistics_102.gd"
    scripts["troop_capacity"] = "res://build102/036_troop_capacity_102.gd"
    scripts["troop_upkeep"] = "res://build102/037_troop_upkeep_102.gd"
    scripts["troop_training"] = "res://build102/038_troop_training_102.gd"
    scripts["troop_upgrade"] = "res://build102/039_troop_upgrade_102.gd"
    scripts["troop_morale"] = "res://build102/040_troop_morale_102.gd"
    scripts["troop_fatigue"] = "res://build102/041_troop_fatigue_102.gd"
    scripts["troop_speed"] = "res://build102/042_troop_speed_102.gd"
    scripts["troop_supply"] = "res://build102/043_troop_supply_102.gd"
    scripts["army_march"] = "res://build102/044_army_march_102.gd"
    scripts["army_route"] = "res://build102/045_army_route_102.gd"
    scripts["army_stance"] = "res://build102/046_army_stance_102.gd"
    scripts["army_merge"] = "res://build102/047_army_merge_102.gd"
    scripts["army_split"] = "res://build102/048_army_split_102.gd"
    scripts["army_scout"] = "res://build102/049_army_scout_102.gd"
    scripts["army_ambush"] = "res://build102/050_army_ambush_102.gd"
    scripts["battle_attack"] = "res://build102/051_battle_attack_102.gd"
    scripts["battle_defense"] = "res://build102/052_battle_defense_102.gd"
    scripts["battle_counter"] = "res://build102/053_battle_counter_102.gd"
    scripts["battle_critical"] = "res://build102/054_battle_critical_102.gd"
    scripts["battle_skill"] = "res://build102/055_battle_skill_102.gd"
    scripts["battle_round"] = "res://build102/056_battle_round_102.gd"
    scripts["battle_retreat"] = "res://build102/057_battle_retreat_102.gd"
    scripts["battle_wounded"] = "res://build102/058_battle_wounded_102.gd"
    scripts["battle_prisoner"] = "res://build102/059_battle_prisoner_102.gd"
    scripts["siege_damage"] = "res://build102/060_siege_damage_102.gd"
    scripts["siege_wall"] = "res://build102/061_siege_wall_102.gd"
    scripts["siege_gate"] = "res://build102/062_siege_gate_102.gd"
    scripts["siege_engine"] = "res://build102/063_siege_engine_102.gd"
    scripts["siege_rally"] = "res://build102/064_siege_rally_102.gd"
    scripts["reinforcement"] = "res://build102/065_reinforcement_102.gd"
    scripts["garrison"] = "res://build102/066_garrison_102.gd"
    scripts["hospital"] = "res://build102/067_hospital_102.gd"
    scripts["healing"] = "res://build102/068_healing_102.gd"
    scripts["battle_report"] = "res://build102/069_battle_report_102.gd"
    scripts["combat_statistics"] = "res://build102/070_combat_statistics_102.gd"
    scripts["loot"] = "res://build102/071_loot_102.gd"
    scripts["loot_protection"] = "res://build102/072_loot_protection_102.gd"
    scripts["peace_shield"] = "res://build102/073_peace_shield_102.gd"
    scripts["occupation"] = "res://build102/074_occupation_102.gd"
    scripts["victory_points"] = "res://build102/075_victory_points_102.gd"
    scripts["alliance_found"] = "res://build102/076_alliance_found_102.gd"
    scripts["alliance_join"] = "res://build102/077_alliance_join_102.gd"
    scripts["alliance_leave"] = "res://build102/078_alliance_leave_102.gd"
    scripts["alliance_rank"] = "res://build102/079_alliance_rank_102.gd"
    scripts["alliance_permission"] = "res://build102/080_alliance_permission_102.gd"
    scripts["alliance_help"] = "res://build102/081_alliance_help_102.gd"
    scripts["alliance_donation"] = "res://build102/082_alliance_donation_102.gd"
    scripts["alliance_treasury"] = "res://build102/083_alliance_treasury_102.gd"
    scripts["alliance_territory"] = "res://build102/084_alliance_territory_102.gd"
    scripts["alliance_flag"] = "res://build102/085_alliance_flag_102.gd"
    scripts["alliance_fort"] = "res://build102/086_alliance_fort_102.gd"
    scripts["alliance_resource"] = "res://build102/087_alliance_resource_102.gd"
    scripts["alliance_quest"] = "res://build102/088_alliance_quest_102.gd"
    scripts["alliance_reward"] = "res://build102/089_alliance_reward_102.gd"
    scripts["alliance_chat_stub"] = "res://build102/090_alliance_chat_stub_102.gd"
    scripts["alliance_mail_stub"] = "res://build102/091_alliance_mail_stub_102.gd"
    scripts["alliance_rally"] = "res://build102/092_alliance_rally_102.gd"
    scripts["alliance_garrison"] = "res://build102/093_alliance_garrison_102.gd"
    scripts["alliance_war"] = "res://build102/094_alliance_war_102.gd"
    scripts["alliance_truce"] = "res://build102/095_alliance_truce_102.gd"
    scripts["alliance_diplomacy"] = "res://build102/096_alliance_diplomacy_102.gd"
    scripts["alliance_relation"] = "res://build102/097_alliance_relation_102.gd"
    scripts["alliance_vote"] = "res://build102/098_alliance_vote_102.gd"
    scripts["alliance_election"] = "res://build102/099_alliance_election_102.gd"
    scripts["alliance_capital"] = "res://build102/100_alliance_capital_102.gd"
    scripts["alliance_throne"] = "res://build102/101_alliance_throne_102.gd"
    scripts["alliance_king"] = "res://build102/102_alliance_king_102.gd"
    scripts["alliance_tax"] = "res://build102/103_alliance_tax_102.gd"
    scripts["alliance_blessing"] = "res://build102/104_alliance_blessing_102.gd"
    scripts["alliance_ranking"] = "res://build102/105_alliance_ranking_102.gd"
    scripts["food_production"] = "res://build102/106_food_production_102.gd"
    scripts["wood_production"] = "res://build102/107_wood_production_102.gd"
    scripts["stone_production"] = "res://build102/108_stone_production_102.gd"
    scripts["gold_production"] = "res://build102/109_gold_production_102.gd"
    scripts["storage"] = "res://build102/110_storage_102.gd"
    scripts["warehouse"] = "res://build102/111_warehouse_102.gd"
    scripts["construction"] = "res://build102/112_construction_102.gd"
    scripts["build_queue"] = "res://build102/113_build_queue_102.gd"
    scripts["construction_speed"] = "res://build102/114_construction_speed_102.gd"
    scripts["building_upgrade"] = "res://build102/115_building_upgrade_102.gd"
    scripts["building_repair"] = "res://build102/116_building_repair_102.gd"
    scripts["city_wall"] = "res://build102/117_city_wall_102.gd"
    scripts["city_happiness"] = "res://build102/118_city_happiness_102.gd"
    scripts["city_security"] = "res://build102/119_city_security_102.gd"
    scripts["city_population"] = "res://build102/120_city_population_102.gd"
    scripts["city_housing"] = "res://build102/121_city_housing_102.gd"
    scripts["city_market"] = "res://build102/122_city_market_102.gd"
    scripts["city_trade"] = "res://build102/123_city_trade_102.gd"
    scripts["caravan"] = "res://build102/124_caravan_102.gd"
    scripts["taxation"] = "res://build102/125_taxation_102.gd"
    scripts["resource_transfer"] = "res://build102/126_resource_transfer_102.gd"
    scripts["resource_protection"] = "res://build102/127_resource_protection_102.gd"
    scripts["research"] = "res://build102/128_research_102.gd"
    scripts["research_queue"] = "res://build102/129_research_queue_102.gd"
    scripts["technology_bonus"] = "res://build102/130_technology_bonus_102.gd"
    scripts["hospital_capacity"] = "res://build102/131_hospital_capacity_102.gd"
    scripts["training_capacity"] = "res://build102/132_training_capacity_102.gd"
    scripts["scouting_cost"] = "res://build102/133_scouting_cost_102.gd"
    scripts["city_power"] = "res://build102/134_city_power_102.gd"
    scripts["economy_report"] = "res://build102/135_economy_report_102.gd"
    scripts["production_boost"] = "res://build102/136_production_boost_102.gd"
    scripts["resource_gathering"] = "res://build102/137_resource_gathering_102.gd"
    scripts["gathering_speed"] = "res://build102/138_gathering_speed_102.gd"
    scripts["city_teleport"] = "res://build102/139_city_teleport_102.gd"
    scripts["city_cooldown"] = "res://build102/140_city_cooldown_102.gd"
    scripts["hero_xp"] = "res://build102/141_hero_xp_102.gd"
    scripts["hero_level"] = "res://build102/142_hero_level_102.gd"
    scripts["hero_star"] = "res://build102/143_hero_star_102.gd"
    scripts["hero_talent"] = "res://build102/144_hero_talent_102.gd"
    scripts["hero_skill"] = "res://build102/145_hero_skill_102.gd"
    scripts["hero_cooldown"] = "res://build102/146_hero_cooldown_102.gd"
    scripts["hero_energy"] = "res://build102/147_hero_energy_102.gd"
    scripts["hero_equipment"] = "res://build102/148_hero_equipment_102.gd"
    scripts["hero_weapon"] = "res://build102/149_hero_weapon_102.gd"
    scripts["hero_armor"] = "res://build102/150_hero_armor_102.gd"
    scripts["hero_accessory"] = "res://build102/151_hero_accessory_102.gd"
    scripts["hero_assignment"] = "res://build102/152_hero_assignment_102.gd"
    scripts["hero_garrison"] = "res://build102/153_hero_garrison_102.gd"
    scripts["hero_march"] = "res://build102/154_hero_march_102.gd"
    scripts["hero_duo"] = "res://build102/155_hero_duo_102.gd"
    scripts["hero_synergy"] = "res://build102/156_hero_synergy_102.gd"
    scripts["hero_civilization"] = "res://build102/157_hero_civilization_102.gd"
    scripts["civilization_bonus"] = "res://build102/158_civilization_bonus_102.gd"
    scripts["civilization_choice"] = "res://build102/159_civilization_choice_102.gd"
    scripts["civilization_change"] = "res://build102/160_civilization_change_102.gd"
    scripts["civilization_tech"] = "res://build102/161_civilization_tech_102.gd"
    scripts["civilization_troop"] = "res://build102/162_civilization_troop_102.gd"
    scripts["civilization_city"] = "res://build102/163_civilization_city_102.gd"
    scripts["hero_recruit"] = "res://build102/164_hero_recruit_102.gd"
    scripts["hero_shards"] = "res://build102/165_hero_shards_102.gd"
    scripts["npc_spawn"] = "res://build102/166_npc_spawn_102.gd"
    scripts["npc_schedule"] = "res://build102/167_npc_schedule_102.gd"
    scripts["npc_mood"] = "res://build102/168_npc_mood_102.gd"
    scripts["npc_dialogue"] = "res://build102/169_npc_dialogue_102.gd"
    scripts["npc_request"] = "res://build102/170_npc_request_102.gd"
    scripts["npc_reward"] = "res://build102/171_npc_reward_102.gd"
    scripts["npc_reputation"] = "res://build102/172_npc_reputation_102.gd"
    scripts["npc_safety"] = "res://build102/173_npc_safety_102.gd"
    scripts["npc_prosperity"] = "res://build102/174_npc_prosperity_102.gd"
    scripts["npc_market"] = "res://build102/175_npc_market_102.gd"
    scripts["citizen_population"] = "res://build102/176_citizen_population_102.gd"
    scripts["citizen_happiness"] = "res://build102/177_citizen_happiness_102.gd"
    scripts["citizen_job"] = "res://build102/178_citizen_job_102.gd"
    scripts["citizen_event"] = "res://build102/179_citizen_event_102.gd"
    scripts["quest_create"] = "res://build102/180_quest_create_102.gd"
    scripts["quest_progress"] = "res://build102/181_quest_progress_102.gd"
    scripts["quest_complete"] = "res://build102/182_quest_complete_102.gd"
    scripts["daily_quest"] = "res://build102/183_daily_quest_102.gd"
    scripts["weekly_quest"] = "res://build102/184_weekly_quest_102.gd"
    scripts["achievement"] = "res://build102/185_achievement_102.gd"
    scripts["quality_level"] = "res://build102/186_quality_level_102.gd"
    scripts["fps_budget"] = "res://build102/187_fps_budget_102.gd"
    scripts["object_budget"] = "res://build102/188_object_budget_102.gd"
    scripts["chunk_budget"] = "res://build102/189_chunk_budget_102.gd"
    scripts["texture_budget"] = "res://build102/190_texture_budget_102.gd"
    scripts["lod_distance"] = "res://build102/191_lod_distance_102.gd"
    scripts["ui_scale"] = "res://build102/192_ui_scale_102.gd"
    scripts["touch_sensitivity"] = "res://build102/193_touch_sensitivity_102.gd"
    scripts["camera_speed"] = "res://build102/194_camera_speed_102.gd"
    scripts["camera_zoom"] = "res://build102/195_camera_zoom_102.gd"
    scripts["camera_pan"] = "res://build102/196_camera_pan_102.gd"
    scripts["notification"] = "res://build102/197_notification_102.gd"
    scripts["notification_filter"] = "res://build102/198_notification_filter_102.gd"
    scripts["save_snapshot"] = "res://build102/199_save_snapshot_102.gd"
    scripts["save_checksum"] = "res://build102/200_save_checksum_102.gd"

func execute(rule_id: String, payload: Dictionary = {}) -> Dictionary:
    if not scripts.has(rule_id):
        return {"ok": false, "error": "unknown_rule", "rule": rule_id}
    if not instances.has(rule_id):
        var script: Script = load(str(scripts[rule_id])) as Script
        if script == null:
            return {"ok": false, "error": "missing_script", "rule": rule_id}
        instances[rule_id] = script.new()
    var instance: RefCounted = instances[rule_id]
    var result: Dictionary = instance.execute(state, payload)
    rule_executed.emit(rule_id, result)
    return result

func get_rule_count() -> int:
    return scripts.size()

func save_state() -> bool:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(state))
    file.close()
    return true

func load_state() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return false
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if parsed is Dictionary:
        state = parsed
        return true
    return false

func _exit_tree() -> void:
    save_state()
