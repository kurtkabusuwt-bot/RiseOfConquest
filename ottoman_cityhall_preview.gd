
extends Node3D

# RISE OF CONQUEST
# OTTOMAN CITY HALL - ORIGINAL QUALITY
# Godot 4.4.1
# 8 GLB parts, original geometry preserved

const PART_COUNT: int = 8
const TARGET_WIDTH: float = 7.0

var game: Node3D
var building_holder: Node3D
var old_center: Node3D
var old_decorations: Node3D
var loaded_parts: int = 0


func _ready() -> void:
    call_deferred("setup_city_hall")


func setup_city_hall() -> void:
    game = get_parent() as Node3D

    if game == null:
        push_error("Game root not found.")
        return

    building_holder = Node3D.new()
    building_holder.name = "OttomanCityHallOriginal"
    add_child(building_holder)

    for part_number in range(1, PART_COUNT + 1):
        var path: String = (
            "res://ottoman_cityhall_part_%02d.glb"
            % part_number
        )

        var resource: Resource = load(path)

        if not (resource is PackedScene):
            push_error("GLB part cannot load: " + path)
            continue

        var part: Node = (
            resource as PackedScene
        ).instantiate()

        if not (part is Node3D):
            push_error("Invalid GLB part: " + path)
            part.queue_free()
            continue

        part.name = "CityHallPart_%02d" % part_number
        building_holder.add_child(part)

        loaded_parts += 1

    if loaded_parts != PART_COUNT:
        push_error(
            "Missing city hall parts: %d / %d"
            % [loaded_parts, PART_COUNT]
        )

        building_holder.queue_free()
        building_holder = null
        return

    adjust_building()
    hide_old_city_hall()

    print(
        "Ottoman City Hall loaded: %d parts"
        % loaded_parts
    )


func adjust_building() -> void:
    var bounds: AABB = calculate_bounds(
        building_holder
    )

    if bounds.size.length() < 0.001:
        push_error("City hall bounds are empty.")
        return

    var horizontal_size: float = maxf(
        bounds.size.x,
        bounds.size.z
    )

    if horizontal_size <= 0.001:
        return

    var factor: float = (
        TARGET_WIDTH / horizontal_size
    )

    var center: Vector3 = bounds.get_center()

    building_holder.scale = (
        Vector3.ONE * factor
    )

    building_holder.position = Vector3(
        -center.x * factor,
        -bounds.position.y * factor,
        -center.z * factor
    )


func calculate_bounds(root: Node3D) -> AABB:
    var stack: Array[Node] = [root]
    var found: bool = false
    var result: AABB = AABB()

    while not stack.is_empty():
        var current: Node = stack.pop_back()

        if current is MeshInstance3D:
            var mesh_instance: MeshInstance3D = (
                current as MeshInstance3D
            )

            if mesh_instance.mesh != null:
                var relative: Transform3D = (
                    root.global_transform.affine_inverse()
                    * mesh_instance.global_transform
                )

                var mesh_bounds: AABB = (
                    relative * mesh_instance.get_aabb()
                )

                if not found:
                    result = mesh_bounds
                    found = true
                else:
                    result = result.merge(mesh_bounds)

        for child in current.get_children():
            stack.append(child)

    return result


func hide_old_city_hall() -> void:
    old_center = game.get_node_or_null(
        "Merkez"
    ) as Node3D

    old_decorations = game.get_node_or_null(
        "CityUpgrade30/CityDecorations30/CastleUpgrades"
    ) as Node3D

    if is_instance_valid(old_center):
        old_center.visible = false

    if is_instance_valid(old_decorations):
        old_decorations.visible = false


func _process(_delta: float) -> void:
    if loaded_parts != PART_COUNT:
        return

    if is_instance_valid(old_center):
        if old_center.visible:
            old_center.visible = false

    if is_instance_valid(old_decorations):
        if old_decorations.visible:
            old_decorations.visible = false


func _exit_tree() -> void:
    if is_instance_valid(old_center):
        old_center.visible = true

    if is_instance_valid(old_decorations):
        old_decorations.visible = true
