
extends CanvasLayer

# RISE OF CONQUEST - BUILD 95.7
# CONSTRUCTION RESULT NOTIFICATIONS
# Godot 4.4.1 / Android

const SUCCESS_COLOR := Color(0.08, 0.38, 0.22, 0.96)
const ERROR_COLOR := Color(0.55, 0.12, 0.14, 0.96)
const BORDER_COLOR := Color(0.90, 0.72, 0.38)
const DISPLAY_SECONDS := 3.0

var game: Node
var panel: PanelContainer
var message_label: Label

var display_time := 0.0
var last_status := ""
var initialized := false


func _ready() -> void:
    layer = 110
    game = get_parent()

    _create_interface()

    if is_instance_valid(game):
        last_status = str(game.get("status"))

    initialized = true
    set_process(true)

    print("ROC BUILD 95.7: Notifications ready")


func _create_interface() -> void:
    panel = PanelContainer.new()
    panel.name = "ConstructionNotification"

    add_child(panel)

    panel.set_anchors_preset(
        Control.PRESET_CENTER_TOP
    )

    panel.custom_minimum_size = Vector2(300, 65)

    panel.offset_left = -150
    panel.offset_right = 150
    panel.offset_top = 65
    panel.offset_bottom = 130

    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var style := StyleBoxFlat.new()
    style.bg_color = SUCCESS_COLOR
    style.border_color = BORDER_COLOR
    style.set_border_width_all(2)
    style.set_corner_radius_all(12)
    style.set_content_margin_all(12)

    panel.add_theme_stylebox_override(
        "panel", style
    )

    message_label = Label.new()
    message_label.name = "NotificationText"

    message_label.text = ""
    message_label.horizontal_alignment = (
        HORIZONTAL_ALIGNMENT_CENTER
    )
    message_label.vertical_alignment = (
        VERTICAL_ALIGNMENT_CENTER
    )

    message_label.autowrap_mode = (
        TextServer.AUTOWRAP_WORD_SMART
    )

    message_label.mouse_filter = (
        Control.MOUSE_FILTER_IGNORE
    )

    message_label.add_theme_font_size_override(
        "font_size", 16
    )

    message_label.add_theme_color_override(
        "font_color", Color.WHITE
    )

    panel.add_child(message_label)
    panel.visible = false


func _process(delta: float) -> void:
    if display_time > 0.0:
        display_time -= delta

        if display_time <= 0.0:
            panel.visible = false

    if not initialized:
        return

    if not is_instance_valid(game):
        return

    var current_status := str(game.get("status"))

    if current_status == last_status:
        return

    last_status = current_status
    _handle_status(current_status)


func _handle_status(message: String) -> void:
    var lower_message := message.to_lower()

    if (
        lower_message.contains("insa edildi!")
        or lower_message.contains("inşa edildi!")
    ):
        show_success(message)
        return

    if (
        lower_message.contains("yeterli odun yok")
        or lower_message.contains("yeterli altin yok")
        or lower_message.contains("yeterli altın yok")
        or lower_message.contains("bina cok yakin")
        or lower_message.contains("bina çok yakın")
        or lower_message.contains("sehir siniri disinda")
        or lower_message.contains("şehir sınırı dışında")
        or lower_message.contains("gecersiz bina turu")
        or lower_message.contains("geçersiz bina türü")
    ):
        show_error(message)


func show_success(message: String) -> void:
    _show_notification(
        message,
        SUCCESS_COLOR
    )


func show_error(message: String) -> void:
    _show_notification(
        message,
        ERROR_COLOR
    )


func _show_notification(
    message: String,
    background_color: Color
) -> void:
    if not is_instance_valid(panel):
        return

    message_label.text = message

    var style := panel.get_theme_stylebox(
        "panel"
    ).duplicate() as StyleBoxFlat

    style.bg_color = background_color

    panel.add_theme_stylebox_override(
        "panel", style
    )

    display_time = DISPLAY_SECONDS
    panel.visible = true
