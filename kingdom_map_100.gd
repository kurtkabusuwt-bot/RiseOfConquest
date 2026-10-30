
extends Node3D

# ============================================================
# RISE OF CONQUEST - BUILD 100
# MODULE 02 / 50
# KINGDOM MAP ENGINE
# Godot 4.4.1 / Android
#
# - Procedural terrain
# - Deterministic world generation
# - Mountain regions
# - Forest regions
# - Rivers and lakes
# - Desert and plains
# - Regional zones
# - Chunk streaming
# - Mobile quality settings
# - World coordinate conversion
# ============================================================

signal chunk_loaded(chunk_position: Vector2i)
signal chunk_unloaded(chunk_position: Vector2i)
signal map_center_changed(center: Vector2i)

const WORLD_WIDTH := 1200
const WORLD_HEIGHT := 1200

const CHUNK_SIZE := 16
const TILE_SIZE := 2.0

const MAX_ELEVATION := 5.0
const WATER_LEVEL := 0.0

const TERRAIN_PLAINS := 0
const TERRAIN_FOREST := 1
const TERRAIN_MOUNTAIN := 2
const TERRAIN_DESERT := 3
const TERRAIN_WATER := 4
const TERRAIN_HILLS := 5

const TERRAIN_COLORS := {
    TERRAIN_PLAINS: Color(0.36, 0.49, 0.27),
    TERRAIN_FOREST: Color(0.14, 0.31, 0.17),
    TERRAIN_MOUNTAIN: Color(0.43, 0.42, 0.39),
    TERRAIN_DESERT: Color(0.67, 0.57, 0.36),
    TERRAIN_WATER: Color(0.12, 0.29, 0.49),
    TERRAIN_HILLS: Color(0.40, 0.43, 0.29)
}

@export_range(0, 2) var quality_level := 1
@export_range(1, 4) var visible_chunk_radius := 2
@export var enable_streaming := true
@export var enable_decorations := true
@export var kingdom_seed := 100100

var terrain_noise := FastNoiseLite.new()
var moisture_noise := FastNoiseLite.new()
var temperature_noise := FastNoiseLite.new()

var chunks: Dictionary = {}
var terrain_cache: Dictionary = {}

var map_center := Vector2i(600, 600)
var previous_chunk_center := Vector2i(-1, -1)

var chunk_queue: Array[Vector2i] = []

var terrain_root: Node3D

var initialized := false
var total_generated_chunks := 0
var total_generated_tiles := 0

var material_cache: Dictionary = {}


func _ready() -> void:
    _configure_noise()
    _create_root()

    initialized = true

    if enable_streaming:
        update_visible_chunks()


# ============================================================
# NOISE GENERATION
# ============================================================

func _configure_noise() -> void:
    terrain_noise.seed = kingdom_seed
    terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    terrain_noise.frequency = 0.008
    terrain_noise.fractal_octaves = 4

    moisture_noise.seed = kingdom_seed + 200
    moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    moisture_noise.frequency = 0.012

    temperature_noise.seed = kingdom_seed + 400
    temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    temperature_noise.frequency = 0.006


func _create_root() -> void:
    terrain_root = Node3D.new()
    terrain_root.name = "KingdomTerrain"
    add_child(terrain_root)

    for terrain_type in TERRAIN_COLORS.keys():
        var material := StandardMaterial3D.new()
        material.albedo_color = TERRAIN_COLORS[terrain_type]
        material.roughness = 0.95

        material_cache[terrain_type] = material


# ============================================================
# TERRAIN DATA
# ============================================================

