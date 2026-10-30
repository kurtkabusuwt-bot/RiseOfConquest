
extends CanvasLayer

# RISE OF CONQUEST - BUILD 90
# Mobile Resource Bar
# Godot 4.4.1 / Android

const RESOURCE_PATH := "res://assets/ui/resources/"

const RESOURCE_DATA := [
	{"title": "Altin", "file": "gold.png", "key": "coins"},
	{"title": "Odun", "file": "wood.png", "key": "woods"},
	{"title": "Tas", "file": "stone.png", "key": "stones"},
	{"title": "Yiyecek", "file": "food.png", "key": "foods"},
	{"title": "Mucevher", "file": "gems.png", "key": "gems"}
]

var game: Node
var root: Control
var bar: PanelContainer
var amounts: Dictionary = {}
var refresh_timer: float = 0.0

func _ready() -> void:
	layer = 90
	game = get_tree().current_scene
	_build_ui()
	_refresh_values()

func _build_ui() -> void:
	root = Control.new()
	root.name = "MobileResourceRoot"
	root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	bar = PanelContainer.new()
	bar.name = "ResourceBar"
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 12
	bar.offset_top = 12
	bar.offset_right = -12
	bar.offset_bottom = 78
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(bar)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.065, 0.105, 0.92)
	style.border_color = Color(0.72, 0.55, 0.27)
	style.set_border_width_all(1)
	style.set_corner_radius_all(13)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	bar.add_theme_stylebox_override("panel", style)

	var scroll := ScrollContainer.new()
	scroll.name = "ResourceScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(scroll)

	var items := HBoxContainer.new()
	items.name = "ResourceItems"
	items.add_theme_constant_override("separation", 14)
	scroll.add_child(items)

	for data in RESOURCE_DATA:
		_add_resource(items, data)

func _add_resource(parent: HBoxContainer, data: Dictionary) -> void:
	var item := HBoxContainer.new()
	item.custom_minimum_size = Vector2(135, 48)
	item.add_theme_constant_override("separation", 5)
	parent.add_child(item)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(43, 43)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var path: String = RESOURCE_PATH + str(data["file"])
	if ResourceLoader.exists(path):
		icon.texture = load(path)

	item.add_child(icon)

	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 0)
	item.add_child(texts)

	var title := Label.new()
	title.text = str(data["title"])
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override(
		"font_color",
		Color(0.77, 0.80, 0.86)
	)
	texts.add_child(title)

	var amount := Label.new()
	amount.text = "0"
	amount.add_theme_font_size_override("font_size", 19)
	amount.add_theme_color_override(
		"font_color",
		Color(1.0, 0.90, 0.65)
	)
	texts.add_child(amount)

	amounts[str(data["key"])] = amount

func _process(delta: float) -> void:
	refresh_timer += delta
	if refresh_timer >= 0.3:
		refresh_timer = 0.0
		_refresh_values()

func _refresh_values() -> void:
	if not is_instance_valid(game):
		game = get_tree().current_scene

	if game == null:
		return

	for data in RESOURCE_DATA:
		var key: String = str(data["key"])
		var label: Label = amounts.get(key)

		if label == null:
			continue

		var value := _read_resource(key)
		label.text = _format_amount(value)

func _read_resource(key: String) -> int:
	if game == null:
		return 0

	for property in game.get_property_list():
		if str(property.get("name", "")) == key:
			return int(game.get(key))

	return 0

func _format_amount(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (float(value) / 1000000.0)
	if value >= 10000:
		return "%.1fK" % (float(value) / 1000.0)
	return str(value)
