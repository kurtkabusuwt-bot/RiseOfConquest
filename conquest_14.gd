extends Node
# Rise of Conquest 1.4 - additive gameplay expansion.
# Existing city, battles, map and save remain in main.gd.

const SAVE_FILE := "user://roc_expansion_14.json"
var game: Node3D
var panel: PanelContainer
var summary: Label
var log_label: Label
var quest_label: Label
var castle_level := 1
var building_levels := {"Ev": 1, "Kışla": 1, "Çiftlik": 1, "Kereste": 1, "Taşocağı": 1}
var infantry := 0
var archers := 0
var cavalry := 0
var scout_level := 0
var expedition_time := 0.0
var expedition_target := ""
var victories := 0
var quest_claimed: Array = []
var production_time := 0.0
var save_time := 0.0
var notice := "1.4 hazir. Gelistirme panelini kullan."

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	game = get_tree().current_scene as Node3D
	if game == null:
		return
	load_expansion()
	build_interface()
	refresh()

func value(key: String) -> int:
	return int(game.get(key))

func afford(costs: Dictionary) -> bool:
	for key in costs:
		if value(key) < int(costs[key]):
			notice = "Yetersiz kaynak: " + str(key)
			refresh()
			return false
	for key in costs:
		game.set(key, value(key) - int(costs[key]))
	return true

func gain(rewards: Dictionary) -> void:
	for key in rewards:
		game.set(key, value(key) + int(rewards[key]))
	game.call("update_ui")

func build_interface() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	var open_button := Button.new()
	open_button.text = "KALE 1.4"
	open_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	open_button.offset_left = -175
	open_button.offset_right = -8
	open_button.offset_top = 58
	open_button.offset_bottom = 112
	root.add_child(open_button)
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -365
	panel.offset_right = -8
	panel.offset_top = 118
	panel.offset_bottom = -125
	root.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.12, 0.13, 0.96)
	style.border_color = Color("b49a62")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	scroll.add_child(column)
	var heading := Label.new()
	heading.text = "RISE OF CONQUEST 1.4"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	summary = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summary)
	make_button(column, "1 | KALE YUKSELT", upgrade_castle)
	make_button(column, "2 | EV GELISTIR", func(): upgrade_building("Ev"))
	make_button(column, "2 | KISLA GELISTIR", func(): upgrade_building("Kışla"))
	make_button(column, "2 | CIFTLIGI GELISTIR", func(): upgrade_building("Çiftlik"))
	make_button(column, "2 | KERESTEYI GELISTIR", func(): upgrade_building("Kereste"))
	make_button(column, "2 | TASOCAGINI GELISTIR", func(): upgrade_building("Taşocağı"))
	make_button(column, "4 | 5 PIYADE EGIT", func(): train("infantry"))
	make_button(column, "4 | 5 OKCU EGIT", func(): train("archers"))
	make_button(column, "4 | 3 SUVARI EGIT", func(): train("cavalry"))
	make_button(column, "6 | KESIF YAP", scout)
	make_button(column, "7 | SEFER BASLAT", start_expedition)
	make_button(column, "8 | CATISMA BASLAT", start_skirmish)
	quest_label = Label.new()
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(quest_label)
	make_button(column, "9 | GOREV ODULUNU AL", claim_quest)
	make_button(column, "10 | ILERLEMEYI KAYDET", func(): save_expansion(true))
	log_label = Label.new()
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(log_label)
	panel.visible = false
	open_button.pressed.connect(func():
		panel.visible = not panel.visible
		open_button.text = "KAPAT" if panel.visible else "KALE 1.4"
		refresh()
	)

