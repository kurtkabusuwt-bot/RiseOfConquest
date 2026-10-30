
extends CanvasLayer

# RISE OF CONQUEST - BUILD 94.0
# PREMIUM RESPONSIVE RESOURCE BAR
# Godot 4.4.1 / Android

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

var game: Node
var root: Control
var bar: PanelContainer
var scroll: ScrollContainer
var items: HBoxContainer

var amounts: Dictionary = {}
var refresh_timer := 0.0
var last_screen_size := Vector2.ZERO

func _ready() -> void:
	layer = 90
	game = get_parent()
	_build_ui()
	_update_layout()
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
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.add_theme_stylebox_override(
		"panel", _make_style()
	)
	root.add_child(bar)

	scroll = ScrollContainer.new()
	scroll.name = "ResourceScroll"
	scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)
	scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)
	scroll.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	bar.add_child(scroll)

	items = HBoxContainer.new()
	items.name = "ResourceItems"
	items.add_theme_constant_override(
		"separation", 8
	)
	scroll.add_child(items)

	for data in RESOURCE_DATA:
		_add_resource(items, data)

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

func _add_resource(
	parent: HBoxContainer,
	data: Dictionary
) -> void:
	var item := HBoxContainer.new()
	item.custom_minimum_size = Vector2(116, 46)
	item.add_theme_constant_override(
		"separation", 5
	)
	parent.add_child(item)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)
	icon.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	icon.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	var path := RESOURCE_PATH + str(data["file"])

	if ResourceLoader.exists(path):
		icon.texture = load(path)

	item.add_child(icon)

	var texts := VBoxContainer.new()
	texts.add_theme_constant_override(
		"separation", 0
	)
	item.add_child(texts)

	var title := Label.new()
	title.text = str(data["title"])
	title.add_theme_font_size_override(
		"font_size", 11
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

	amounts[str(data["key"])] = amount

func _process(delta: float) -> void:
	refresh_timer += delta

	if refresh_timer >= 0.25:
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
	bar.offset_bottom = 68

	var compact := size.x < 600.0

	if compact:
		bar.offset_bottom = 62
		items.add_theme_constant_override(
			"separation", 5
		)
	else:
		items.add_theme_constant_override(
			"separation", 8
		)

	for child in items.get_children():
		if child is HBoxContainer:
			child.custom_minimum_size = (
				Vector2(105, 42)
				if compact
				else Vector2(116, 46)
			)

func _refresh_values() -> void:
	if not is_instance_valid(game):
		game = get_parent()

	if not is_instance_valid(game):
		return

	for data in RESOURCE_DATA:
		var key := str(data["key"])
		var label := amounts.get(key) as Label

		if not is_instance_valid(label):
			continue

		var value := _read_resource(key)
		var formatted := _format_amount(value)

		if label.text != formatted:
			label.text = formatted

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
