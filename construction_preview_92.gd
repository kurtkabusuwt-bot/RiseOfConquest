
extends Node3D

# RISE OF CONQUEST - BUILD 95.1
# MOBILE 3D CONSTRUCTION PREVIEW
# Godot 4.4.1 / Android

const VALID_COLOR := Color(0.12, 0.90, 0.35, 0.45)
const INVALID_COLOR := Color(1.0, 0.18, 0.16, 0.52)
const SELECTED_COLOR := Color(0.15, 0.75, 1.0, 0.52)

var game: Node3D
var ghost_root: Node3D
var model_root: Node3D
var guide_root: Node3D

var ghost_material: StandardMaterial3D
var guide_material: StandardMaterial3D

var last_pointer := Vector2.ZERO
var has_pointer := false
var touch_active := false
var was_placing := false
var last_kind := ""


func _ready() -> void:
    set_process(false)
    call_deferred("_initialize")


func _initialize() -> void:
    game = get_parent() as Node3D

    if not is_instance_valid(game):
        return

    ghost_material = _make_material(VALID_COLOR)
    guide_material = _make_material(VALID_COLOR)

    ghost_root = Node3D.new()
    ghost_root.name = "ConstructionGhost"
    add_child(ghost_root)

    model_root = Node3D.new()
    model_root.name = "BuildingModel"
    ghost_root.add_child(model_root)

    guide_root = Node3D.new()
    guide_root.name = "PlacementGuides"
    ghost_root.add_child(guide_root)

    ghost_root.visible = false
    set_process(true)

    print("ROC BUILD 95.1: Construction preview ready")


func _make_material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.albedo_color = color
    material.no_depth_test = false
    return material


func _game_bool(property_name: String) -> bool:
    if not is_instance_valid(game):
        return false

    for property in game.get_property_list():
        if str(property.get("name", "")) == property_name:
            return bool(game.get(property_name))

    return false


func _input(event: InputEvent) -> void:
    if not is_instance_valid(game):
        return

    if not _game_bool("placing"):
        return

    if event is InputEventScreenTouch:
        if event.pressed:
            touch_active = true
            last_pointer = event.position
            has_pointer = true
        else:
            touch_active = false

    elif event is InputEventScreenDrag:
        if touch_active:
            last_pointer = event.position
            has_pointer = true

    elif event is InputEventMouseMotion:
        last_pointer = event.position
        has_pointer = true


func _process(_delta: float) -> void:
    if not is_instance_valid(game):
        return

    if not is_instance_valid(ghost_root):
        return

    if not _game_bool("placing"):
        _reset_preview()
        return

    if _game_bool("world_mode"):
        ghost_root.visible = false
        return

    if _game_bool("battle_active"):
        ghost_root.visible = false
        return

    if _game_bool("ruler_mode"):
        ghost_root.visible = false
        return

    var camera := game.get("camera") as Camera3D

    if not is_instance_valid(camera):
        ghost_root.visible = false
        return

    if not was_placing:
        was_placing = true
        has_pointer = false
        last_pointer = (
            get_viewport().get_visible_rect().size * 0.5
        )

    var kind := str(game.get("selected_building"))

    if kind != last_kind:
        last_kind = kind
        _build_ghost(kind)

    var pending := false

    if game.has_method("get_construction_pending"):
        pending = bool(
            game.call("get_construction_pending")
        )

    if pending:
        var selected_position := Vector3.ZERO

        if game.has_method("get_construction_position"):
            selected_position = game.call(
                "get_construction_position"
            )

        ghost_root.global_position = selected_position
        ghost_root.visible = true
        _set_color(SELECTED_COLOR)
        return

    if not has_pointer:
        last_pointer = (
            get_viewport().get_visible_rect().size * 0.5
        )

    var origin := camera.project_ray_origin(last_pointer)
    var direction := camera.project_ray_normal(last_pointer)

    if absf(direction.y) < 0.0001:
        ghost_root.visible = false
        return

    var distance := -origin.y / direction.y

    if distance <= 0.0:
        ghost_root.visible = false
        return

    var hit := origin + direction * distance

    var target := Vector3(
        float(roundi(hit.x)),
        0.0,
        float(roundi(hit.z))
    )

    ghost_root.global_position = target
    ghost_root.visible = true

    var problem := ""

    if game.has_method("construction_check"):
        problem = str(
            game.call("construction_check", kind, target)
        )

    if problem.is_empty():
        _set_color(VALID_COLOR)
    else:
        _set_color(INVALID_COLOR)


func _reset_preview() -> void:
    ghost_root.visible = false
    was_placing = false
    has_pointer = false
    touch_active = false
    last_kind = ""


func _set_color(color: Color) -> void:
    ghost_material.albedo_color = color

    guide_material.albedo_color = Color(
        color.r,
        color.g,
        color.b,
        0.85
    )


func _clear_root(target_root: Node3D) -> void:
    for child in target_root.get_children():
        target_root.remove_child(child)
        child.queue_free()


func _add_box(
    target_root: Node3D,
    part_name: String,
    box_size: Vector3,
    offset: Vector3,
    material: Material
) -> void:
    var part := MeshInstance3D.new()
    part.name = part_name

    var mesh := BoxMesh.new()
    mesh.size = box_size

    part.mesh = mesh
    part.material_override = material
    part.position = offset

    target_root.add_child(part)


