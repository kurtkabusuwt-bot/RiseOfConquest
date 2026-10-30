
extends CanvasLayer

# RISE OF CONQUEST - BUILD 95.8
# MOBILE CONSTRUCTION REPOSITION
# Godot 4.4.1 / Android

const PANEL_COLOR := Color(0.035, 0.065, 0.105, 0.96)
const GOLD_COLOR := Color(0.91, 0.72, 0.39)
const TEXT_COLOR := Color(0.95, 0.95, 0.96)
const GREEN_COLOR := Color(0.24, 0.67, 0.43)
const RED_COLOR := Color(0.75, 0.28, 0.27)
const BLUE_COLOR := Color(0.20, 0.47, 0.75)

const BUILDING_COSTS := {
    "Ev": {"woods": 100},
    "Kışla": {"woods": 200},
    "Çiftlik": {"woods": 80},
    "Taşocağı": {"woods": 100},
    "Kereste": {"coins": 100},
    "Kule": {"coins": 150}
}

var game: Node
var panel: PanelContainer

var title_label: Label
var building_label: Label
var position_label: Label
var cost_label: Label
var resource_label: Label
var status_label: Label

var confirm_button: Button
var reposition_button: Button
var cancel_button: Button

var refresh_elapsed := 0.0


func _ready() -> void:
    layer = 105
    game = get_parent()
    _build_ui()
    _refresh_ui()
    set_process(true)


func _make_label(
    value: String,
    font_size: int,
    font_color: Color
) -> Label:
    var result := Label.new()
    result.text = value
    result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result.add_theme_font_size_override(
        "font_size", font_size
    )
    result.add_theme_color_override(
        "font_color", font_color
    )
    return result


func _make_button(
    value: String,
    button_color: Color
) -> Button:
    var result := Button.new()
    result.text = value
    result.custom_minimum_size = Vector2(125, 44)
    result.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var normal_style := StyleBoxFlat.new()
    normal_style.bg_color = button_color
    normal_style.set_corner_radius_all(8)
    normal_style.set_content_margin_all(8)

    var hover_style := normal_style.duplicate() as StyleBoxFlat
    hover_style.bg_color = button_color.lightened(0.12)

    var pressed_style := normal_style.duplicate() as StyleBoxFlat
    pressed_style.bg_color = button_color.darkened(0.15)

    result.add_theme_stylebox_override(
        "normal", normal_style
    )
    result.add_theme_stylebox_override(
        "hover", hover_style
    )
    result.add_theme_stylebox_override(
        "pressed", pressed_style
    )

    result.add_theme_color_override(
        "font_color", Color.WHITE
    )
    result.add_theme_color_override(
        "font_hover_color", Color.WHITE
    )
    result.add_theme_color_override(
        "font_pressed_color", Color.WHITE
    )

    return result


func _build_ui() -> void:
    panel = PanelContainer.new()
    panel.name = "ConstructionConfirmPanel"
    add_child(panel)

    panel.set_anchors_preset(
        Control.PRESET_CENTER_BOTTOM
    )

    panel.custom_minimum_size = Vector2(330, 275)
    panel.offset_left = -165
    panel.offset_right = 165
    panel.offset_top = -330
    panel.offset_bottom = -55

    var style := StyleBoxFlat.new()
    style.bg_color = PANEL_COLOR
    style.border_color = GOLD_COLOR
    style.set_border_width_all(2)
    style.set_corner_radius_all(12)
    style.set_content_margin_all(10)

    panel.add_theme_stylebox_override(
        "panel", style
    )

    var layout := VBoxContainer.new()
    layout.add_theme_constant_override(
        "separation", 6
    )
    panel.add_child(layout)

    title_label = _make_label(
        "INSAAT ONAYI", 18, GOLD_COLOR
    )
    layout.add_child(title_label)

    building_label = _make_label(
        "Bina: -", 15, TEXT_COLOR
    )
    layout.add_child(building_label)

    position_label = _make_label(
        "Konum: -", 13, TEXT_COLOR
    )
    layout.add_child(position_label)

    cost_label = _make_label(
        "Maliyet: -", 14, GOLD_COLOR
    )
    layout.add_child(cost_label)

    resource_label = _make_label(
        "Mevcut kaynak: -", 13, TEXT_COLOR
    )
    layout.add_child(resource_label)

    status_label = _make_label(
        "Kontrol ediliyor", 12, GREEN_COLOR
    )
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    layout.add_child(status_label)

    var action_row := HBoxContainer.new()
    action_row.add_theme_constant_override(
        "separation", 10
    )
    layout.add_child(action_row)

    confirm_button = _make_button(
        "INSA ET", GREEN_COLOR
    )
    confirm_button.pressed.connect(_confirm)
    action_row.add_child(confirm_button)

    cancel_button = _make_button(
        "IPTAL", RED_COLOR
    )
    cancel_button.pressed.connect(_cancel)
    action_row.add_child(cancel_button)

    reposition_button = _make_button(
        "YER DEGISTIR", BLUE_COLOR
    )
    reposition_button.pressed.connect(_reposition)
    layout.add_child(reposition_button)

    panel.visible = false


