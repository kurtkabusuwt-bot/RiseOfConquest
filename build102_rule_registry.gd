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
    scripts["terrain_height"] = "res://001_terrain_height_102.gd"
    scripts["biome"] = "res://002_biome_102.gd"
    scripts["climate"] = "res://003_climate_102.gd"
    scripts["river"] = "res://004_river_102.gd"
    scripts["lake"] = "res://005_lake_102.gd"
    scripts["mountain"] = "res://006_mountain_102.gd"
    scripts["forest"] = "res://007_forest_102.gd"
    scripts["desert"] = "res://008_desert_102.gd"
    scripts["road"] = "res://009_road_102.gd"
    scripts["bridge"] = "res://010_bridge_102.gd"
    scripts["passage"] = "res://011_passage_102.gd"
    scripts["region"] = "res://012_region_102.gd"
    scripts["province"] = "res://013_province_102.gd"
    scripts["frontier"] = "res://014_frontier_102.gd"
    scripts["fog"] = "res://015_fog_102.gd"
    scripts["discovery"] = "res://016_discovery_102.gd"
    scripts["waypoint"] = "res://017_waypoint_102.gd"
    scripts["landmark"] = "res://018_landmark_102.gd"
    scripts["spawn"] = "res://019_spawn_102.gd"
    scripts["world_event"] = "res://020_world_event_102.gd"
    scripts["season"] = "res://021_season_102.gd"
    scripts["weather"] = "res://022_weather_102.gd"
    scripts["temperature"] = "res://023_temperature_102.gd"
    scripts["daylight"] = "res://024_daylight_102.gd"
    scripts["visibility"] = "res://025_visibility_102.gd"
    scripts["travel_cost"] = "res://026_travel_cost_102.gd"
    scripts["tile_claim"] = "res://027_tile_claim_102.gd"
    scripts["tile_reserve"] = "res://028_tile_reserve_102.gd"
    scripts["map_search"] = "res://029_map_search_102.gd"
    scripts["map_bookmark"] = "res://030_map_bookmark_102.gd"
    scripts["map_ping"] = "res://031_map_ping_102.gd"
    scripts["region_reward"] = "res://032_region_reward_102.gd"
    scripts["hazard"] = "res://033_hazard_102.gd"
    scripts["terrain_bonus"] = "res://034_terrain_bonus_102.gd"
    scripts["map_statistics"] = "res://035_map_statistics_102.gd"
    scripts["troop_capacity"] = "res://036_troop_capacity_102.gd"
    scripts["troop_upkeep"] = "res://037_troop_upkeep_102.gd"
    scripts["troop_training"] = "res://038_troop_training_102.gd"
    scripts["troop_upgrade"] = "res://039_troop_upgrade_102.gd"
    scripts["troop_morale"] = "res://040_troop_morale_102.gd"
    scripts["troop_fatigue"] = "res://041_troop_fatigue_102.gd"
    scripts["troop_speed"] = "res://042_troop_speed_102.gd"
    scripts["troop_supply"] = "res://043_troop_supply_102.gd"
    scripts["army_march"] = "res://044_army_march_102.gd"
    scripts["army_route"] = "res://045_army_route_102.gd"
    scripts["army_stance"] = "res://046_army_stance_102.gd"
    scripts["army_merge"] = "res://047_army_merge_102.gd"
    scripts["army_split"] = "res://048_army_split_102.gd"
    scripts["army_scout"] = "res://049_army_scout_102.gd"
    scripts["army_ambush"] = "res://050_army_ambush_102.gd"
    scripts["battle_attack"] = "res://051_battle_attack_102.gd"
    scripts["battle_defense"] = "res://052_battle_defense_102.gd"
    scripts["battle_counter"] = "res://053_battle_counter_102.gd"
    scripts["battle_critical"] = "res://054_battle_critical_102.gd"
    scripts["battle_skill"] = "res://055_battle_skill_102.gd"
    scripts["battle_round"] = "res://056_battle_round_102.gd"
    scripts["battle_retreat"] = "res://057_battle_retreat_102.gd"
    scripts["battle_wounded"] = "res://058_battle_wounded_102.gd"
    scripts["battle_prisoner"] = "res://059_battle_prisoner_102.gd"
    scripts["siege_damage"] = "res://060_siege_damage_102.gd"
    scripts["siege_wall"] = "res://061_siege_wall_102.gd"
    scripts["siege_gate"] = "res://062_siege_gate_102.gd"
    scripts["siege_engine"] = "res://063_siege_engine_102.gd"
    scripts["siege_rally"] = "res://064_siege_rally_102.gd"
    scripts["reinforcement"] = "res://065_reinforcement_102.gd"
    scripts["garrison"] = "res://066_garrison_102.gd"
    scripts["hospital"] = "res://067_hospital_102.gd"
    scripts["healing"] = "res://068_healing_102.gd"
    scripts["battle_report"] = "res://069_battle_report_102.gd"
    scripts["combat_statistics"] = "res://070_combat_statistics_102.gd"
    scripts["loot"] = "res://071_loot_102.gd"
    scripts["loot_protection"] = "res://072_loot_protection_102.gd"
    scripts["peace_shield"] = "res://073_peace_shield_102.gd"
    scripts["occupation"] = "res://074_occupation_102.gd"
    scripts["victory_points"] = "res://075_victory_points_102.gd"
    scripts["alliance_found"] = "res://076_alliance_found_102.gd"
    scripts["alliance_join"] = "res://077_alliance_join_102.gd"
    scripts["alliance_leave"] = "res://078_alliance_leave_102.gd"
    scripts["alliance_rank"] = "res://079_alliance_rank_102.gd"
    scripts["alliance_permission"] = "res://080_alliance_permission_102.gd"
    scripts["alliance_help"] = "res://081_alliance_help_102.gd"
    scripts["alliance_donation"] = "res://082_alliance_donation_102.gd"
    scripts["alliance_treasury"] = "res://083_alliance_treasury_102.gd"
    scripts["alliance_territory"] = "res://084_alliance_territory_102.gd"
    scripts["alliance_flag"] = "res://085_alliance_flag_102.gd"
    scripts["alliance_fort"] = "res://086_alliance_fort_102.gd"
    scripts["alliance_resource"] = "res://087_alliance_resource_102.gd"
    scripts["alliance_quest"] = "res://088_alliance_quest_102.gd"
    scripts["alliance_reward"] = "res://089_alliance_reward_102.gd"
    scripts["alliance_chat_stub"] = "res://090_alliance_chat_stub_102.gd"
    scripts["alliance_mail_stub"] = "res://091_alliance_mail_stub_102.gd"
    scripts["alliance_rally"] = "res://092_alliance_rally_102.gd"
    scripts["alliance_garrison"] = "res://093_alliance_garrison_102.gd"
    scripts["alliance_war"] = "res://094_alliance_war_102.gd"
    scripts["alliance_truce"] = "res://095_alliance_truce_102.gd"
    scripts["alliance_diplomacy"] = "res://096_alliance_diplomacy_102.gd"
    scripts["alliance_relation"] = "res://097_alliance_relation_102.gd"
    scripts["alliance_vote"] = "res://098_alliance_vote_102.gd"
    scripts["alliance_election"] = "res://099_alliance_election_102.gd"
    scripts["alliance_capital"] = "res://100_alliance_capital_102.gd"
    scripts["alliance_throne"] = "res://101_alliance_throne_102.gd"
    scripts["alliance_king"] = "res://102_alliance_king_102.gd"
    scripts["alliance_tax"] = "res://103_alliance_tax_102.gd"
    scripts["alliance_blessing"] = "res://104_alliance_blessing_102.gd"
    scripts["alliance_ranking"] = "res://105_alliance_ranking_102.gd"
    scripts["food_production"] = "res://106_food_production_102.gd"
    scripts["wood_production"] = "res://107_wood_production_102.gd"
    scripts["stone_production"] = "res://108_stone_production_102.gd"
    scripts["gold_production"] = "res://109_gold_production_102.gd"
    scripts["storage"] = "res://110_storage_102.gd"
    scripts["warehouse"] = "res://111_warehouse_102.gd"
    scripts["construction"] = "res://112_construction_102.gd"
    scripts["build_queue"] = "res://113_build_queue_102.gd"
    scripts["construction_speed"] = "res://114_construction_speed_102.gd"
    scripts["building_upgrade"] = "res://115_building_upgrade_102.gd"
    scripts["building_repair"] = "res://116_building_repair_102.gd"
    scripts["city_wall"] = "res://117_city_wall_102.gd"
    scripts["city_happiness"] = "res://118_city_happiness_102.gd"
    scripts["city_security"] = "res://119_city_security_102.gd"
    scripts["city_population"] = "res://120_city_population_102.gd"
    scripts["city_housing"] = "res://121_city_housing_102.gd"
    scripts["city_market"] = "res://122_city_market_102.gd"
    scripts["city_trade"] = "res://123_city_trade_102.gd"
    scripts["caravan"] = "res://124_caravan_102.gd"
    scripts["taxation"] = "res://125_taxation_102.gd"
    scripts["resource_transfer"] = "res://126_resource_transfer_102.gd"
    scripts["resource_protection"] = "res://127_resource_protection_102.gd"
    scripts["research"] = "res://128_research_102.gd"
    scripts["research_queue"] = "res://129_research_queue_102.gd"
    scripts["technology_bonus"] = "res://130_technology_bonus_102.gd"
    scripts["hospital_capacity"] = "res://131_hospital_capacity_102.gd"
    scripts["training_capacity"] = "res://132_training_capacity_102.gd"
    scripts["scouting_cost"] = "res://133_scouting_cost_102.gd"
    scripts["city_power"] = "res://134_city_power_102.gd"
    scripts["economy_report"] = "res://135_economy_report_102.gd"
    scripts["production_boost"] = "res://136_production_boost_102.gd"
    scripts["resource_gathering"] = "res://137_resource_gathering_102.gd"
    scripts["gathering_speed"] = "res://138_gathering_speed_102.gd"
    scripts["city_teleport"] = "res://139_city_teleport_102.gd"
    scripts["city_cooldown"] = "res://140_city_cooldown_102.gd"
    scripts["hero_xp"] = "res://141_hero_xp_102.gd"
    scripts["hero_level"] = "res://142_hero_level_102.gd"
    scripts["hero_star"] = "res://143_hero_star_102.gd"
    scripts["hero_talent"] = "res://144_hero_talent_102.gd"
    scripts["hero_skill"] = "res://145_hero_skill_102.gd"
    scripts["hero_cooldown"] = "res://146_hero_cooldown_102.gd"
    scripts["hero_energy"] = "res://147_hero_energy_102.gd"
    scripts["hero_equipment"] = "res://148_hero_equipment_102.gd"
    scripts["hero_weapon"] = "res://149_hero_weapon_102.gd"
    scripts["hero_armor"] = "res://150_hero_armor_102.gd"
    scripts["hero_accessory"] = "res://151_hero_accessory_102.gd"
    scripts["hero_assignment"] = "res://152_hero_assignment_102.gd"
    scripts["hero_garrison"] = "res://153_hero_garrison_102.gd"
    scripts["hero_march"] = "res://154_hero_march_102.gd"
    scripts["hero_duo"] = "res://155_hero_duo_102.gd"
    scripts["hero_synergy"] = "res://156_hero_synergy_102.gd"
    scripts["hero_civilization"] = "res://157_hero_civilization_102.gd"
    scripts["civilization_bonus"] = "res://158_civilization_bonus_102.gd"
    scripts["civilization_choice"] = "res://159_civilization_choice_102.gd"
    scripts["civilization_change"] = "res://160_civilization_change_102.gd"
    scripts["civilization_tech"] = "res://161_civilization_tech_102.gd"
    scripts["civilization_troop"] = "res://162_civilization_troop_102.gd"
    scripts["civilization_city"] = "res://163_civilization_city_102.gd"
    scripts["hero_recruit"] = "res://164_hero_recruit_102.gd"
    scripts["hero_shards"] = "res://165_hero_shards_102.gd"
    scripts["npc_spawn"] = "res://166_npc_spawn_102.gd"
    scripts["npc_schedule"] = "res://167_npc_schedule_102.gd"
    scripts["npc_mood"] = "res://168_npc_mood_102.gd"
    scripts["npc_dialogue"] = "res://169_npc_dialogue_102.gd"
    scripts["npc_request"] = "res://170_npc_request_102.gd"
    scripts["npc_reward"] = "res://171_npc_reward_102.gd"
    scripts["npc_reputation"] = "res://172_npc_reputation_102.gd"
    scripts["npc_safety"] = "res://173_npc_safety_102.gd"
    scripts["npc_prosperity"] = "res://174_npc_prosperity_102.gd"
    scripts["npc_market"] = "res://175_npc_market_102.gd"
    scripts["citizen_population"] = "res://176_citizen_population_102.gd"
    scripts["citizen_happiness"] = "res://177_citizen_happiness_102.gd"
    scripts["citizen_job"] = "res://178_citizen_job_102.gd"
    scripts["citizen_event"] = "res://179_citizen_event_102.gd"
    scripts["quest_create"] = "res://180_quest_create_102.gd"
    scripts["quest_progress"] = "res://181_quest_progress_102.gd"
    scripts["quest_complete"] = "res://182_quest_complete_102.gd"
    scripts["daily_quest"] = "res://183_daily_quest_102.gd"
    scripts["weekly_quest"] = "res://184_weekly_quest_102.gd"
    scripts["achievement"] = "res://185_achievement_102.gd"
    scripts["quality_level"] = "res://186_quality_level_102.gd"
    scripts["fps_budget"] = "res://187_fps_budget_102.gd"
    scripts["object_budget"] = "res://188_object_budget_102.gd"
    scripts["chunk_budget"] = "res://189_chunk_budget_102.gd"
    scripts["texture_budget"] = "res://190_texture_budget_102.gd"
    scripts["lod_distance"] = "res://191_lod_distance_102.gd"
    scripts["ui_scale"] = "res://192_ui_scale_102.gd"
    scripts["touch_sensitivity"] = "res://193_touch_sensitivity_102.gd"
    scripts["camera_speed"] = "res://194_camera_speed_102.gd"
    scripts["camera_zoom"] = "res://195_camera_zoom_102.gd"
    scripts["camera_pan"] = "res://196_camera_pan_102.gd"
    scripts["notification"] = "res://197_notification_102.gd"
    scripts["notification_filter"] = "res://198_notification_filter_102.gd"
    scripts["save_snapshot"] = "res://199_save_snapshot_102.gd"
    scripts["save_checksum"] = "res://200_save_checksum_102.gd"

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
