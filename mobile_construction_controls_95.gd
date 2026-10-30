
extends CanvasLayer

# RISE OF CONQUEST - BUILD 95.2
# MOBILE CONSTRUCTION CONFIRMATION
# Godot 4.4.1 / Android

const PANEL_COLOR := Color(0.035, 0.065, 0.105, 0.96)
const GOLD_COLOR := Color(0.91, 0.72, 0.39)
const TEXT_COLOR := Color(0.95, 0.95, 0.96)

var game: Node
var panel: PanelContainer
var title_label: Label
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


func _build_ui() -> void:
    panel = PanelContainer.new()
    panel.name = "ConstructionConfirmPanel"

    add_child(panel)

    panel.set_anchors_preset(
        Control.PRESET_CENTER_BOTTOM
    )

    panel.custom_minimum_size = Vector2(310, 112)

    panel.offset_left = -155
    panel.offset_right = 155
    panel.offset_top = -155
    panel.offset_bottom = -43

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
        "separation", 7
    )

    panel.add_child(layout)

    title_label = Label.new()
    title_label.text = "INSAAT ONAYI"
    title_label.horizontal_alignment = (
        HORIZONTAL_ALIGNMENT_CENTER
    )

    title_label.add_theme_color_override(
        "font_color", GOLD_COLOR
    )

    title_label.add_theme_font_size_override(
        "font_size", 17
    )

    layout.add_child(title_label)

    status_label = Label.new()
    status_label.text = "Bina konumu secildi"
    status_label.horizontal_alignment = (
        HORIZONTAL_ALIGNMENT_CENTER
    )

    status_label.add_theme_color_override(
        "font_color", TEXT_COLOR
    )

    layout.add_child(status_label)

    var buttons := HBoxContainer.new()
    buttons.add_theme_constant_override(
        "separation", 10
    )

    layout.add_child(buttons)

    confirm_button = Button.new()
    confirm_button.text = "INSA ET"
    confirm_button.custom_minimum_size = Vector2(135, 40)
    confirm_button.pressed.connect(_confirm)

    buttons.add_child(confirm_button)

    cancel_button = Button.new()
    cancel_button.text = "IPTAL"
    cancel_button.custom_minimum_size = Vector2(135, 40)
    cancel_button.pressed.connect(_cancel)

    buttons.add_child(cancel_button)

    panel.visible = false


func _process(delta: float) -> void:
    refresh_elapsed += delta

    if refresh_elapsed < 0.15:
        return

    refresh_elapsed = 0.0
    _refresh_ui()


func _refresh_ui() -> void:
    if not is_instance_valid(game):
        panel.visible = false
        return

    if not game.has_method(
        "get_construction_pending"
    ):
        panel.visible = false
        return

    var pending := bool(
        game.call("get_construction_pending")
    )

    panel.visible = pending

    if not pending:
        return

    var kind := str(game.get("selected_building"))

    title_label.text = "INSAAT ONAYI"
    status_label.text = kind + " - Konum secildi"


func _confirm() -> void:
    if not is_instance_valid(game):
        return

    if not game.has_method(
        "get_construction_pending"
    ):
        return

    if not bool(
        game.call("get_construction_pending")
    ):
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
