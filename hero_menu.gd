
extends CanvasLayer

# RISE OF CONQUEST
# HERO MENU 1.0 - GODOT 4.4.1

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

var root: Control
var panel: PanelContainer
var list_box: VBoxContainer
var detail: RichTextLabel
var hero_button: Button

var selected_civ := "Osmanlı"
var selected_hero := "Fatih Sultan Mehmet"


func _ready() -> void:
	layer = 80
	build_ui()


func make_button(
	label_text: String,
	parent: Node,
	callback: Callable
) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(150, 46)
	parent.add_child(button)
	button.pressed.connect(callback)
	return button


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
	panel.offset_left = 42
	panel.offset_top = 35
	panel.offset_right = -42
	panel.offset_bottom = -35
	root.add_child(panel)

	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.055, 0.075, 0.12, 0.97)
	background.border_color = Color(0.7, 0.53, 0.23)
	background.set_border_width_all(3)
	background.set_corner_radius_all(12)
	panel.add_theme_stylebox_override(
		"panel",
		background
	)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	panel.add_child(outer)

	var header := HBoxContainer.new()
	outer.add_child(header)

	var title := Label.new()
	title.text = "KAHRAMANLAR  -  35 KOMUTAN"
	title.add_theme_font_size_override(
		"font_size", 28
	)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	make_button(
		"KAPAT  X",
		header,
		close_menu
	)

	var civ_scroll := ScrollContainer.new()
	civ_scroll.custom_minimum_size.y = 60
	civ_scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)
	outer.add_child(civ_scroll)

	var civ_row := HBoxContainer.new()
	civ_scroll.add_child(civ_row)

	for civ in HEROES.keys():
		var civilization: String = civ
		make_button(
			civilization,
			civ_row,
			func() -> void:
				choose_civ(civilization)
		)

	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(body)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 320
	body.add_child(scroll)

	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_box)

	detail = RichTextLabel.new()
	detail.bbcode_enabled = true
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_theme_font_size_override(
		"normal_font_size", 22
	)
	body.add_child(detail)

	panel.visible = false
	refresh()


func open_menu() -> void:
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
	if list_box == null:
		return

	for child in list_box.get_children():
		child.queue_free()

	for hero in HEROES[selected_civ]:
		var hero_name: String = hero
		var rarity := (
			"EFSANEVİ"
			if hero_name in LEGENDARY
			else "NADİR"
		)

		make_button(
			hero_name + "  |  " + rarity,
			list_box,
			func() -> void:
				choose_hero(hero_name)
		)

	refresh_detail()


func refresh_detail() -> void:
	var rarity := (
		"EFSANEVİ"
		if selected_hero in LEGENDARY
		else "NADİR"
	)

	var color := (
		"#f5cc68"
		if selected_hero in LEGENDARY
		else "#88c6f5"
	)

	detail.text = (
		"[center][font_size=32][color=%s]%s" +
		"[/color][/font_size][/center]\n\n"
	) % [color, selected_hero]

	detail.text += (
		"[center]%s  -  %s[/center]\n\n"
	) % [selected_civ, rarity]

	detail.text += "SEVİYE  1 / 60\n\n"
	detail.text += "YILDIZ  ☆ ☆ ☆ ☆ ☆ ☆\n\n"
	detail.text += "YETENEKLER\n"
	detail.text += "  - Aktif beceri: Yakında\n"
	detail.text += "  - Pasif beceriler: Yakında\n\n"
	detail.text += "EKİPMAN\n"
	detail.text += "  - Henüz donatılmadı\n\n"
	detail.text += "3D KAHRAMAN MODELİ\n"
	detail.text += "  - Model hazır olduğunda gösterilecek\n\n"
	detail.text += (
		"[color=#aab5c7]Bu sürüm koleksiyon " +
		"menüsüdür. Seviye, yetenek ve ekipman " +
		"geliştirmesi sonraki aşamada " +
		"etkinleştirilecek.[/color]"
	)
