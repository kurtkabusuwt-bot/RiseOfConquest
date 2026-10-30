
extends CanvasLayer

# RISE OF CONQUEST - BUILD 91.9
# CITY AND CONSTRUCTION NAVIGATION
# Godot 4.4.1 / Android

const GOLD := Color(0.91, 0.72, 0.39)
const DARK := Color(0.035, 0.065, 0.105, 0.96)
const BUTTON_BG := Color(0.12, 0.19, 0.27, 0.97)

var game: Node
var manager: Node
var root: Control
var bottom_bar: PanelContainer
var action_panel: PanelContainer
var action_title: Label
var action_list: VBoxContainer
var current_tab := ""

func _ready() -> void:
	layer = 95
	call_deferred("_initialize")

func _initialize() -> void:
	game = get_tree().current_scene

	if game == null:
		return

	manager = game.get_node_or_null("MobileUIManager90")
	_build_interface()

func _make_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = GOLD
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(8)
	return style

func _make_button(caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(112, 50)
	button.add_theme_stylebox_override(
		"normal", _make_style(BUTTON_BG)
	)
	button.add_theme_stylebox_override(
		"pressed", _make_style(Color(0.25, 0.34, 0.42))
	)
	button.add_theme_color_override("font_color", GOLD)
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(action)
	return button

func _build_interface() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_bottom_bar()
	_build_action_panel()

func _build_bottom_bar() -> void:
	bottom_bar = PanelContainer.new()
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
	action_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_title.add_theme_font_size_override("font_size", 21)
	action_title.add_theme_color_override("font_color", GOLD)
	header.add_child(action_title)

	header.add_child(_make_button("KAPAT", _close_panel))

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

func _add_section(title_text: String) -> void:
	var label := Label.new()
	label.text = title_text
	label.add_theme_color_override("font_color", GOLD)
	label.add_theme_font_size_override("font_size", 17)
	action_list.add_child(label)

func _add_action(
	caption: String,
	method: String,
	args: Array = []
) -> void:
	var action := func() -> void:
		_close_panel()

		if game != null and game.has_method(method):
			game.callv(method, args)
		else:
			push_warning("Eksik oyun fonksiyonu: " + method)

	action_list.add_child(_make_button(caption, action))

func _add_manager_action(
	caption: String,
	method: String
) -> void:
	var action := func() -> void:
		_close_panel()

		if is_instance_valid(manager) and manager.has_method(method):
			manager.call(method)
		else:
			push_warning("Eksik arayuz fonksiyonu: " + method)

	action_list.add_child(_make_button(caption, action))

func _toggle_building_names() -> void:
	_close_panel()

	var interaction := game.get_node_or_null("CityInteraction")

	if interaction == null:
		return

	var enabled := not bool(interaction.get("names_enabled"))
	interaction.set("names_enabled", enabled)

	var old_button: Variant = interaction.get("names_button")

	if old_button is Button:
		old_button.set_pressed_no_signal(enabled)

	if interaction.has_method("update_labels"):
		interaction.update_labels()

func _open_commanders() -> void:
	_close_panel()

	var war := game.get_node_or_null("WarConquest31")

	if war != null and war.has_method("toggle_commander_panel"):
		war.toggle_commander_panel()

func _open_war_management() -> void:
	_close_panel()

	var war := game.get_node_or_null("WarConquest31")

	if war != null and war.has_method("toggle_panel"):
		war.toggle_panel()

func _open_tab(tab: String) -> void:
	if current_tab == tab and action_panel.visible:
		_close_panel()
		return

	current_tab = tab
	action_title.text = tab
	_clear_actions()

	match tab:
		"SEHIR":
			_add_section("SEHIR KONTROLLERI")
			_add_action("DUNYA / SEHIR", "toggle_world_map")
			_add_action("HUKUMDAR MODU", "toggle_ruler")
			_add_action("GUN / GECE", "toggle_day_night")

			_add_section("GORUNUM")
			action_list.add_child(
				_make_button(
					"BINA ISIMLERINI AC / KAPAT",
					_toggle_building_names
				)
			)
			_add_action("KAMERA YAKINLASTIR", "zoom_camera", [-3.0])
			_add_action("KAMERA UZAKLASTIR", "zoom_camera", [3.0])

		"INSAAT":
			_add_section("YASAM VE ASKERI BINALAR")
			_add_action("EV", "choose_building", ["Ev"])
			_add_action("KISLA", "choose_building", ["Kışla"])
			_add_action("GOZETLEME KULESI", "choose_building", ["Kule"])

			_add_section("URETIM BINALARI")
			_add_action("CIFTLIK", "choose_building", ["Çiftlik"])
			_add_action("KERESTE ATOLYESI", "choose_building", ["Kereste"])
			_add_action("TAS OCAGI", "choose_building", ["Taşocağı"])

			_add_section("YERLESTIRME")
			var hint := Label.new()
			hint.text = (
				"Mevcut binayi tasimak icin "
				"uzerine basili tutup surukleyin."
			)
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			action_list.add_child(hint)

			_add_action(
				"YERLESTIRMEYI IPTAL ET",
				"cancel_placement"
			)

		"ORDU":
			_add_section("ORDU YONETIMI")
			_add_manager_action("ORDU YONETIMI", "open_army")
			_add_action("ORDU GONDER", "send_world_army")
			action_list.add_child(
				_make_button("KOMUTANLAR", _open_commanders)
			)
			_add_action("HEDEF DEGISTIR", "select_next_unit")

		"SAVAS":
			_add_section("SAVAS VE FETIH")
			action_list.add_child(
				_make_button(
					"FETIH YONETIMI",
					_open_war_management
				)
			)
			_add_action("SEHIR SAVASI BASLAT", "start_battle")
			_add_action("SALDIR", "order_attack")
			_add_action("SAVUN", "toggle_hold")
			_add_action("GERI CEKIL", "retreat_battle")

		"MENU":
			_add_section("KRALLIK")
			_add_manager_action("KAHRAMANLAR", "open_heroes")
			_add_manager_action(
				"KRALLIK YONETIMI", "open_kingdom"
			)
			action_list.add_child(
				_make_button("KOMUTANLAR", _open_commanders)
			)

			_add_section("OYUN")
			_add_action("OYUNU KAYDET", "save_game", [true])
			_add_action("GUN / GECE", "toggle_day_night")

	action_panel.visible = true

func _close_panel() -> void:
	if action_panel != null:
		action_panel.visible = false

	current_tab = ""
