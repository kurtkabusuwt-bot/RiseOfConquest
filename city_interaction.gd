
extends Node

# RISE OF CONQUEST
# CITY INTERACTION 2.0
# Godot 4.4.1

const HOLD_TIME: float = 0.55
const MOVE_LIMIT: float = 20.0
const SAVE_PATH: String = "user://building_layout_v2.json"

const TYPES: Array[String] = [
    "Merkez", "Ev", "Kule", "Kışla",
    "Çiftlik", "Kereste", "Taşocağı"
]

var game: Node3D
var camera: Camera3D
var label_root: Node3D
var fps_label: Label

var labels: Dictionary = {}
var pressing: bool = false
var hold_active: bool = false
var show_names: bool = false
var hold_elapsed: float = 0.0
var finger: int = -1
var start_point: Vector2 = Vector2.ZERO
var selected: Node3D = null
var last_valid_position: Vector3 = Vector3.ZERO
var fps_elapsed: float = 0.0
var refresh_elapsed: float = 0.0


func _ready() -> void:
    call_deferred("initialize")


func initialize() -> void:
    game = get_parent() as Node3D
    if game == null:
        return

    camera = game.get("camera") as Camera3D

    label_root = Node3D.new()
    label_root.name = "BuildingNameOverlay"
    add_child(label_root)

    create_fps()
    load_layout()
    refresh_labels()


func create_fps() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 100
    add_child(layer)

    var panel := Control.new()
    panel.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT
    )
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(panel)

    fps_label = Label.new()
    fps_label.set_anchors_preset(
        Control.PRESET_TOP_RIGHT
    )
    fps_label.offset_left = -145.0
    fps_label.offset_right = -12.0
    fps_label.offset_top = 50.0
    fps_label.offset_bottom = 85.0
    fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fps_label.add_theme_font_size_override("font_size", 20)
    fps_label.add_theme_color_override(
        "font_shadow_color", Color.BLACK
    )
    fps_label.add_theme_constant_override("shadow_offset_x", 2)
    fps_label.add_theme_constant_override("shadow_offset_y", 2)
    panel.add_child(fps_label)


func _process(delta: float) -> void:
    fps_elapsed += delta
    refresh_elapsed += delta

    if fps_elapsed >= 0.5:
        fps_elapsed = 0.0
        var fps := Engine.get_frames_per_second()
        fps_label.text = "FPS: %d" % fps

        var color := Color.GREEN
        if fps < 30:
            color = Color.RED
        elif fps < 55:
            color = Color.YELLOW

        fps_label.add_theme_color_override("font_color", color)

    if refresh_elapsed >= 0.5:
        refresh_elapsed = 0.0
        refresh_labels()

    if pressing and not hold_active:
        hold_elapsed += delta
        if hold_elapsed >= HOLD_TIME:
            activate_hold()

    if show_names:
        position_labels()


func interaction_allowed() -> bool:
    if game == null or camera == null:
        return false

    if bool(game.get("world_mode")):
        return false
    if bool(game.get("placing")):
        return false
    if bool(game.get("battle_active")):
        return false
    if bool(game.get("ruler_mode")):
        return false

    return true


func get_buildings() -> Array[Node3D]:
    var result: Array[Node3D] = []

    for child in game.get_children():
        if not (child is Node3D):
            continue

        var node := child as Node3D
        if node.name in TYPES:
            result.append(node)

    return result


func get_title(building: Node3D) -> String:
    match building.name:
        "Merkez":
            return "Osmanlı Belediye Binası"
        "Ev":
            return "Ev"
        "Kule":
            return "Gözetleme Kulesi"
        "Kışla":
            return "Kışla"
        "Çiftlik":
            return "Çiftlik"
        "Kereste":
            return "Kereste Atölyesi"
        "Taşocağı":
            return "Taş Ocağı"

    return building.name


func refresh_labels() -> void:
    if label_root == null:
        return

    for building in get_buildings():
        var key := building.get_instance_id()

        if labels.has(key):
            continue

        var label := Label3D.new()
        label.name = "Name_%d" % key
        label.text = get_title(building)
        label.font_size = 48
        label.pixel_size = 0.006
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.no_depth_test = true
        label.outline_size = 10
        label.modulate = Color.WHITE
        label.outline_modulate = Color.BLACK
        label.visible = show_names

        label_root.add_child(label)
        labels[key] = {
            "building": building,
            "label": label
        }

    position_labels()


func position_labels() -> void:
    for key in labels.keys():
        var entry: Dictionary = labels[key]
        var building: Node3D = entry["building"]
        var label: Label3D = entry["label"]

        if not is_instance_valid(building):
            label.queue_free()
            labels.erase(key)
            continue

        var height := 3.5

        if building.name == "Merkez":
            height = 7.0
        elif building.name == "Kule":
            height = 5.5

        label.global_position = (
            building.global_position
            + Vector3(0.0, height, 0.0)
        )
        label.visible = show_names


func ground_at(screen_pos: Vector2) -> Vector3:
    var origin := camera.project_ray_origin(screen_pos)
    var direction := camera.project_ray_normal(screen_pos)

    if absf(direction.y) < 0.0001:
        return Vector3.INF

    var distance := -origin.y / direction.y
    if distance <= 0.0:
        return Vector3.INF

    return origin + direction * distance