func get_terrain_data(
    coordinate: Vector2i
) -> Dictionary:
    if not is_valid_coordinate(coordinate):
        return {}

    if terrain_cache.has(coordinate):
        return terrain_cache[coordinate]

    var x := float(coordinate.x)
    var y := float(coordinate.y)

    var elevation_noise := terrain_noise.get_noise_2d(
        x, y
    )

    var moisture := moisture_noise.get_noise_2d(
        x, y
    )

    var temperature := temperature_noise.get_noise_2d(
        x, y
    )

    var elevation := (
        elevation_noise * 0.5 + 0.5
    )

    var terrain_type := TERRAIN_PLAINS

    if elevation < 0.32:
        terrain_type = TERRAIN_WATER

    elif elevation > 0.78:
        terrain_type = TERRAIN_MOUNTAIN

    elif elevation > 0.65:
        terrain_type = TERRAIN_HILLS

    elif moisture > 0.20:
        terrain_type = TERRAIN_FOREST

    elif moisture < -0.30 and temperature > 0.0:
        terrain_type = TERRAIN_DESERT

    var height := elevation * MAX_ELEVATION

    if terrain_type == TERRAIN_WATER:
        height = WATER_LEVEL

    var data := {
        "coordinate": coordinate,
        "type": terrain_type,
        "elevation": elevation,
        "height": height,
        "moisture": moisture,
        "temperature": temperature,
        "walkable": terrain_type != TERRAIN_WATER
            and terrain_type != TERRAIN_MOUNTAIN,
        "buildable": terrain_type == TERRAIN_PLAINS
            or terrain_type == TERRAIN_HILLS
    }

    terrain_cache[coordinate] = data

    return data


func is_valid_coordinate(
    coordinate: Vector2i
) -> bool:
    return (
        coordinate.x >= 0
        and coordinate.y >= 0
        and coordinate.x < WORLD_WIDTH
        and coordinate.y < WORLD_HEIGHT
    )


func is_walkable(
    coordinate: Vector2i
) -> bool:
    var data := get_terrain_data(coordinate)

    if data.is_empty():
        return false

    return bool(data.get("walkable", false))


func is_buildable(
    coordinate: Vector2i
) -> bool:
    var data := get_terrain_data(coordinate)

    if data.is_empty():
        return false

    return bool(data.get("buildable", false))


# ============================================================
# REGIONS
# ============================================================

func get_region_id(
    coordinate: Vector2i
) -> int:
    if not is_valid_coordinate(coordinate):
        return -1

    var region_x := coordinate.x / 100
    var region_y := coordinate.y / 100

    return region_y * 12 + region_x


func get_region_name(
    coordinate: Vector2i
) -> String:
    var region_id := get_region_id(coordinate)

    if region_id < 0:
        return "Bilinmeyen Bolge"

    return "Bolge %03d" % (region_id + 1)


func get_region_center(
    region_id: int
) -> Vector2i:
    if region_id < 0 or region_id >= 144:
        return Vector2i(-1, -1)

    var region_x := region_id % 12
    var region_y := region_id / 12

    return Vector2i(
        region_x * 100 + 50,
        region_y * 100 + 50
    )


# ============================================================
# COORDINATE CONVERSION
# ============================================================

func coordinate_to_world(
    coordinate: Vector2i
) -> Vector3:
    var data := get_terrain_data(coordinate)

    var height := float(
        data.get("height", 0.0)
    )

    return Vector3(
        float(coordinate.x - map_center.x) * TILE_SIZE,
        height,
        float(coordinate.y - map_center.y) * TILE_SIZE
    )


func world_to_coordinate(
    position: Vector3
) -> Vector2i:
    return Vector2i(
        roundi(position.x / TILE_SIZE)
            + map_center.x,
        roundi(position.z / TILE_SIZE)
            + map_center.y
    )


# ============================================================
# CHUNK MANAGEMENT
# ============================================================

func coordinate_to_chunk(
    coordinate: Vector2i
) -> Vector2i:
    return Vector2i(
        coordinate.x / CHUNK_SIZE,
        coordinate.y / CHUNK_SIZE
    )


