
extends CanvasLayer

# RISE OF CONQUEST
# MOBILE RESOURCE HUD
# Android / Godot 4.4

const RESOURCE_PATH := "res://assets/ui/resources/"

const RESOURCE_DATA := [
    {"title": "ALTIN", "file": "gold.png", "key": "coins"},
    {"title": "ODUN", "file": "wood.png", "key": "woods"},
    {"title": "TAS", "file": "stone.png", "key": "stones"},
    {"title": "YIYECEK", "file": "food.png", "key": "foods"},
    {"title": "MUCEVHER", "file": "gems.png", "key": "gems"}
]

const BG_COLOR := Color(0.035, 0.065, 0.105, 0.96)
const GOLD_COLOR := Color(0.91, 0.72, 0.39)
const TEXT_COLOR := Color(0.93, 0.94, 0.96)
const MUTED_COLOR := Color(0.68, 0.74, 0.81)
const GAIN_COLOR := Color(0.38, 0.86, 0.57)

var game: Node
var root: Control
var bar: PanelContainer
var scroll: ScrollContainer
var items: HBoxContainer

var amounts: Dictionary = {}
var production_labels: Dictionary = {}

var refresh_timer := 0.0
var last_screen_size := Vector2.ZERO


func _ready() -> void:
    layer = 90
    game = get_parent()
    _build_ui()
    _update_layout()
    _refresh_values()


func _make_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = BG_COLOR
    style.border_color = GOLD_COLOR
    style.set_border_width_all(1)
    style.set_corner_radius_all(13)
    style.content_margin_left = 8
    style.content_margin_right = 8
    style.content_margin_top = 5
    style.content_margin_bottom = 5
    return style


func _build_ui() -> void:
    root = Control.new()
    root.name = "MobileResourceRoot"
    add_child(root)

    root.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT
    )
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE

    bar = PanelContainer.new()
    bar.name = "ResourceBar"
    root.add_child(bar)
    bar.mouse_filter = Control.MOUSE_FILTER_STOP
    bar.add_theme_stylebox_override(
        "panel", _make_style()
    )

    scroll = ScrollContainer.new()
    scroll.name = "ResourceScroll"
    bar.add_child(scroll)

    scroll.horizontal_scroll_mode = (
        ScrollContainer.SCROLL_MODE_AUTO
    )
    scroll.vertical_scroll_mode = (
        ScrollContainer.SCROLL_MODE_DISABLED
    )
    scroll.size_flags_horizontal = (
        Control.SIZE_EXPAND_FILL
    )

    items = HBoxContainer.new()
    items.name = "ResourceItems"
    scroll.add_child(items)
    items.add_theme_constant_override(
        "separation", 8
    )

    for data in RESOURCE_DATA:
        _add_resource(data)


func _load_resource_icon(file_name: String) -> Texture2D:
    var path := RESOURCE_PATH + file_name

    var resource := load(path)
    if resource is Texture2D:
        return resource as Texture2D

    push_error(
        "RiseOfConquest: Resource icon missing: " + path
    )

    return _create_fallback_icon(file_name)


func _create_fallback_icon(file_name: String) -> Texture2D:
    var image := Image.create(
        64, 64, false, Image.FORMAT_RGBA8
    )

    var color := GOLD_COLOR

    match file_name:
        "gold.png":
            color = Color(1.0, 0.75, 0.15)
        "wood.png":
            color = Color(0.55, 0.32, 0.15)
        "stone.png":
            color = Color(0.62, 0.66, 0.72)
        "food.png":
            color = Color(0.35, 0.78, 0.28)
        "gems.png":
            color = Color(0.25, 0.78, 0.95)

    image.fill(Color.TRANSPARENT)

    for y in range(64):
        for x in range(64):
            var dx := float(x - 32)
            var dy := float(y - 32)
            var distance := sqrt(dx * dx + dy * dy)

            if distance < 27.0:
                var brightness := 1.0 - distance / 90.0
                image.set_pixel(
                    x,
                    y,
                    Color(
                        color.r * brightness,
                        color.g * brightness,
                        color.b * brightness,
                        1.0
                    )
                )

    return ImageTexture.create_from_image(image)