func make_button(parent: VBoxContainer, title: String, action: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(0, 43)
	parent.add_child(button)
	button.pressed.connect(action)

func upgrade_castle() -> void:
	if castle_level >= 10:
		notice = "Kale en yuksek seviyede."
	elif afford({"coins": 100 * castle_level, "stones": 60 * castle_level}):
		castle_level += 1
		notice = "Kale seviye %d oldu!" % castle_level
		commit()
	refresh()

func upgrade_building(kind: String) -> void:
	var count := 0
	match kind:
		"Ev": count = int(game.get("house_count"))
		"Kışla": count = int(game.get("barracks_count"))
		"Çiftlik": count = int(game.get("farm_count"))
		"Kereste": count = int(game.get("lumber_count"))
		"Taşocağı": count = int(game.get("mine_count"))
	if count <= 0:
		notice = "Once sehirde " + kind + " insa et."
	elif int(building_levels[kind]) >= castle_level:
		notice = "Once kaleyi yukselt."
	else:
		var level := int(building_levels[kind])
		if afford({"woods": 45 * level, "stones": 20 * level}):
			building_levels[kind] = level + 1
			notice = "%s seviye %d oldu." % [kind, level + 1]
			commit()
	refresh()

func train(kind: String) -> void:
	if int(game.get("barracks_count")) <= 0:
		notice = "Asker icin once kisla insa et."
	elif kind == "cavalry" and castle_level < 3:
		notice = "Suvari icin kale seviye 3 gerekli."
	elif kind == "archers" and castle_level < 2:
		notice = "Okcu icin kale seviye 2 gerekli."
	else:
		var costs := {"foods": 50, "woods": 20}
		if kind == "archers":
			costs = {"foods": 60, "woods": 45}
		elif kind == "cavalry":
			costs = {"foods": 90, "coins": 80}
		if afford(costs):
			match kind:
				"infantry": infantry += 5
				"archers": archers += 5
				"cavalry": cavalry += 3
			notice = "Birlikler egitildi: " + kind
			commit()
	refresh()

func army_power() -> int:
	return infantry * 10 + archers * 15 + cavalry * 30 + castle_level * 5

func scout() -> void:
	if afford({"foods": 25}):
		scout_level += 1
		var places := ["Kuzey Ormani", "Tas Vadisi", "Altin Tepeleri", "Sinir Kalesi"]
		expedition_target = places[(scout_level - 1) % places.size()]
		notice = "Kesif tamam: " + expedition_target
		commit()
	refresh()

func start_expedition() -> void:
	if scout_level == 0:
		notice = "Once kesif yap."
	elif expedition_time > 0.0:
		notice = "Bir sefer zaten devam ediyor."
	elif infantry + archers + cavalry < 5:
		notice = "En az 5 asker egit."
	elif afford({"foods": 35}):
		expedition_time = 25.0
		notice = expedition_target + " icin ordu yola cikti."
		commit()
	refresh()

func start_skirmish() -> void:
	if infantry + archers + cavalry < 5:
		notice = "Catismak icin en az 5 asker gerekli."
		refresh()
		return
	var enemy_power := 65 + victories * 25
	if army_power() >= enemy_power:
		victories += 1
		gain({"coins": 90 + victories * 15, "stones": 35})
		notice = "ZAFER! +altin ve tas. Rakip gucu: %d" % enemy_power
	else:
		infantry = maxi(0, infantry - 2)
		archers = maxi(0, archers - 1)
		notice = "YENILGI! Birlik kaybi. Rakip gucu: %d" % enemy_power
	commit()
	refresh()

func quest_state() -> Array:
	return [
		["Kaleyi seviye 2 yap", castle_level >= 2],
		["5 piyade egit", infantry >= 5],
		["Bir kesif tamamla", scout_level >= 1],
		["Bir sefer tamamla", int(quest_claimed.count("expedition_done")) > 0],
		["Bir savas kazan", victories >= 1],
		["Kaleyi seviye 3 yap", castle_level >= 3],
		["5 okcu egit", archers >= 5],
		["3 suvari egit", cavalry >= 3],
		["Uc savas kazan", victories >= 3],
		["Kaleyi seviye 5 yap", castle_level >= 5]
	]

func claim_quest() -> void:
	var tasks := quest_state()
	for i in range(tasks.size()):
		if not quest_claimed.has(i) and bool(tasks[i][1]):
			quest_claimed.append(i)
			gain({"coins": 100 + i * 25, "woods": 50})
			notice = "Gorev %d tamamlandi! Odul alindi." % (i + 1)
			commit()
			refresh()
			return
	notice = "Odulu hazir yeni gorev yok."
	refresh()

func _process(delta: float) -> void:
	if game == null:
		return
	production_time += delta
	save_time += delta
	if production_time >= 5.0:
		production_time -= 5.0
		var bonus := {
			"coins": (int(building_levels["Ev"]) - 1) * int(game.get("house_count")) * 2,
			"foods": (int(building_levels["Çiftlik"]) - 1) * int(game.get("farm_count")) * 5,
			"woods": (int(building_levels["Kereste"]) - 1) * int(game.get("lumber_count")) * 4,
			"stones": (int(building_levels["Taşocağı"]) - 1) * int(game.get("mine_count")) * 3
		}
		gain(bonus)
	if expedition_time > 0.0:
		expedition_time -= delta
		if expedition_time <= 0.0:
			expedition_time = 0.0
			gain({"woods": 90 + scout_level * 10, "stones": 65, "coins": 50})
			if not quest_claimed.has("expedition_done"):
				quest_claimed.append("expedition_done")
			notice = "Sefer tamamlandi! Kaynaklar toplandi."
			commit()
	if save_time >= 30.0:
		save_time = 0.0
		save_expansion(false)
	if panel != null and panel.visible:
		refresh()

func refresh() -> void:
	if summary == null:
		return
	summary.text = "KALE %d | GUC %d\nPiyade %d | Okcu %d | Suvari %d\nKesif %d | Zafer %d\nSefer: %s\nBina seviyeleri: Ev %d, Kisla %d, Ciftlik %d, Kereste %d, Tas %d" % [castle_level, army_power(), infantry, archers, cavalry, scout_level, victories, ("%d sn" % ceili(expedition_time)) if expedition_time > 0 else "Hazir", int(building_levels["Ev"]), int(building_levels["Kışla"]), int(building_levels["Çiftlik"]), int(building_levels["Kereste"]), int(building_levels["Taşocağı"])]
	var tasks := quest_state()
	var next_task := "Tum gorevler tamamlandi!"
	for i in range(tasks.size()):
		if not quest_claimed.has(i):
			next_task = "%d/10: %s %s" % [i + 1, str(tasks[i][0]), "[ODUL HAZIR]" if bool(tasks[i][1]) else ""]
			break
	quest_label.text = "GOREV: " + next_task
	log_label.text = "DURUM: " + notice

func commit() -> void:
	save_expansion(false)
	game.call("update_ui")

func save_expansion(show_message: bool) -> void:
	var data := {"castle": castle_level, "levels": building_levels, "infantry": infantry, "archers": archers, "cavalry": cavalry, "scout": scout_level, "target": expedition_target, "expedition": expedition_time, "victories": victories, "claimed": quest_claimed}
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file == null:
		notice = "Ek kayit dosyasi acilamadi."
		return
	file.store_string(JSON.stringify(data))
	file.close()
	game.call("save_game", false)
	if show_message:
		notice = "Sehir ve 1.4 ilerlemesi kaydedildi."
		refresh()

func load_expansion() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return
	var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (data is Dictionary):
		return
	castle_level = clampi(int(data.get("castle", 1)), 1, 10)
	var levels: Variant = data.get("levels", {})
	if levels is Dictionary:
		for key in building_levels:
			building_levels[key] = clampi(int(levels.get(key, 1)), 1, 10)
	infantry = maxi(0, int(data.get("infantry", 0)))
	archers = maxi(0, int(data.get("archers", 0)))
	cavalry = maxi(0, int(data.get("cavalry", 0)))
	scout_level = maxi(0, int(data.get("scout", 0)))
	expedition_target = str(data.get("target", ""))
	expedition_time = maxf(0.0, float(data.get("expedition", 0.0)))
	victories = maxi(0, int(data.get("victories", 0)))
	var claimed: Variant = data.get("claimed", [])
	if claimed is Array:
		quest_claimed = claimed