func _process(delta: float) -> void:
    refresh_elapsed += delta

    if refresh_elapsed < 0.15:
        return

    refresh_elapsed = 0.0
    _refresh_ui()


func _is_pending() -> bool:
    if not is_instance_valid(game):
        return false

    if not game.has_method(
        "get_construction_pending"
    ):
        return false

    return bool(
        game.call("get_construction_pending")
    )


func _resource_name(key: String) -> String:
    match key:
        "coins":
            return "Altin"
        "woods":
            return "Odun"
        "stones":
            return "Tas"
        "foods":
            return "Yiyecek"
        _:
            return key


func _resource_amount(key: String) -> int:
    if not is_instance_valid(game):
        return 0

    return int(game.get(key))


func _get_cost_problem(kind: String) -> String:
    if not BUILDING_COSTS.has(kind):
        return "Gecersiz bina turu"

    var costs: Dictionary = BUILDING_COSTS[kind]

    for resource_key in costs.keys():
        var key := str(resource_key)
        var required := int(costs[key])
        var available := _resource_amount(key)

        if available < required:
            var missing := required - available
            return (
                "%s eksik: %d"
                % [_resource_name(key), missing]
            )

    return ""


func _update_cost_display(kind: String) -> void:
    if not BUILDING_COSTS.has(kind):
        cost_label.text = "Maliyet: Bilinmiyor"
        resource_label.text = "Kaynak bilgisi yok"
        return

    var costs: Dictionary = BUILDING_COSTS[kind]

    var cost_parts: PackedStringArray = []
    var balance_parts: PackedStringArray = []

    for resource_key in costs.keys():
        var key := str(resource_key)
        var required := int(costs[key])
        var available := _resource_amount(key)
        var name := _resource_name(key)

        cost_parts.append(
            "%d %s" % [required, name]
        )

        balance_parts.append(
            "%s: %d" % [name, available]
        )

    cost_label.text = (
        "Maliyet: " + ", ".join(cost_parts)
    )

    resource_label.text = (
        "Mevcut: " + ", ".join(balance_parts)
    )


func _set_status(
    message: String,
    color: Color,
    can_build: bool
) -> void:
    status_label.text = message
    status_label.add_theme_color_override(
        "font_color", color
    )
    confirm_button.disabled = not can_build


func _refresh_ui() -> void:
    if not is_instance_valid(panel):
        return

    var pending := _is_pending()
    panel.visible = pending

    if not pending:
        return

    var kind := str(game.get("selected_building"))
    building_label.text = "Bina: " + kind

    var position := Vector3.ZERO

    if game.has_method(
        "get_construction_position"
    ):
        position = game.call(
            "get_construction_position"
        )

    position_label.text = (
        "Konum: X %d  |  Z %d"
        % [
            roundi(position.x),
            roundi(position.z)
        ]
    )

    _update_cost_display(kind)

    var placement_problem := ""

    if game.has_method("construction_check"):
        placement_problem = str(
            game.call(
                "construction_check",
                kind,
                position
            )
        )

    if not placement_problem.is_empty():
        _set_status(
            "Konum uygun degil: " + placement_problem,
            RED_COLOR,
            false
        )
        return

    var cost_problem := _get_cost_problem(kind)

    if not cost_problem.is_empty():
        _set_status(
            cost_problem,
            RED_COLOR,
            false
        )
        return

    if game.has_method("_construction_cost_problem"):
        var game_cost_problem := str(
            game.call(
                "_construction_cost_problem",
                kind
            )
        )

        if not game_cost_problem.is_empty():
            _set_status(
                game_cost_problem,
                RED_COLOR,
                false
            )
            return

    _set_status(
        "Konum ve kaynaklar uygun - Insaat hazir",
        GREEN_COLOR,
        true
    )


func _confirm() -> void:
    if not _is_pending():
        return

    _refresh_ui()

    if confirm_button.disabled:
        return

    if game.has_method("confirm_construction"):
        game.call("confirm_construction")

    _refresh_ui()


func _reposition() -> void:
    if not _is_pending():
        return

    if not game.has_method(
        "clear_construction_pending"
    ):
        return

    var kind := str(game.get("selected_building"))

    game.call("clear_construction_pending")

    # Keep construction placement mode active.
    game.set("placing", true)
    game.set("status", (
        "%s icin yeni konum sec."
        % kind
    ))

    if game.has_method("update_ui"):
        game.call("update_ui")

    _refresh_ui()


func _cancel() -> void:
    if not is_instance_valid(game):
        return

    if game.has_method("reject_construction"):
        game.call("reject_construction")

    _refresh_ui()
