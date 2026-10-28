
extends CanvasLayer

# Rise of Conquest 1.5 - Mobile interface
# Keeps the existing 1.4 gameplay and saves.

var game: Node
var expansion: Node
var panel: PanelContainer
var stats: Label
var message: Label
var content: VBoxContainer
var active_tab := "Kale"

func _ready() -> void:
	layer = 25
	call_deferred("setup")

func setup() -> void:
	game = get_tree().current_scene
	expansion = game.get_node_or_null("ConquestExpansion")
	if expansion == null:
		push_warning("ConquestExpansion bulunamadi")
		return

	create_interface()

	if expansion.panel != null:
		expansion.panel.visible = false
		var old_root = expansion.panel.get_parent()
		for child in old_root.get_children():
			if child is Button:
				child.visible = false

	show_tab("Kale")

func create_interface() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var open_button := Button.new()
	open_button.text = "KALE 1.5"
	open_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	open_button.offset_left = -190
	open_button.offset_right = -12
	open_button.offset_top = 55
	open_button.offset_bottom = 110
	root.add_child(open_button)

	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -420
	panel.offset_right = 420
	panel.offset_top = -280
	panel.offset_bottom = 280
	root.add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.12, 0.97)
	style.border_color = Color(0.75, 0.60, 0.32)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	var title := Label.new()
	title.text = "RISE OF CONQUEST 1.5"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "KAPAT"
	header.add_child(close_button)
	close_button.pressed.connect(func(): panel.visible = false)

	var navigation := HBoxContainer.new()
	layout.add_child(navigation)

	for tab in ["Kale", "Binalar", "Ordu", "Harita", "Gorevler"]:
		var button := Button.new()
		button.text = tab
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 48)
		navigation.add_child(button)
		button.pressed.connect(show_tab.bind(tab))

	stats = Label.new()
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(stats)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)

	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(message)

	panel.visible = false

	open_button.pressed.connect(func():
		panel.visible = not panel.visible
		if panel.visible:
			show_tab(active_tab)
	)

func add_button(label_text: String, method: String, argument: String = "") -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0, 55)
	content.add_child(button)

	button.pressed.connect(func():
		if argument == "":
			expansion.call(method)
		else:
			expansion.call(method, argument)
		refresh()
	)

func add_note(value: String) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(label)

func show_tab(tab: String) -> void:
	active_tab = tab

	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

	match tab:
		"Kale":
			add_note("Kralligini gelistir ve kaleni guclendir.")
			add_button("KALEYI YUKSELT", "upgrade_castle")
			add_button("ILERLEMEYI KAYDET", "save_expansion_button")

		"Binalar":
			add_note("Sehirdeki binalarini gelistir.")
			add_button("EV GELISTIR", "upgrade_building", "Ev")
			add_button("KISLA GELISTIR", "upgrade_building", "Kışla")
			add_button("CIFTLIK GELISTIR", "upgrade_building", "Çiftlik")
			add_button("KERESTE GELISTIR", "upgrade_building", "Kereste")
			add_button("TASOCAGI GELISTIR", "upgrade_building", "Taşocağı")

		"Ordu":
			add_note("Asker egit, ordunu guclendir ve savas.")
			add_button("5 PIYADE EGIT", "train", "infantry")
			add_button("5 OKCU EGIT", "train", "archers")
			add_button("3 SUVARI EGIT", "train", "cavalry")
			add_button("CATISMA BASLAT", "start_skirmish")

		"Harita":
			add_note("Yeni bolgeler kesfet ve sefere cik.")
			add_button("KESIF YAP", "scout")
			add_button("SEFER BASLAT", "start_expedition")

		"Gorevler":
			add_note("Gorevleri tamamla ve odullerini al.")
			add_button("GOREV ODULUNU AL", "claim_quest")

	refresh()

func save_expansion_button() -> void:
	expansion.save_expansion(true)
	refresh()

func refresh() -> void:
	if stats == null or expansion == null:
		return

	stats.text = "KALE %d | ORDU GUCU %d\nPIYADE %d | OKCU %d | SUVARI %d\nALTIN %d | ODUN %d | TAS %d | YIYECEK %d" % [
		int(expansion.castle_level),
		int(expansion.army_power()),
		int(expansion.infantry),
		int(expansion.archers),
		int(expansion.cavalry),
		int(game.get("coins")),
		int(game.get("woods")),
		int(game.get("stones")),
		int(game.get("foods"))
	]

	var quest_text := ""
	if expansion.quest_label != null:
		quest_text = expansion.quest_label.text

	message.text = quest_text + "\nDURUM: " + str(expansion.notice)

func _process(_delta: float) -> void:
	if panel != null and panel.visible:
		refresh()