func _add_resource(data: Dictionary) -> void:
    var item := HBoxContainer.new()
    item.custom_minimum_size = Vector2(128, 55)
    item.add_theme_constant_override(
        "separation", 5
    )
    items.add_child(item)

    var icon := TextureRect.new()
    icon.custom_minimum_size = Vector2(34, 34)
    icon.expand_mode = (
        TextureRect.EXPAND_IGNORE_SIZE
    )
    icon.stretch_mode = (
        TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    )
    icon.mouse_filter = (
        Control.MOUSE_FILTER_IGNORE
    )

    icon.texture = _load_resource_icon(
        str(data["file"])
    )

    item.add_child(icon)

    var texts := VBoxContainer.new()
    texts.add_theme_constant_override(
        "separation", 0
    )
    item.add_child(texts)

    var title := Label.new()
    title.text = str(data["title"])
    title.add_theme_font_size_override(
        "font_size", 10
    )
    title.add_theme_color_override(
        "font_color", MUTED_COLOR
    )
    texts.add_child(title)

    var amount := Label.new()
    amount.text = "0"
    amount.add_theme_font_size_override(
        "font_size", 17
    )
    amount.add_theme_color_override(
        "font_color", TEXT_COLOR
    )
    texts.add_child(amount)

    var production := Label.new()
    production.text = "+0/dk"
    production.add_theme_font_size_override(
        "font_size", 11
    )
    production.add_theme_color_override(
        "font_color", GAIN_COLOR
    )
    texts.add_child(production)

    var key := str(data["key"])
    amounts[key] = amount
    production_labels[key] = production


func _process(delta: float) -> void:
    refresh_timer += delta

    if refresh_timer >= 0.5:
        refresh_timer = 0.0
        _refresh_values()

    var screen_size := (
        get_viewport().get_visible_rect().size
    )

    if screen_size != last_screen_size:
        _update_layout()


func _update_layout() -> void:
    if not is_instance_valid(bar):
        return

    var size := (
        get_viewport().get_visible_rect().size
    )
    last_screen_size = size

    bar.set_anchors_preset(
        Control.PRESET_TOP_WIDE
    )
    bar.offset_left = 8
    bar.offset_right = -8
    bar.offset_top = 8
    bar.offset_bottom = 82

    var compact := size.x < 600.0

    if compact:
        bar.offset_bottom = 76
        items.add_theme_constant_override(
            "separation", 5
        )
    else:
        items.add_theme_constant_override(
            "separation", 8
        )

    for child in items.get_children():
        if child is HBoxContainer:
            if compact:
                child.custom_minimum_size = (
                    Vector2(116, 53)
                )
            else:
                child.custom_minimum_size = (
                    Vector2(128, 55)
                )


func _refresh_values() -> void:
    if not is_instance_valid(game):
        game = get_parent()

    if not is_instance_valid(game):
        return

    var rates := _get_production_rates()

    for data in RESOURCE_DATA:
        var key := str(data["key"])
        var label := amounts.get(key) as Label
        var production := (
            production_labels.get(key) as Label
        )

        if is_instance_valid(label):
            var value := _read_resource(key)
            var formatted := _format_amount(value)

            if label.text != formatted:
                label.text = formatted

        if not is_instance_valid(production):
            continue

        if key == "gems":
            production.text = "URETIM YOK"
            production.add_theme_color_override(
                "font_color", MUTED_COLOR
            )
            continue

        var rate := int(rates.get(key, 0))
        var production_text := (
            "+" + _format_amount(rate) + "/dk"
        )

        if production.text != production_text:
            production.text = production_text


func _get_production_rates() -> Dictionary:
    if not is_instance_valid(game):
        return {}

    if game.has_method(
        "get_resource_production_per_minute"
    ):
        var result: Variant = game.call(
            "get_resource_production_per_minute"
        )

        if result is Dictionary:
            return result

    var houses := _read_resource("house_count")
    var lumber := _read_resource("lumber_count")
    var mines := _read_resource("mine_count")
    var farms := _read_resource("farm_count")

    return {
        "coins": (houses * 3 + 1) * 12,
        "woods": (lumber * 8 + 2) * 12,
        "stones": mines * 6 * 12,
        "foods": (farms * 10 + 2) * 12,
        "gems": 0
    }


func _read_resource(key: String) -> int:
    if not is_instance_valid(game):
        return 0

    for property in game.get_property_list():
        if str(property.get("name", "")) == key:
            return int(game.get(key))

    return 0


func _format_amount(value: int) -> String:
    var negative := value < 0
    var number := abs(value)
    var result := ""

    if number >= 1000000000:
        result = "%.1fB" % (
            float(number) / 1000000000.0
        )
    elif number >= 1000000:
        result = "%.1fM" % (
            float(number) / 1000000.0
        )
    elif number >= 10000:
        result = "%.1fK" % (
            float(number) / 1000.0
        )
    else:
        result = str(number)

    if negative:
        return "-" + result

    return result