func update_visible_chunks() -> void:
    if not initialized:
        return

    var current_chunk := coordinate_to_chunk(
        map_center
    )

    if current_chunk == previous_chunk_center:
        return

    previous_chunk_center = current_chunk

    var required: Dictionary = {}

    for offset_y in range(
        -visible_chunk_radius,
        visible_chunk_radius + 1
    ):
        for offset_x in range(
            -visible_chunk_radius,
            visible_chunk_radius + 1
        ):
            var chunk := current_chunk + Vector2i(
                offset_x, offset_y
            )

            if not _valid_chunk(chunk):
                continue

            required[chunk] = true

            if not chunks.has(chunk):
                if not chunk_queue.has(chunk):
                    chunk_queue.append(chunk)

    var old_chunks := chunks.keys()

    for chunk in old_chunks:
        if not required.has(chunk):
            unload_chunk(chunk)

    var filtered_queue: Array[Vector2i] = []

    for chunk in chunk_queue:
        if required.has(chunk):
            filtered_queue.append(chunk)

    chunk_queue = filtered_queue


func _valid_chunk(chunk: Vector2i) -> bool:
    var max_x := (
        WORLD_WIDTH + CHUNK_SIZE - 1
    ) / CHUNK_SIZE

    var max_y := (
        WORLD_HEIGHT + CHUNK_SIZE - 1
    ) / CHUNK_SIZE

    return (
        chunk.x >= 0
        and chunk.y >= 0
        and chunk.x < max_x
        and chunk.y < max_y
    )


func _process(_delta: float) -> void:
    if not initialized:
        return

    var chunks_per_frame := 1

    if quality_level == 0:
        chunks_per_frame = 1
    elif quality_level == 2:
        chunks_per_frame = 2

    for i in range(chunks_per_frame):
        if chunk_queue.is_empty():
            break

        var chunk := chunk_queue.pop_front()

        if not chunks.has(chunk):
            generate_chunk(chunk)


# ============================================================
# CHUNK GENERATION
# ============================================================

func generate_chunk(
    chunk_position: Vector2i
) -> void:
    if chunks.has(chunk_position):
        return

    if not _valid_chunk(chunk_position):
        return

    var chunk_root := Node3D.new()

    chunk_root.name = (
        "Chunk_%d_%d"
        % [chunk_position.x, chunk_position.y]
    )

    terrain_root.add_child(chunk_root)

    var surfaces: Dictionary = {}

    for terrain_type in TERRAIN_COLORS.keys():
        surfaces[terrain_type] = []

    for local_y in range(CHUNK_SIZE):
        for local_x in range(CHUNK_SIZE):
            var coordinate := Vector2i(
                chunk_position.x * CHUNK_SIZE + local_x,
                chunk_position.y * CHUNK_SIZE + local_y
            )

            if not is_valid_coordinate(coordinate):
                continue

            var data := get_terrain_data(coordinate)

            var terrain_type := int(
                data.get("type", TERRAIN_PLAINS)
            )

            var world_position := coordinate_to_world(
                coordinate
            )

            var tile_height := float(
                data.get("height", 0.0)
            )

            var top_height := (
                world_position.y
                if terrain_type != TERRAIN_WATER
                else WATER_LEVEL
            )

            var tile_data := {
                "position": Vector3(
                    world_position.x,
                    top_height,
                    world_position.z
                ),
                "height": tile_height
            }

            surfaces[terrain_type].append(tile_data)
            total_generated_tiles += 1

    for terrain_type in surfaces.keys():
        var tiles: Array = surfaces[terrain_type]

        if tiles.is_empty():
            continue

        _create_terrain_surface(
            chunk_root,
            int(terrain_type),
            tiles
        )

    chunks[chunk_position] = chunk_root
    total_generated_chunks += 1

    chunk_loaded.emit(chunk_position)


func _create_terrain_surface(
    parent: Node3D,
    terrain_type: int,
    tiles: Array
) -> void:
    var mesh := MultiMesh.new()
    mesh.transform_format = MultiMesh.TRANSFORM_3D

    var tile_mesh := BoxMesh.new()
    tile_mesh.size = Vector3(
        TILE_SIZE,
        0.3,
        TILE_SIZE
    )

    mesh.mesh = tile_mesh
    mesh.instance_count = tiles.size()

    for i in range(tiles.size()):
        var tile: Dictionary = tiles[i]
        var position: Vector3 = tile["position"]

        var transform := Transform3D.IDENTITY
        transform.origin = position - Vector3(
            0, 0.15, 0
        )

        mesh.set_instance_transform(i, transform)

    var instance := MultiMeshInstance3D.new()
    instance.multimesh = mesh

    instance.material_override = (
        material_cache[terrain_type]
    )

    parent.add_child(instance)


