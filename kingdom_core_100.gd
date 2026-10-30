
extends Node

# RISE OF CONQUEST - BUILD 100
# KINGDOM CORE
# Godot 4.4.1

signal kingdom_initialized
signal city_registered(city_id: String)
signal resource_changed(resource_name: String)
signal army_registered(army_id: String)

const KINGDOM_WIDTH := 1200
const KINGDOM_HEIGHT := 1200
const KINGDOM_ID := 1001

const SAVE_PATH := "user://kingdom_100.json"

const CIVILIZATIONS := [
    "Osmanlı",
    "Roma",
    "Viking",
    "Moğol",
    "Çin",
    "Arabistan",
    "Alamut"
]

const RESOURCE_TYPES := [
    "food",
    "wood",
    "stone",
    "gold",
    "gems"
]

const TROOP_TYPES := [
    "infantry",
    "cavalry",
    "archer",
    "siege",
    "assassin"
]

var player_id := "player_001"
var player_name := "Hukumdar"
var civilization := "Osmanlı"

var kingdom_seed := 100100
var kingdom_day := 1

var cities: Dictionary = {}
var armies: Dictionary = {}
var resource_nodes: Dictionary = {}
var alliances: Dictionary = {}
var landmarks: Dictionary = {}

var resources := {
    "food": 5000,
    "wood": 5000,
    "stone": 3000,
    "gold": 3000,
    "gems": 0
}

var next_city_id := 1
var next_army_id := 1
var next_resource_id := 1

var initialized := false


func _ready() -> void:
    if not load_kingdom():
        create_new_kingdom()

    initialized = true
    kingdom_initialized.emit()


func create_new_kingdom() -> void:
    cities.clear()
    armies.clear()
    resource_nodes.clear()
    alliances.clear()
    landmarks.clear()

    resources = {
        "food": 5000,
        "wood": 5000,
        "stone": 3000,
        "gold": 3000,
        "gems": 0
    }

    next_city_id = 1
    next_army_id = 1
    next_resource_id = 1

    register_city(
        player_id,
        player_name,
        civilization,
        Vector2i(600, 600)
    )

    save_kingdom()


func is_valid_coordinate(
    coordinate: Vector2i
) -> bool:
    return (
        coordinate.x >= 0
        and coordinate.y >= 0
        and coordinate.x < KINGDOM_WIDTH
        and coordinate.y < KINGDOM_HEIGHT
    )


func register_city(
    owner_id: String,
    city_name: String,
    civ: String,
    coordinate: Vector2i
) -> String:
    if not is_valid_coordinate(coordinate):
        return ""

    if is_coordinate_occupied(coordinate):
        return ""

    var city_id := "city_%06d" % next_city_id
    next_city_id += 1

    cities[city_id] = {
        "id": city_id,
        "owner_id": owner_id,
        "name": city_name,
        "civilization": civ,
        "x": coordinate.x,
        "y": coordinate.y,
        "level": 1,
        "power": 1000,
        "wall_hp": 10000,
        "wall_max_hp": 10000,
        "alliance_id": "",
        "shield_until": 0
    }

    city_registered.emit(city_id)
    return city_id


func is_coordinate_occupied(
    coordinate: Vector2i
) -> bool:
    for city in cities.values():
        if (
            int(city.get("x", -1)) == coordinate.x
            and int(city.get("y", -1)) == coordinate.y
        ):
            return true

    for landmark in landmarks.values():
        if (
            int(landmark.get("x", -1)) == coordinate.x
            and int(landmark.get("y", -1)) == coordinate.y
        ):
            return true

    return false


func relocate_city(
    city_id: String,
    coordinate: Vector2i
) -> bool:
    if not cities.has(city_id):
        return false

    if not is_valid_coordinate(coordinate):
        return false

    if is_coordinate_occupied(coordinate):
        return false

    cities[city_id]["x"] = coordinate.x
    cities[city_id]["y"] = coordinate.y

    save_kingdom()
    return true


func get_city_coordinate(
    city_id: String
) -> Vector2i:
    if not cities.has(city_id):
        return Vector2i(-1, -1)

    var city: Dictionary = cities[city_id]

    return Vector2i(
        int(city.get("x", -1)),
        int(city.get("y", -1))
    )


func register_resource_node(
    kind: String,
    level: int,
    coordinate: Vector2i,
    amount: int
) -> String:
    if kind not in RESOURCE_TYPES:
        return ""

    if not is_valid_coordinate(coordinate):
        return ""

    var resource_id := (
        "resource_%06d" % next_resource_id
    )
    next_resource_id += 1

    resource_nodes[resource_id] = {
        "id": resource_id,
        "kind": kind,
        "level": clampi(level, 1, 10),
        "x": coordinate.x,
        "y": coordinate.y,
        "amount": maxi(amount, 0),
        "occupied_by": ""
    }

    return resource_id


