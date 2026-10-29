
extends Node

# RISE OF CONQUEST
# FPS + BUILDING DRAG + HOLD TO SHOW NAMES
# Godot 4.4.1

const HOLD_SECONDS := 0.55
const SAVE_FILE := "user://city_positions_v1.json"

const BUILDING_TYPES := [
    "Merkez", "Ev", "Kule", "Kışla",
    "Çiftlik", "Kereste", "Taşocağı"
]

var game: Node3D
var camera: Camera3D
var fps_label: Label
var name_labels: Dictionary = {}

var pressing := false
var holding := false
var showing_all_names := false
var press_time := 0.0
var press_position := Vector2.ZERO
var current_position := Vector2.ZERO
var active_finger := -1

var selected_building: Node3D
var original_position := Vector3.ZERO
var original_preview_position := Vector3.ZERO
var original_decor_position := Vector3.ZERO

var saved_positions: Dictionary = {}
var fps_timer := 0.0


func _ready() -> void:
    game = get_parent() as Node3D
    set_process_input(true)
    call_deferred("initialize")


func initialize() -> void:
    camera = game.get("camera") as Camera3D
    create_fps_counter()
    load_positions()
    refresh_buildings()


func create_fps_counter() -> void:
    var layer := CanvasLayer.new()
    layer.name = "PerformanceOverlay"
    layer.layer = 100
    add_child(layer)

    fps_label = Label.new()
    fps_label.name = "FPS"
    fps_label.set_anchors_preset(
        Control.PRESET_TOP_RIGHT
    )
    fps_label.offset_left = -135.0
    fps_label.offset_right = -12.0
    fps_label.offset_top = 55.0
    fps_label.offset_bottom = 90.0
    fps_label.horizontal_alignment = (
        HORIZONTAL_ALIGNMENT_RIGHT
    )
    fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fps_label.add_theme_font_size_override("font_size", 20)
    fps_label.add_theme_color_override(
        "font_shadow_color", Color.BLACK
    )
    fps_label.add_theme_constant_override(
        "shadow_offset_x", 2
    )
    fps_label.add_theme_constant_override(
        "shadow_offset_y", 2
    )
    layer.add_child(fps_label)


func _process(delta: float) -> void:
    fps_timer += delta
    if fps_timer >= 0.5:
        fps_timer = 0.0
        update_fps()
        refresh_buildings()

    if pressing and not holding:
        press_time += delta
        if press_time >= HOLD_SECONDS:
            begin_hold()

    if showing_all_names:
        update_name_visibility(true)


func update_fps() -> void:
    if fps_label == null:
        return

    var fps := Engine.get_frames_per_second()
    fps_label.text = "FPS: %d" % fps

    var color := Color.GREEN
    if fps < 30:
        color = Color.RED
    elif fps < 55:
        color = Color.YELLOW

    fps_label.add_theme_color_override(
        "font_color", color
    )


func get_buildings() -> Array[Node3D]:
    var result: Array[Node3D] = []

    if game == null:
        return result

    for child in game.get_children():
        if not (child is Node3D):
            continue

        var building := child as Node3D
        var kind := building.name.rstrip("0123456789")

        if kind in BUILDING_TYPES:
            result.append(building)

    return result


func refresh_buildings() -> void:
    for building in get_buildings():
        var key := str(building.get_path())

        if not name_labels.has(key):
            var label := Label3D.new()
            label.name = "BuildingName"
            label.text = display_name(building)
            label.font_size = 64
            label.pixel_size = 0.006
            label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
            label.no_depth_test = true
            label.modulate = Color.WHITE
            label.outline_modulate = Color.BLACK
            label.outline_size = 12
            label.visible = false

            building.add_child(label)
            label.position = Vector3(
                0, get_building_height(building) + 0.8, 0
            )

            name_labels[key] = label

    update_name_visibility(showing_all_names)


func display_name(building: Node3D) -> String:
    var kind := building.name.rstrip("0123456789")

    if kind == "Merkez":
        return "Osmanlı Belediye Binası"
    if kind == "Kereste":
        return "Kereste Atölyesi"
    if kind == "Taşocağı":
        return "Taş Ocağı"

    return kind


func get_building_height(building: Node3D) -> float:
    if building.name.begins_with("Merkez"):
        return 6.0
    if building.name.begins_with("Kule"):
        return 5.0
    return 3.5


func update_name_visibility(visible_state: bool) -> void:
    for label in name_labels.values():
        if is_instance_valid(label):
            label.visible = visible_state


func screen_to_ground(screen_pos: Vector2) -> Vector3:
    if camera == null:
        return Vector3.INF

    var origin := camera.project_ray_origin(screen_pos)
    var direction := camera.project_ray_normal(screen_pos)

    if absf(direction.y) < 0.0001:
        return Vector3.INF

    var distance := -origin.y / direction.y

    if distance <= 0.0:
        return Vector3.INF

    return origin + direction * distance


