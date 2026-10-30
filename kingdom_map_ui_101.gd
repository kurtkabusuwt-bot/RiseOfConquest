extends CanvasLayer
# Build 101: playable prototype map inspection UI; local simulation only.
const MAP_SIZE := 1200
const GRID := 21
var panel: PanelContainer
var canvas: Control
var coordinate_label: Label
var center := Vector2i(600, 600)
var zoom := 1
var noise := FastNoiseLite.new()
var active := false
func _ready() -> void:
    layer = 45
    noise.seed = 100100
    noise.frequency = 0.015
    _build_ui()
func _build_ui() -> void:
    var button := Button.new()
    button.text = "KRALLIK"
    button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    button.position = Vector2(-152, 72)
    button.size = Vector2(140, 54)
    add_child(button)
    button.pressed.connect(_toggle)
    panel = PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.visible = false
    add_child(panel)
    var body := VBoxContainer.new()
    panel.add_child(body)
    var toolbar := HBoxContainer.new()
    body.add_child(toolbar)
    var close := Button.new()
    close.text = "KAPAT"
    toolbar.add_child(close)
    close.pressed.connect(_toggle)
    coordinate_label = Label.new()
    coordinate_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    toolbar.add_child(coordinate_label)
    var minus := Button.new()
    minus.text = "-"
    toolbar.add_child(minus)
    minus.pressed.connect(_zoom_out)
    var plus := Button.new()
    plus.text = "+"
    toolbar.add_child(plus)
    plus.pressed.connect(_zoom_in)
    canvas = Control.new()
    canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
    canvas.mouse_filter = Control.MOUSE_FILTER_STOP
    body.add_child(canvas)
    canvas.draw.connect(_draw_map)
    canvas.gui_input.connect(_map_input)
    var nav := HBoxContainer.new()
    body.add_child(nav)
    for direction in ["BATI", "KUZEY", "GUNEY", "DOGU"]:
        var nav_button := Button.new()
        nav_button.text = direction
        nav_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        nav.add_child(nav_button)
        nav_button.pressed.connect(_move.bind(direction))
    _refresh()
func _toggle() -> void:
    active = not active
    panel.visible = active
    if active:
        _refresh()
func _zoom_in() -> void:
    zoom = maxi(1, zoom / 2)
    _refresh()
func _zoom_out() -> void:
    zoom = mini(32, zoom * 2)
    _refresh()
func _move(direction: String) -> void:
    var step := GRID * zoom / 2
    match direction:
        "BATI": center.x -= step
        "DOGU": center.x += step
        "KUZEY": center.y -= step
        "GUNEY": center.y += step
    center.x = clampi(center.x, 0, MAP_SIZE - 1)
    center.y = clampi(center.y, 0, MAP_SIZE - 1)
    _refresh()
func _refresh() -> void:
    coordinate_label.text = "KRALLIK 1001 | X:%d Y:%d | x%d" % [center.x, center.y, zoom]
    if canvas != null:
        canvas.queue_redraw()
func _terrain_color(x: int, y: int) -> Color:
    if x < 0 or y < 0 or x >= MAP_SIZE or y >= MAP_SIZE:
        return Color(0.04, 0.06, 0.08)
    var n := noise.get_noise_2d(float(x), float(y))
    if n < -0.33:
        return Color(0.12, 0.27, 0.48)
    if n > 0.43:
        return Color(0.45, 0.44, 0.41)
    if n > 0.20:
        return Color(0.18, 0.34, 0.18)
    if n < -0.12:
        return Color(0.62, 0.55, 0.36)
    return Color(0.35, 0.49, 0.27)
func _draw_map() -> void:
    var side := minf(canvas.size.x, canvas.size.y)
    if side <= 0.0:
        return
    var cell := side / float(GRID)
    var origin := Vector2((canvas.size.x - side) * 0.5, (canvas.size.y - side) * 0.5)
    for y in range(GRID):
        for x in range(GRID):
            var wx := center.x + (x - GRID / 2) * zoom
            var wy := center.y + (y - GRID / 2) * zoom
            canvas.draw_rect(Rect2(origin + Vector2(x, y) * cell, Vector2(cell + 0.5, cell + 0.5)), _terrain_color(wx, wy))
    var city_pos := Vector2i(600, 600)
    var dx := float(city_pos.x - center.x) / float(zoom)
    var dy := float(city_pos.y - center.y) / float(zoom)
    if absf(dx) <= float(GRID / 2) and absf(dy) <= float(GRID / 2):
        var p := origin + Vector2(dx + float(GRID) * 0.5, dy + float(GRID) * 0.5) * cell
        canvas.draw_circle(p, maxf(4.0, cell * 0.4), Color(0.95, 0.77, 0.25))
    canvas.draw_rect(Rect2(origin, Vector2(side, side)), Color(0.9, 0.8, 0.6), false, 2.0)
func _map_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        var side := minf(canvas.size.x, canvas.size.y)
        if side <= 0.0:
            return
        var origin := Vector2((canvas.size.x - side) * 0.5, (canvas.size.y - side) * 0.5)
        var local := event.position - origin
        if local.x < 0 or local.y < 0 or local.x >= side or local.y >= side:
            return
        var tile := Vector2i(floori(local.x / (side / GRID)), floori(local.y / (side / GRID)))
        center.x = clampi(center.x + (tile.x - GRID / 2) * zoom, 0, MAP_SIZE - 1)
        center.y = clampi(center.y + (tile.y - GRID / 2) * zoom, 0, MAP_SIZE - 1)
        _refresh()
