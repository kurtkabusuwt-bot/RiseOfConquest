
extends CanvasLayer

# RISE OF CONQUEST
# HERO MENU 2.0 - GODOT 4.4.1

const HEROES := {
	"Osmanlı": [
		"Fatih Sultan Mehmet",
		"Yavuz Sultan Selim",
		"Kanuni Sultan Süleyman",
		"Barbaros Hayreddin Paşa",
		"İdris-i Bitlisî"
	],
	"Roma": [
		"Julius Caesar",
		"Scipio Africanus",
		"Augustus",
		"Marcus Aurelius",
		"Trajan"
	],
	"Viking": [
		"Ragnar Lodbrok",
		"Björn Ironside",
		"Ivar the Boneless",
		"Harald",
		"Lagertha"
	],
	"Moğol": [
		"Cengiz Han",
		"Subutay",
		"Kubilay Han",
		"Cebe Noyan",
		"Batu Han"
	],
	"Çin": [
		"Qin Shi Huang",
		"Guan Yu",
		"Zhuge Liang",
		"Sun Tzu",
		"Hua Mulan"
	],
	"Arabistan": [
		"Halid bin Velid",
		"Selahaddin Eyyubi",
		"Tarık bin Ziyad",
		"Harun Reşid",
		"Amr bin Âs"
	],
	"Alamut": [
		"Hasan Sabbah",
		"Raşidüddin Sinan",
		"Kiyâ Büzürgümmîd",
		"Nûreddin Muhammed II",
		"Rükneddin Hürşah"
	]
}

const LEGENDARY := [
	"Fatih Sultan Mehmet",
	"Yavuz Sultan Selim",
	"Kanuni Sultan Süleyman",
	"Julius Caesar",
	"Augustus",
	"Ragnar Lodbrok",
	"Björn Ironside",
	"Cengiz Han",
	"Subutay",
	"Qin Shi Huang",
	"Guan Yu",
	"Halid bin Velid",
	"Selahaddin Eyyubi",
	"Hasan Sabbah"
]

var progression: Node
var root: Control
var panel: PanelContainer
var hero_button: Button
var list_box: VBoxContainer
var detail_box: VBoxContainer
var message_label: Label

var selected_civ := "Osmanlı"
var selected_hero := "Fatih Sultan Mehmet"


func _ready() -> void:
	layer = 80
	progression = get_node_or_null("../HeroProgression")
	build_ui()


func make_button(
	label_text: String,
	parent: Node,
	callback: Callable
) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(170, 46)
	parent.add_child(button)
	button.pressed.connect(callback)
	return button


func make_label(
	label_text: String,
	parent: Node,
	font_size: int = 20
) -> Label:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override(
		"font_size", font_size
	)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func build_ui() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	hero_button = make_button(
		"KAHRAMANLAR",
		root,
		open_menu
	)
	hero_button.position = Vector2(14, 136)
	hero_button.custom_minimum_size = Vector2(175, 48)

	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	panel.offset_left = 40
	panel.offset_top = 30
	panel.offset_right = -40
	panel.offset_bottom = -30
	root.add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.12, 0.98)
	style.border_color = Color(0.75, 0.55, 0.24)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	var header := HBoxContainer.new()
	outer.add_child(header)

	var title := make_label(
		"KAHRAMANLAR  |  35 KOMUTAN",
		header,
		26
	)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	make_button("KAPAT X", header, close_menu)

	var civ_scroll := ScrollContainer.new()
	civ_scroll.custom_minimum_size.y = 58
	civ_scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)
	outer.add_child(civ_scroll)

	var civ_row := HBoxContainer.new()
	civ_scroll.add_child(civ_row)

	for civ in HEROES.keys():
		var civ_name: String = civ
		make_button(
			civ_name,
			civ_row,
			func() -> void:
				choose_civ(civ_name)
		)

	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(body)

	var hero_scroll := ScrollContainer.new()
	hero_scroll.custom_minimum_size.x = 300
	body.add_child(hero_scroll)

	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_scroll.add_child(list_box)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	body.add_child(detail_scroll)

	detail_box = VBoxContainer.new()
	detail_box.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	detail_box.add_theme_constant_override(
		"separation", 12
	)
	detail_scroll.add_child(detail_box)

	panel.visible = false
	refresh()


func open_menu() -> void:
	progression = get_node_or_null("../HeroProgression")
	panel.visible = true
	hero_button.visible = false
	refresh()