func find_building(screen_pos: Vector2) -> Node3D:
    var ground := screen_to_ground(screen_pos)

    if not ground.is_finite():
        return null

    var best: Node3D = null
    var best_distance := INF

    for building in get_buildings():
        var radius := 2.6
        if building.name.begins_with("Merkez"):
            radius = 4.0
        elif building.name.begins_with("Kule"):
            radius = 2.0

        var distance := Vector2(
            ground.x - building.global_position.x,
            ground.z - building.global_position.z
        ).length()

        if distance <= radius and distance < best_distance:
            best = building
            best_distance = distance

    return best


func _input(event: InputEvent) -> void:
    if camera == null:
        return

    if bool(game.get("world_mode")):
        return

    if bool(game.get("placing")):
        return

    if bool(game.get("battle_active")):
        return

    if event is InputEventScreenTouch:
        if event.pressed:
            if pressing:
                cancel_hold()
                return
            start_press(event.position, event.index)
        elif event.index == active_finger:
            finish_press()
            if holding:
                get_viewport().set_input_as_handled()

    elif event is InputEventScreenDrag:
        if event.index != active_finger:
            return

        current_position = event.position

        if holding:
            if selected_building != null:
                move_selected(event.position)
            get_viewport().set_input_as_handled()
        elif event.position.distance_to(press_position) > 14.0:
            pressing = false

    elif event is InputEventMouseButton:
        if event.button_index != MOUSE_BUTTON_LEFT:
            return

        if event.pressed:
            start_press(event.position, -2)
        else:
            finish_press()
            if holding:
                get_viewport().set_input_as_handled()

    elif event is InputEventMouseMotion:
        if active_finger != -2:
            return

        current_position = event.position

        if holding:
            if selected_building != null:
                move_selected(event.position)
            get_viewport().set_input_as_handled()
        elif event.position.distance_to(press_position) > 14.0:
            pressing = false


func start_press(pos: Vector2, finger: int) -> void:
    pressing = true
    holding = false
    showing_all_names = false
    selected_building = null
    press_time = 0.0
    press_position = pos
    current_position = pos
    active_finger = finger


func begin_hold() -> void:
    if not pressing:
        return

    holding = true
    selected_building = find_building(press_position)

    if selected_building == null:
        showing_all_names = true
        refresh_buildings()
        update_name_visibility(true)
    else:
        original_position = selected_building.position

        var preview := game.get_node_or_null(
            "OttomanCityHallPreview"
        ) as Node3D
        if preview != null:
            original_preview_position = preview.position

        var decor := game.get_node_or_null(
            "CityUpgrade30/CityDecorations30/CastleUpgrades"
        ) as Node3D
        if decor != null:
            original_decor_position = decor.position

        showing_all_names = true
        refresh_buildings()
        update_name_visibility(true)


func move_selected(pos: Vector2) -> void:
    if selected_building == null:
        return

    var ground := screen_to_ground(pos)
    if not ground.is_finite():
        return

    var target := Vector3(
        clampf(roundf(ground.x), -14.0, 14.0),
        0.0,
        clampf(roundf(ground.z), -14.0, 14.0)
    )

    for other in get_buildings():
        if other == selected_building:
            continue

        if other.position.distance_to(target) < 4.0:
            return

    var previous := selected_building.position
    selected_building.position = target

    if selected_building.name.begins_with("Merkez"):
        var offset := target - previous

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


func finish_press() -> void:
    if holding and selected_building != null:
        save_positions()

    pressing = false
    showing_all_names = false
    update_name_visibility(false)
    selected_building = null
    active_finger = -1


func cancel_hold() -> void:
    pressing = false
    holding = false
    showing_all_names = false
    selected_building = null
    active_finger = -1
    update_name_visibility(false)


func save_positions() -> void:
    var entries: Dictionary = {}

    for building in get_buildings():
        var p := building.position
        entries[str(building.get_path())] = [
            p.x, p.y, p.z
        ]

    var file := FileAccess.open(
        SAVE_FILE, FileAccess.WRITE
    )
    if file != null:
        file.store_string(JSON.stringify(entries))
        file.close()


func load_positions() -> void:
    if not FileAccess.file_exists(SAVE_FILE):
        return

    var file := FileAccess.open(
        SAVE_FILE, FileAccess.READ
    )
    if file == null:
        return

    var data: Variant = JSON.parse_string(
        file.get_as_text()
    )
    file.close()

    if not (data is Dictionary):
        return

    for building in get_buildings():
        var key := str(building.get_path())

        if not data.has(key):
            continue

        var coordinates: Variant = data[key]
        if not (coordinates is Array):
            continue
        if coordinates.size() != 3:
            continue

        var target := Vector3(
            float(coordinates[0]),
            float(coordinates[1]),
            float(coordinates[2])
        )

        var offset := target - building.position
        building.position = target

        if building.name.begins_with("Merkez"):
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