func register_army(
    owner_id: String,
    coordinate: Vector2i,
    troops: Dictionary,
    commander_id: String = ""
) -> String:
    if not is_valid_coordinate(coordinate):
        return ""

    var army_id := "army_%06d" % next_army_id
    next_army_id += 1

    armies[army_id] = {
        "id": army_id,
        "owner_id": owner_id,
        "x": coordinate.x,
        "y": coordinate.y,
        "target_x": coordinate.x,
        "target_y": coordinate.y,
        "troops": troops.duplicate(true),
        "commander_id": commander_id,
        "state": "idle",
        "speed": 1.0
    }

    army_registered.emit(army_id)
    return army_id


func set_army_destination(
    army_id: String,
    destination: Vector2i
) -> bool:
    if not armies.has(army_id):
        return false

    if not is_valid_coordinate(destination):
        return false

    armies[army_id]["target_x"] = destination.x
    armies[army_id]["target_y"] = destination.y
    armies[army_id]["state"] = "marching"

    return true


func get_distance(
    from_coord: Vector2i,
    to_coord: Vector2i
) -> float:
    return Vector2(from_coord).distance_to(
        Vector2(to_coord)
    )


func add_resource(
    resource_name: String,
    amount: int
) -> void:
    if not resources.has(resource_name):
        return

    resources[resource_name] = maxi(
        0,
        int(resources[resource_name]) + amount
    )

    resource_changed.emit(resource_name)


func can_afford(cost: Dictionary) -> bool:
    for key in cost.keys():
        if not resources.has(key):
            return false

        if int(resources[key]) < int(cost[key]):
            return false

    return true


func spend_resources(
    cost: Dictionary
) -> bool:
    if not can_afford(cost):
        return false

    for key in cost.keys():
        add_resource(
            str(key),
            -int(cost[key])
        )

    return true


func get_player_cities() -> Array:
    var result: Array = []

    for city in cities.values():
        if str(city.get("owner_id", "")) == player_id:
            result.append(city)

    return result


func get_kingdom_statistics() -> Dictionary:
    return {
        "kingdom_id": KINGDOM_ID,
        "width": KINGDOM_WIDTH,
        "height": KINGDOM_HEIGHT,
        "cities": cities.size(),
        "armies": armies.size(),
        "resource_nodes": resource_nodes.size(),
        "alliances": alliances.size(),
        "landmarks": landmarks.size(),
        "day": kingdom_day
    }


func save_kingdom() -> bool:
    var data := {
        "version": 100,
        "player_id": player_id,
        "player_name": player_name,
        "civilization": civilization,
        "kingdom_day": kingdom_day,
        "cities": cities,
        "armies": armies,
        "resource_nodes": resource_nodes,
        "alliances": alliances,
        "landmarks": landmarks,
        "resources": resources,
        "next_city_id": next_city_id,
        "next_army_id": next_army_id,
        "next_resource_id": next_resource_id
    }

    var file := FileAccess.open(
        SAVE_PATH,
        FileAccess.WRITE
    )

    if file == null:
        push_error("Kingdom save failed.")
        return false

    file.store_string(
        JSON.stringify(data, "\t")
    )
    file.close()

    return true


func load_kingdom() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false

    var file := FileAccess.open(
        SAVE_PATH,
        FileAccess.READ
    )

    if file == null:
        return false

    var parsed: Variant = JSON.parse_string(
        file.get_as_text()
    )
    file.close()

    if not (parsed is Dictionary):
        return false

    var data: Dictionary = parsed

    if int(data.get("version", 0)) != 100:
        return false

    player_id = str(
        data.get("player_id", player_id)
    )
    player_name = str(
        data.get("player_name", player_name)
    )
    civilization = str(
        data.get("civilization", civilization)
    )

    kingdom_day = int(
        data.get("kingdom_day", 1)
    )

    cities = data.get("cities", {})
    armies = data.get("armies", {})
    resource_nodes = data.get(
        "resource_nodes", {}
    )
    alliances = data.get("alliances", {})
    landmarks = data.get("landmarks", {})
    resources = data.get(
        "resources", resources
    )

    next_city_id = int(
        data.get("next_city_id", 1)
    )
    next_army_id = int(
        data.get("next_army_id", 1)
    )
    next_resource_id = int(
        data.get("next_resource_id", 1)
    )

    return true