func building_at(screen_pos: Vector2) -> Node3D:
    var hit := ground_at(screen_pos)
    if not hit.is_finite():
        return null

    var nearest: Node3D = null
    var nearest_distance: float = INF

    for building in get_buildings():
        var radius := 2.8

        if building.name == "Merkez":
            radius = 4.2
        elif building.name == "Kule":
            radius = 2.2

        var distance := Vector2(
            hit.x - building.global_position.x,
            hit.z - building.global_position.z
        ).length()

        if distance < radius and distance < nearest_distance:
            nearest = building
            nearest_distance = distance

    return nearest


func _input(event: InputEvent) -> void:
    if not interaction_allowed():
        return

    if event is InputEventScreenTouch:
        if event.pressed:
            if pressing:
                cancel_interaction()
                return

            start_press(event.position, event.index)
        elif event.index == finger:
            var was_holding := hold_active
            finish_press()
            if was_holding:
                get_viewport().set_input_as_handled()

    elif event is InputEventScreenDrag:
        if event.index != finger:
            return

        if hold_active:
            if selected != null:
                drag_building(event.position)
            get_viewport().set_input_as_handled()
        elif event.position.distance_to(start_point) > MOVE_LIMIT:
            pressing = false

    elif event is InputEventMouseButton:
        if event.button_index != MOUSE_BUTTON_LEFT:
            return

        if event.pressed:
            start_press(event.position, -2)
        elif finger == -2:
            var was_holding := hold_active
            finish_press()
            if was_holding:
                get_viewport().set_input_as_handled()

    elif event is InputEventMouseMotion:
        if finger != -2:
            return

        if hold_active:
            if selected != null:
                drag_building(event.position)
            get_viewport().set_input_as_handled()
        elif event.position.distance_to(start_point) > MOVE_LIMIT:
            pressing = false


func start_press(pos: Vector2, index: int) -> void:
    pressing = true
    hold_active = false
    show_names = false
    selected = null
    hold_elapsed = 0.0
    finger = index
    start_point = pos


func activate_hold() -> void:
    if not pressing:
        return

    hold_active = true
    selected = building_at(start_point)
    show_names = true
    refresh_labels()

    if selected != null:
        last_valid_position = selected.position

    position_labels()


func drag_building(pos: Vector2) -> void:
    if selected == null:
        return

    var hit := ground_at(pos)
    if not hit.is_finite():
        return

    var target := Vector3(
        clampf(roundf(hit.x), -47.0, 47.0),
        0.0,
        clampf(roundf(hit.z), -47.0, 47.0)
    )

    var radius := 4.0
    if selected.name == "Merkez":
        radius = 5.5

    for other in get_buildings():
        if other == selected:
            continue

        var separation := Vector2(
            target.x - other.position.x,
            target.z - other.position.z
        ).length()

        if separation < radius:
            return

    var offset := target - selected.position
    selected.position = target
    last_valid_position = target

    if selected.name == "Merkez":
        var preview := game.get_node_or_null(
            "OttomanCityHallPreview"
        ) as Node3D

        if preview != null:
            preview.position += offset

        var decor := game.get_node_or_null(
            "CityUpgrade30/CityDecorations30/CastleUpgrades"
        ) as Node3D

        if decor != null:
            decor.position += offset

    position_labels()


func finish_press() -> void:
    if hold_active and selected != null:
        save_layout()

    pressing = false
    hold_active = false
    show_names = false
    selected = null
    finger = -1

    # Prevent an old touch from triggering a ground tap.
    if game != null:
        game.set("touch_positions", {})
        game.set("dragging", true)
        game.set("pinch_last_distance", 0.0)

    position_labels()


func cancel_interaction() -> void:
    pressing = false
    hold_active = false
    show_names = false
    selected = null
    finger = -1
    position_labels()


func save_layout() -> void:
    var data: Array[Dictionary] = []

    for building in get_buildings():
        data.append({
            "kind": building.name,
            "x": building.position.x,
            "z": building.position.z
        })

    var file := FileAccess.open(
        SAVE_PATH, FileAccess.WRITE
    )

    if file != null:
        file.store_string(JSON.stringify(data))
        file.close()


func load_layout() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return

    var file := FileAccess.open(
        SAVE_PATH, FileAccess.READ
    )
    if file == null:
        return

    var parsed: Variant = JSON.parse_string(
        file.get_as_text()
    )
    file.close()

    if not (parsed is Array):
        return

    var buildings := get_buildings()
    var used: Dictionary = {}

    for entry in parsed:
        if not (entry is Dictionary):
            continue

        var kind: String = str(entry.get("kind", ""))
        var target: Node3D = null

        for building in buildings:
            var key := building.get_instance_id()

            if building.name == kind and not used.has(key):
                target = building
                used[key] = true
                break

        if target == null:
            continue

        var new_position := Vector3(
            float(entry.get("x", target.position.x)),
            0.0,
            float(entry.get("z", target.position.z))
        )

        var offset := new_position - target.position
        target.position = new_position

        if target.name == "Merkez":
            var preview := game.get_node_or_null(
                "OttomanCityHallPreview"
            ) as Node3D

            if preview != null:
                preview.position += offset

            var decor := game.get_node_or_null(
                "CityUpgrade30/CityDecorations30/CastleUpgrades"
            ) as Node3D

            if decor != null:
                decor.position += offset
