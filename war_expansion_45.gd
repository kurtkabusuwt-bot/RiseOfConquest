extends Node

# RISE OF CONQUEST - WAR EXPANSION 4.5
# Hero, research, army upgrades and siege preparation.

const SAVE_PATH := "user://roc_war_expansion_45.json"

const CIVILIZATIONS := [
	"Osmanli", "Roma", "Viking",
	"Mogol", "Cin", "Arabistan", "Alamut"
]

const HERO_NAMES := [
	["Fatih", "Yavuz", "Kanuni", "Barbaros", "Aksemsettin"],
	["Sezar", "Augustus", "Scipio", "Trajan", "Aurelian"],
	["Ragnar", "Bjorn", "Ivar", "Lagertha", "Harald"],
	["Cengiz", "Subutay", "Ogedei", "Batu", "Cebe"],
	["Sun Tzu", "Yue Fei", "Guan Yu", "Zhao Yun", "Mulan"],
	["Halid", "Selahaddin", "Tarik", "Baybars", "Zubeyr"],
	["Hasan Sabbah", "Sinan", "Rashid", "Fidai", "Alamut Muhafizi"]
]

const RESEARCH_NAMES := [
	"Silah Teknolojisi",
	"Zirh Teknolojisi",
	"Okculuk",
	"Suvari Egitimi",
	"Kusatma Muhendisligi"
]

var game: Node
var war: Node

var civilization := 0
var selected_hero := 0
var hero_levels: Dictionary = {}
var research_levels := [0, 0, 0, 0, 0]
var siege_supplies := 0
var army_experience := 0
var military_rank := 1
var total_campaigns := 0

var canvas: CanvasLayer
var panel: PanelContainer
var info: Label
var hero_button: Button
var civ_button: Button
var status := "Komutanlik hazir."

func _ready() -> void:
	call_deferred("initialize")

func initialize() -> void:
	game = get_tree().current_scene
	if game == null:
		return

	war = game.get_node_or_null("WarConquest31")
	load_data()
	build_ui()
	refresh()

func coins() -> int:
	return int(game.get("coins"))

func woods() -> int:
	return int(game.get("woods"))

func stones() -> int:
	return int(game.get("stones"))

func foods() -> int:
	return int(game.get("foods"))

func spend(
	gold_cost: int,
	wood_cost: int,
	stone_cost: int,
	food_cost: int
) -> bool:
	if coins() < gold_cost:
		status = "Yetersiz altin."
		return false
	if woods() < wood_cost:
		status = "Yetersiz odun."
		return false
	if stones() < stone_cost:
		status = "Yetersiz tas."
		return false
	if foods() < food_cost:
		status = "Yetersiz yiyecek."
		return false

	game.set("coins", coins() - gold_cost)
	game.set("woods", woods() - wood_cost)
	game.set("stones", stones() - stone_cost)
	game.set("foods", foods() - food_cost)

	if game.has_method("update_ui"):
		game.call("update_ui")

	return true

func hero_name() -> String:
	return str(HERO_NAMES[civilization][selected_hero])

func hero_key() -> String:
	return str(civilization) + "_" + str(selected_hero)

func hero_level() -> int:
	return int(hero_levels.get(hero_key(), 1))

func hero_bonus() -> float:
	return 1.0 + float(hero_level() - 1) * 0.05

func research_bonus() -> float:
	var total := 0
	for level in research_levels:
		total += int(level)
	return 1.0 + float(total) * 0.025

func military_bonus() -> float:
	return hero_bonus() * research_bonus()

func next_civilization() -> void:
	civilization = (civilization + 1) % CIVILIZATIONS.size()
	selected_hero = 0
	status = "Medeniyet: " + str(CIVILIZATIONS[civilization])
	save_data()
	refresh()

func next_hero() -> void:
	selected_hero = (selected_hero + 1) % 5
	status = "Komutan: " + hero_name()
	save_data()
	refresh()

func upgrade_hero() -> void:
	var level := hero_level()
	if level >= 20:
		status = "Kahraman en yuksek seviyede."
		refresh()
		return

	var cost := 100 + level * 75
	if not spend(cost, 0, 0, 30):
		refresh()
		return

	hero_levels[hero_key()] = level + 1
	status = hero_name() + " seviye " + str(level + 1)
	save_data()
	refresh()

func upgrade_research(index: int) -> void:
	if index < 0 or index >= research_levels.size():
		return

	var level: int = int(research_levels[index])
	if level >= 10:
		status = "Arastirma en yuksek seviyede."
		refresh()
		return

	var gold_cost := 75 + level * 50
	var wood_cost := 40 + level * 25
	var stone_cost := 25 + level * 20

	if not spend(gold_cost, wood_cost, stone_cost, 0):
		refresh()
		return

	research_levels[index] = level + 1
	status = str(RESEARCH_NAMES[index]) + " gelistirildi."
	save_data()
	refresh()

