
extends CanvasLayer

# RISE OF CONQUEST - BUILD 95.5
# CONSTRUCTION VALIDATION PANEL
# Godot 4.4.1 / Android

const PANEL_COLOR := Color(0.035, 0.065, 0.105, 0.96)
const GOLD_COLOR := Color(0.91, 0.72, 0.39)
const TEXT_COLOR := Color(0.95, 0.95, 0.96)
const GREEN_COLOR := Color(0.24, 0.67, 0.43)
const RED_COLOR := Color(0.75, 0.28, 0.27)
const BLUE_COLOR := Color(0.20, 0.65, 0.95)

var game: Node
var panel: PanelContainer
var title_label: Label
var building_label: Label
var position_label: Label
var status_label: Label
var confirm_button: Button
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
    panel.custom_minimum_size = Vector2(320, 170)

    panel.offset_left = -160
    panel.offset_right = 160
    panel.offset_top = -220
    panel.offset_bottom = -50

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
        "Bina", 15, TEXT_COLOR
    )
    layout.add_child(building_label)

    position_label = _make_label(
        "Konum: -", 13, TEXT_COLOR
    )
    layout.add_child(position_label)

    status_label = _make_label(
        "Kontrol ediliyor", 12, BLUE_COLOR
    )
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    layout.add_child(status_label)

    var buttons := HBoxContainer.new()
    buttons.add_theme_constant_override(
        "separation", 10
    )
    layout.add_child(buttons)

    confirm_button = _make_button(
        "INSA ET", GREEN_COLOR
    )
    confirm_button.pressed.connect(_confirm)
    buttons.add_child(confirm_button)

    cancel_button = _make_button(
        "IPTAL", RED_COLOR
    )
    cancel_button.pressed.connect(_cancel)
    buttons.add_child(cancel_button)

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

    if not game.has_method("get_construction_pending"):
        return false

    return bool(
        game.call("get_construction_pending")
    )


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

    if game.has_method("get_construction_position"):
        position = game.call(
            "get_construction_position"
        )

    position_label.text = (
        "Konum: X %d  |  Z %d"
        % [roundi(position.x), roundi(position.z)]
    )

    var problem := ""

    if game.has_method("construction_check"):
        problem = str(
            game.call(
                "construction_check",
                kind,
                position
            )
        )

    if problem.is_empty():
        status_label.text = "Konum uygun - Insaat hazir"
        status_label.add_theme_color_override(
            "font_color", GREEN_COLOR
        )
        confirm_button.disabled = false
    else:
        status_label.text = "Uygun degil: " + problem
        status_label.add_theme_color_override(
            "font_color", RED_COLOR
        )
        confirm_button.disabled = true


func _confirm() -> void:
    if not _is_pending():
        return

    _refresh_ui()

    if confirm_button.disabled:
        return

    if game.has_method("confirm_construction"):
        game.call("confirm_construction")

    _refresh_ui()


func _cancel() -> void:
    if not is_instance_valid(game):
        return

    if game.has_method("reject_construction"):
        game.call("reject_construction")

    _refresh_ui()