func _add_cylinder(
    part_name: String,
    radius: float,
    height: float,
    offset: Vector3
) -> void:
    var part := MeshInstance3D.new()
    part.name = part_name

    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height

    part.mesh = mesh
    part.material_override = ghost_material
    part.position = offset

    model_root.add_child(part)


func _footprint(kind: String) -> Vector2:
    match kind:
        "Merkez":
            return Vector2(6.0, 6.0)
        "Kışla":
            return Vector2(4.8, 4.1)
        "Çiftlik":
            return Vector2(3.7, 3.7)
        "Kereste":
            return Vector2(3.6, 3.2)
        "Taşocağı":
            return Vector2(3.7, 3.7)
        "Kule":
            return Vector2(3.3, 3.3)
        "Ev":
            return Vector2(3.7, 3.7)
        _:
            return Vector2(4.0, 4.0)


func _build_guides(kind: String) -> void:
    _clear_root(guide_root)

    var size := _footprint(kind)
    var half_x := size.x * 0.5
    var half_z := size.y * 0.5

    # Ground footprint outline
    for side in [-1.0, 1.0]:
        _add_box(
            guide_root,
            "EdgeX",
            Vector3(size.x, 0.08, 0.15),
            Vector3(0.0, 0.06, side * half_z),
            guide_material
        )

        _add_box(
            guide_root,
            "EdgeZ",
            Vector3(0.15, 0.08, size.y),
            Vector3(side * half_x, 0.06, 0.0),
            guide_material
        )

    # Center marker
    _add_box(
        guide_root,
        "CenterX",
        Vector3(1.2, 0.07, 0.12),
        Vector3(0.0, 0.08, 0.0),
        guide_material
    )

    _add_box(
        guide_root,
        "CenterZ",
        Vector3(0.12, 0.07, 1.2),
        Vector3(0.0, 0.08, 0.0),
        guide_material
    )

    # Corner markers
    for x_sign in [-1.0, 1.0]:
        for z_sign in [-1.0, 1.0]:
            _add_box(
                guide_root,
                "Corner",
                Vector3(0.3, 0.12, 0.3),
                Vector3(
                    x_sign * half_x,
                    0.09,
                    z_sign * half_z
                ),
                guide_material
            )


func _model_box(
    part_name: String,
    box_size: Vector3,
    offset: Vector3
) -> void:
    _add_box(
        model_root,
        part_name,
        box_size,
        offset,
        ghost_material
    )


func _build_ghost(kind: String) -> void:
    _clear_root(model_root)
    _build_guides(kind)

    match kind:
        "Merkez":
            _model_box(
                "PalaceBase",
                Vector3(5.5, 3.0, 5.5),
                Vector3(0.0, 1.5, 0.0)
            )

            _add_cylinder(
                "PalaceDome",
                2.2,
                1.4,
                Vector3(0.0, 3.7, 0.0)
            )

            for side in [-1.0, 1.0]:
                _add_cylinder(
                    "Minaret",
                    0.32,
                    5.0,
                    Vector3(side * 2.5, 2.5, -2.8)
                )

        "Kışla":
            _model_box(
                "Barracks",
                Vector3(4.2, 2.4, 3.5),
                Vector3(0.0, 1.2, 0.0)
            )

            _model_box(
                "Roof",
                Vector3(4.7, 0.55, 4.0),
                Vector3(0.0, 2.65, 0.0)
            )

        "Ev":
            _model_box(
                "House",
                Vector3(3.0, 2.4, 3.0),
                Vector3(0.0, 1.2, 0.0)
            )

            _model_box(
                "Roof",
                Vector3(3.4, 0.65, 3.4),
                Vector3(0.0, 2.7, 0.0)
            )

        "Kule":
            _add_cylinder(
                "Tower",
                1.2,
                5.0,
                Vector3(0.0, 2.5, 0.0)
            )

            _add_cylinder(
                "Top",
                1.6,
                0.6,
                Vector3(0.0, 5.2, 0.0)
            )

        "Çiftlik":
            _model_box(
                "Field",
                Vector3(3.5, 0.15, 3.5),
                Vector3(0.0, 0.1, 0.0)
            )

            for i in range(4):
                _model_box(
                    "Crops",
                    Vector3(0.3, 0.55, 2.7),
                    Vector3(
                        -1.1 + float(i) * 0.7,
                        0.38,
                        0.0
                    )
                )

        "Kereste":
            _model_box(
                "Workshop",
                Vector3(3.0, 1.8, 2.5),
                Vector3(0.0, 0.9, 0.0)
            )

            _model_box(
                "Roof",
                Vector3(3.4, 0.4, 2.9),
                Vector3(0.0, 2.0, 0.0)
            )

        "Taşocağı":
            _model_box(
                "StoneBase",
                Vector3(3.5, 0.35, 3.5),
                Vector3(0.0, 0.18, 0.0)
            )

            for i in range(3):
                _model_box(
                    "Stone",
                    Vector3(0.9, 0.9, 0.9),
                    Vector3(
                        -1.0 + float(i),
                        0.65,
                        0.0
                    )
                )

        _:
            _model_box(
                "Default",
                Vector3(4.0, 2.0, 4.0),
                Vector3(0.0, 1.0, 0.0)
            )
