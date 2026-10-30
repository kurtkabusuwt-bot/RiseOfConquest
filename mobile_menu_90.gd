
extends CanvasLayer

# RISE OF CONQUEST - BUILD 90.2
# CLEAN MOBILE MAIN MENU
# Godot 4.4.1 / Android

var game: Node3D
var root: Control
var bottom_bar: PanelContainer
var action_panel: PanelContainer
var action_title: Label
var action_list: VBoxContainer
var current_tab: String = ""

const GOLD := Color(0.91, 0.72, 0.39)
const DARK := Color(0.035, 0.065, 0.105, 0.95)
const BUTTON_BG := Color(0.12, 0.19, 0.27, 0.97)

func _ready() -> void:
	layer = 80
	call_deferred("_initialize")

func _initialize() -> void:
	game = get_tree().current_scene as Node3D
	if game == null:
		return
	_build_interface()

func _make_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = GOLD
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _make_button(text_value: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(110, 52)
	button.add_theme_stylebox_override(
		"normal", _make_style(BUTTON_BG)
	)
	button.add_theme_stylebox_override(
		"pressed", _make_style(Color(0.25, 0.34, 0.42))
	)
	button.add_theme_color_override("font_color", GOLD)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(action)
	return button

func _build_interface() -> void:
	root = Control.new()
	root.name = "CleanMobileUI"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_bottom_bar()
	_build_action_panel()

func _build_bottom_bar() -> void:
	bottom_bar = PanelContainer.new()
	bottom_bar.name = "MobileBottomBar"
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.offset_left = 8
	bottom_bar.offset_right = -8
	bottom_bar.offset_top = -83
	bottom_bar.offset_bottom = -8
	bottom_bar.add_theme_stylebox_override(
		"panel", _make_style(DARK)
	)
	root.add_child(bottom_bar)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bottom_bar.add_child(scroll)

	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 8)
	scroll.add_child(navigation)

	for tab in ["SEHIR", "INSAAT", "ORDU", "SAVAS", "MENU"]:
		navigation.add_child(
			_make_button(tab, _open_tab.bind(tab))
		)

func _build_action_panel() -> void:
	action_panel = PanelContainer.new()
	action_panel.name = "MobileActionPanel"
	action_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	action_panel.offset_left = 12
	action_panel.offset_right = -12
	action_panel.offset_top = 100
	action_panel.offset_bottom = -95
	action_panel.add_theme_stylebox_override(
		"panel", _make_style(DARK)
	)
	root.add_child(action_panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	action_panel.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	action_title = Label.new()
	action_title.text = "RISE OF CONQUEST"
	action_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_title.add_theme_font_size_override("font_size", 22)
	action_title.add_theme_color_override("font_color", GOLD)
	header.add_child(action_title)

	header.add_child(
		_make_button("KAPAT", _close_panel)
	)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	action_list = VBoxContainer.new()
	action_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_list.add_theme_constant_override("separation", 8)
	scroll.add_child(action_list)

	action_panel.visible = false

func _clear_actions() -> void:
	for child in action_list.get_children():
		action_list.remove_child(child)
		child.queue_free()

func _add_action(title: String, method: String, args: Array = []) -> void:
	var action := func() -> void:
		if game != null and game.has_method(method):
			game.callv(method, args)
			_close_panel()
		else:
			push_warning("Eksik oyun fonksiyonu: " + method)

	action_list.add_child(_make_button(title, action))

func _open_tab(tab: String) -> void:
	if current_tab == tab and action_panel.visible:
		_close_panel()
		return

	current_tab = tab
	action_title.text = tab
	_clear_actions()

	match tab:
		"SEHIR":
			_add_action("DUNYA / SEHIR", "toggle_world_map")
			_add_action("HUKUMDAR", "toggle_ruler")
			_add_action("GUN / GECE", "toggle_day_night")
			_add_action("KAMERA YAKIN", "zoom_camera", [-3.0])
			_add_action("KAMERA UZAK", "zoom_camera", [3.0])

		"INSAAT":
			_add_action("EV", "choose_building", ["Ev"])
			_add_action("KISLA", "choose_building", ["Kışla"])
			_add_action("CIFTLIK", "choose_building", ["Çiftlik"])
			_add_action("KERESTE", "choose_building", ["Kereste"])
			_add_action("TASOCAGI", "choose_building", ["Taşocağı"])
			_add_action("KULE", "choose_building", ["Kule"])
			_add_action("YERLESTIRME IPTAL", "cancel_placement")

		"ORDU":
			_add_action("ORDU GONDER", "send_world_army")
			_add_action("HEDEF DEGISTIR", "select_next_unit")
			_add_action("SALDIR", "order_attack")
			_add_action("SAVUN", "toggle_hold")
			_add_action("GERI CEKIL", "retreat_battle")

		"SAVAS":
			_add_action("SAVAS BASLAT", "start_battle")
			_add_action("SALDIR", "order_attack")
			_add_action("SAVUN", "toggle_hold")
			_add_action("GERI CEKIL", "retreat_battle")

		"MENU":
			_add_action("OYUNU KAYDET", "save_game", [true])
			_add_action("DUNYA HARITASI", "toggle_world_map")
			_add_action("GUN / GECE", "toggle_day_night")

	action_panel.visible = true

func _close_panel() -> void:
	action_panel.visible = false
	current_tab = ""