# ============================================================
# CHUNK UNLOADING
# ============================================================

func unload_chunk(
    chunk_position: Vector2i
) -> void:
    if not chunks.has(chunk_position):
        return

    var chunk: Node3D = chunks[chunk_position]

    chunks.erase(chunk_position)

    if is_instance_valid(chunk):
        chunk.queue_free()

    chunk_unloaded.emit(chunk_position)


func clear_all_chunks() -> void:
    for chunk in chunks.keys():
        unload_chunk(chunk)

    chunk_queue.clear()
    terrain_cache.clear()

    previous_chunk_center = Vector2i(-1, -1)


# ============================================================
# MAP NAVIGATION
# ============================================================

func move_map_center(
    coordinate: Vector2i
) -> void:
    if not is_valid_coordinate(coordinate):
        return

    map_center = coordinate

    # Existing chunks use local coordinates relative
    # to the previous center. Rebuild after recentering.
    clear_all_chunks()

    update_visible_chunks()

    map_center_changed.emit(map_center)


func jump_to_coordinate(
    x: int,
    y: int
) -> bool:
    var target := Vector2i(x, y)

    if not is_valid_coordinate(target):
        return false

    move_map_center(target)
    return true


# ============================================================
# TERRAIN QUERIES
# ============================================================

func get_nearby_walkable_tiles(
    center: Vector2i,
    radius: int
) -> Array[Vector2i]:
    var result: Array[Vector2i] = []

    for y in range(
        center.y - radius,
        center.y + radius + 1
    ):
        for x in range(
            center.x - radius,
            center.x + radius + 1
        ):
            var coordinate := Vector2i(x, y)

            if is_walkable(coordinate):
                result.append(coordinate)

    return result


func find_nearest_buildable_tile(
    origin: Vector2i,
    max_radius: int = 20
) -> Vector2i:
    if is_buildable(origin):
        return origin

    for radius in range(1, max_radius + 1):
        for y in range(
            origin.y - radius,
            origin.y + radius + 1
        ):
            for x in range(
                origin.x - radius,
                origin.x + radius + 1
            ):
                var coordinate := Vector2i(x, y)

                if is_buildable(coordinate):
                    return coordinate

    return Vector2i(-1, -1)


func get_terrain_name(
    terrain_type: int
) -> String:
    match terrain_type:
        TERRAIN_PLAINS:
            return "Ova"
        TERRAIN_FOREST:
            return "Orman"
        TERRAIN_MOUNTAIN:
            return "Dag"
        TERRAIN_DESERT:
            return "Col"
        TERRAIN_WATER:
            return "Su"
        TERRAIN_HILLS:
            return "Tepe"

    return "Bilinmeyen"


# ============================================================
# QUALITY MANAGEMENT
# ============================================================

func set_quality_level(value: int) -> void:
    quality_level = clampi(value, 0, 2)

    match quality_level:
        0:
            visible_chunk_radius = 1
        1:
            visible_chunk_radius = 2
        2:
            visible_chunk_radius = 3

    clear_all_chunks()
    update_visible_chunks()


# ============================================================
# STATISTICS
# ============================================================

func get_map_statistics() -> Dictionary:
    return {
        "version": "100.2",
        "world_width": WORLD_WIDTH,
        "world_height": WORLD_HEIGHT,
        "chunk_size": CHUNK_SIZE,
        "loaded_chunks": chunks.size(),
        "queued_chunks": chunk_queue.size(),
        "total_generated_chunks": total_generated_chunks,
        "total_generated_tiles": total_generated_tiles,
        "quality_level": quality_level,
        "center_x": map_center.x,
        "center_y": map_center.y
    }


func _exit_tree() -> void:
    clear_all_chunks()