func close_menu() -> void:
	panel.visible = false
	hero_button.visible = true


func choose_civ(civ: String) -> void:
	selected_civ = civ
	selected_hero = HEROES[civ][0]
	refresh()


func choose_hero(hero: String) -> void:
	selected_hero = hero
	refresh_detail()


func refresh() -> void:
	for child in list_box.get_children():
		list_box.remove_child(child)
		child.queue_free()

	for hero in HEROES[selected_civ]:
		var hero_name: String = hero
		var rarity := "NADİR"

		if hero_name in LEGENDARY:
			rarity = "EFSANEVİ"

		make_button(
			hero_name + " | " + rarity,
			list_box,
			func() -> void:
				choose_hero(hero_name)
		)

	refresh_detail()


func refresh_detail() -> void:
	for child in detail_box.get_children():
		detail_box.remove_child(child)
		child.queue_free()

	if progression == null:
		make_label(
			"Geliştirme sistemi bulunamadı.",
			detail_box
		)
		return

	var hero: Dictionary = progression.get_hero(
		selected_hero
	)

	var level := int(hero.get("level", 1))
	var xp := int(hero.get("xp", 0))
	var stars := int(hero.get("stars", 1))
	var points := int(hero.get("skill_points", 0))
	var skills: Array = hero.get(
		"skills", [0, 0, 0, 0]
	)

	var rarity := "NADİR"
	if selected_hero in LEGENDARY:
		rarity = "EFSANEVİ"

	var name_label := make_label(
		selected_hero,
		detail_box,
		30
	)

	if rarity == "EFSANEVİ":
		name_label.add_theme_color_override(
			"font_color",
			Color(1.0, 0.78, 0.32)
		)

	make_label(
		selected_civ + "  |  " + rarity,
		detail_box,
		18
	)

	make_label(
		"SEVİYE: %d / 60" % level,
		detail_box,
		23
	)

	var xp_bar := ProgressBar.new()
	xp_bar.custom_minimum_size.y = 25
	detail_box.add_child(xp_bar)

	if level >= 60:
		xp_bar.max_value = 1
		xp_bar.value = 1
		make_label(
			"MAKSİMUM SEVİYE",
			detail_box
		)
	else:
		var needed: int = progression.xp_needed(level)
		xp_bar.max_value = needed
		xp_bar.value = xp

		make_label(
			"Deneyim: %d / %d" % [xp, needed],
			detail_box,
			17
		)

	make_label(
		"YILDIZ: %d / 6" % stars,
		detail_box,
		22
	)

	make_label(
		"Yetenek puanı: %d" % points,
		detail_box,
		20
	)

	var skill_names := [
		"Aktif Beceri",
		"Pasif Beceri I",
		"Pasif Beceri II",
		"Uzmanlık Becerisi"
	]

	for i in range(4):
		var index := i
		var skill_level := int(skills[i])

		make_button(
			"%s  %d/5  [+]" % [
				skill_names[i], skill_level
			],
			detail_box,
			func() -> void:
				upgrade_skill(index)
		)

	make_button(
		"+100 DENEYİM (TEST)",
		detail_box,
		add_test_xp
	)

	make_button(
		"YILDIZ YÜKSELT",
		detail_box,
		upgrade_star
	)

	message_label = make_label(
		"",
		detail_box,
		18
	)

	make_label(
		"3D kahraman modeli ve gerçek savaş " +
		"ödülleri sonraki güncellemede bağlanacak.",
		detail_box,
		16
	)


func add_test_xp() -> void:
	if progression == null:
		return

	var gained: int = progression.add_xp(
		selected_hero, 100
	)

	refresh_detail()
	show_message(
		"+100 deneyim | %d seviye kazanıldı" % gained
	)


func upgrade_star() -> void:
	if progression == null:
		return

	var success: bool = progression.upgrade_star(
		selected_hero
	)

	refresh_detail()

	if success:
		show_message("Yıldız yükseltildi!")
	else:
		show_message(
			"Yıldız için gereken seviyeye ulaşmalısın."
		)


func upgrade_skill(index: int) -> void:
	if progression == null:
		return

	var success: bool = progression.upgrade_skill(
		selected_hero, index
	)

	refresh_detail()

	if success:
		show_message("Yetenek geliştirildi!")
	else:
		show_message(
			"Yeterli yetenek puanı yok veya beceri maksimum."
		)


func show_message(value: String) -> void:
	if is_instance_valid(message_label):
		message_label.text = value
