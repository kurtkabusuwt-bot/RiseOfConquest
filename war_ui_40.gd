
extends RefCounted

# RISE OF CONQUEST - WAR UI 4.0

var layer: CanvasLayer
var panel: PanelContainer
var hud: PanelContainer
var stats: Label
var report: Label
var hud_text: Label

func button(
	parent: VBoxContainer,
	title: String,
	action: Callable
) -> Button:
	var result := Button.new()
	result.text = title
	result.custom_minimum_size = Vector2(0, 43)
	parent.add_child(result)
	result.pressed.connect(action)
	return result

func build(war: Node) -> void:
	layer = CanvasLayer.new()
	layer.layer = 40
	war.add_child(layer)

	var open := Button.new()
	open.text = "SAVAS 4.0"
	open.position = Vector2(12, 45)
	open.custom_minimum_size = Vector2(150, 46)
	layer.add_child(open)
	open.pressed.connect(war.toggle_panel)

	panel = PanelContainer.new()
	panel.position = Vector2(165, 50)
	panel.custom_minimum_size = Vector2(335, 0)
	layer.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	panel.add_child(content)

	var title := Label.new()
	title.text = "SAVAS VE FETIH KOMUTANLIGI"
	content.add_child(title)

	stats = Label.new()
	content.add_child(stats)

	button(
		content, "FORMASYON DEGISTIR",
		war.next_formation
	)
	button(
		content, "SAVAS EMRI DEGISTIR",
		war.next_order
	)
	button(
		content, "2 SUIKASTCI EGIT",
		func(): war.train_special("assassin")
	)
	button(
		content, "2 KUSATMA BIRLIGI EGIT",
		func(): war.train_special("siege")
	)
	button(
		content, "FETIH SAVASI BASLAT",
		war.begin_battle
	)

	report = Label.new()
	report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	report.custom_minimum_size = Vector2(325, 0)
	content.add_child(report)

	button(content, "KAPAT", war.toggle_panel)
	panel.visible = false

	hud = PanelContainer.new()
	hud.position = Vector2(180, 12)
	hud.custom_minimum_size = Vector2(300, 0)
	layer.add_child(hud)

	var hud_content := VBoxContainer.new()
	hud.add_child(hud_content)

	hud_text = Label.new()
	hud_content.add_child(hud_text)

	button(
		hud_content,
		"EMIR DEGISTIR",
		war.next_order
	)
	hud.visible = false

func update(
	army: Dictionary,
	power: int,
	formation: String,
	order: String,
	wins: int,
	losses: int,
	conquered: int,
	message: String
) -> void:
	if stats == null:
		return

	stats.text = (
		"PIYADE %d | OKCU %d | SUVARI %d\n" %
		[
			int(army.get("infantry", 0)),
			int(army.get("archers", 0)),
			int(army.get("cavalry", 0))
		]
	)

	stats.text += (
		"SUIKASTCI %d | KUSATMA %d\n" %
		[
			int(army.get("assassin", 0)),
			int(army.get("siege", 0))
		]
	)

	stats.text += (
		"GUC %d | FORMASYON %s\n" %
		[power, formation]
	)

	stats.text += (
		"EMIR %s | FETIH %d\n" %
		[order, conquered]
	)

	stats.text += (
		"ZAFER %d | YENILGI %d" %
		[wins, losses]
	)

	report.text = message

func battle_status(
	enemy: String,
	blue: int,
	red: int,
	wall: String,
	order: String,
	time: float
) -> void:
	if hud_text == null:
		return

	hud_text.text = (
		"SAVAS 4.0 | " + enemy +
		"\nMAVI: %d | KIRMIZI: %d\n" % [blue, red] +
		wall +
		"\nEMIR: " + order +
		" | SURE: " + str(int(time))
	)