func prepare_siege() -> void:
	if not spend(100, 120, 90, 30):
		refresh()
		return

	siege_supplies += 1
	status = "Kusatma malzemesi hazirlandi."
	save_data()
	refresh()

func train_military() -> void:
	if not spend(80, 0, 0, 60):
		refresh()
		return

	army_experience += 25
	var needed := military_rank * 100

	if army_experience >= needed:
		army_experience -= needed
		military_rank += 1
		status = "Ordu rutbesi yukseldi!"
	else:
		status = "Ordu egitimi tamamlandi."

	save_data()
	refresh()

func save_data() -> void:
	var data := {
		"civilization": civilization,
		"hero": selected_hero,
		"hero_levels": hero_levels,
		"research": research_levels,
		"siege_supplies": siege_supplies,
		"army_experience": army_experience,
		"military_rank": military_rank,
		"total_campaigns": total_campaigns
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify(data))
	file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if not (parsed is Dictionary):
		return

	var data: Dictionary = parsed

	civilization = clampi(
		int(data.get("civilization", 0)), 0, 6
	)
	selected_hero = clampi(
		int(data.get("hero", 0)), 0, 4
	)

	var loaded_heroes: Variant = data.get("hero_levels", {})
	if loaded_heroes is Dictionary:
		hero_levels = loaded_heroes

	var loaded_research: Variant = data.get("research", [])
	if loaded_research is Array:
		for i in range(mini(5, loaded_research.size())):
			research_levels[i] = clampi(
				int(loaded_research[i]), 0, 10
			)

	siege_supplies = maxi(
		0, int(data.get("siege_supplies", 0))
	)
	army_experience = maxi(
		0, int(data.get("army_experience", 0))
	)
	military_rank = maxi(
		1, int(data.get("military_rank", 1))
	)
	total_campaigns = maxi(
		0, int(data.get("total_campaigns", 0))
	)

func add_button(
	parent: VBoxContainer,
	title: String,
	action: Callable
) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(0, 40)
	parent.add_child(button)
	button.pressed.connect(action)
	return button

func build_ui() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 45
	add_child(canvas)

	var toggle := Button.new()
	toggle.text = "KRALLIK 4.5"
	toggle.position = Vector2(12, 155)
	toggle.custom_minimum_size = Vector2(155, 44)
	canvas.add_child(toggle)
	toggle.pressed.connect(toggle_panel)

	panel = PanelContainer.new()
	panel.position = Vector2(180, 60)
	panel.custom_minimum_size = Vector2(350, 0)
	canvas.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(350, 460)
	panel.add_child(scroll)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(330, 0)
	content.add_theme_constant_override("separation", 5)
	scroll.add_child(content)

	var heading := Label.new()
	heading.text = "KRALLIK VE ORDU GELISIMI"
	content.add_child(heading)

	info = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(info)

	civ_button = add_button(
		content, "MEDENIYET DEGISTIR", next_civilization
	)

	hero_button = add_button(
		content, "KAHRAMAN DEGISTIR", next_hero
	)

	add_button(
		content, "KAHRAMAN GELISTIR", upgrade_hero
	)

	add_button(
		content, "ORDU EGITIMI", train_military
	)

	add_button(
		content, "KUSATMA MALZEMESI URET", prepare_siege
	)

	for i in range(RESEARCH_NAMES.size()):
		var index: int = i
		add_button(
			content,
			str(RESEARCH_NAMES[i]) + " GELISTIR",
			func(): upgrade_research(index)
		)

	add_button(content, "KAYDET", save_and_refresh)
	add_button(content, "KAPAT", toggle_panel)

	panel.visible = false

func save_and_refresh() -> void:
	save_data()
	status = "Krallik kaydedildi."
	refresh()

func toggle_panel() -> void:
	panel.visible = not panel.visible
	refresh()

func refresh() -> void:
	if info == null:
		return

	var lines := ""
	lines += "MEDENIYET: " + str(CIVILIZATIONS[civilization]) + "\n"
	lines += "KAHRAMAN: " + hero_name() + "\n"
	lines += "KAHRAMAN SEVIYESI: " + str(hero_level()) + "\n"
	lines += "ORDU RUTBESI: " + str(military_rank) + "\n"
	lines += "ORDU DENEYIMI: " + str(army_experience) + "\n"
	lines += "KUSATMA MALZEMESI: " + str(siege_supplies) + "\n"
	lines += "KOMUTAN BONUSU: %" + str(
		int((military_bonus() - 1.0) * 100.0)
	) + "\n\n"

	lines += "ARASTIRMALAR:\n"

	for i in range(RESEARCH_NAMES.size()):
		lines += str(RESEARCH_NAMES[i])
		lines += ": " + str(research_levels[i]) + "/10\n"

	lines += "\n" + status
	info.text = lines
