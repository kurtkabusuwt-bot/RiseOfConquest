
extends RefCounted

# RISE OF CONQUEST - BUILD 91.3
# CLEAN WAR INTERFACE
# Godot 4.4.1 / Android

var layer: CanvasLayer
var panel: PanelContainer
var hud: PanelContainer
var stats: Label
var report: Label
var hud_text: Label

func make_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.06, 0.1, 0.96)
	style.border_color = Color(0.85, 0.67, 0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12)
	return style

func button(
	parent: VBoxContainer,
	title: String,
	action: Callable
) -> Button:
	var result := Button.new()
	result.text = title
	result.custom_minimum_size = Vector2(0, 48)
	result.add_theme_font_size_override("font_size", 16)
	result.add_theme_color_override(
		"font_color",
		Color(0.95, 0.81, 0.54)
	)
	parent.add_child(result)
	result.pressed.connect(action)
	return result

func build(war: Node) -> void:
	layer = CanvasLayer.new()
	layer.layer = 40
	war.add_child(layer)

	# Legacy launcher is retained for compatibility,
	# but hidden in the new mobile interface.
	var open := Button.new()
	open.text = "SAVAS 4.0"
	open.visible = false
	layer.add_child(open)
	open.pressed.connect(war.toggle_panel)

	panel = PanelContainer.new()
	panel.name = "WarManagementPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 14
	panel.offset_top = 100
	panel.offset_right = -14
	panel.offset_bottom = -100
	panel.add_theme_stylebox_override("panel", make_style())
	layer.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "SAVAS VE FETIH KOMUTANLIGI"
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override(
		"font_color",
		Color(0.95, 0.81, 0.54)
	)
	content.add_child(heading)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var actions := VBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 8)
	scroll.add_child(actions)

	stats = Label.new()
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actions.add_child(stats)

	button(actions, "FORMASYON DEGISTIR", war.next_formation)
	button(actions, "SAVAS EMRI DEGISTIR", war.next_order)

	button(
		actions,
		"2 SUIKASTCI EGIT",
		func(): war.train_special("assassin")
	)

	button(
		actions,
		"2 KUSATMA BIRLIGI EGIT",
		func(): war.train_special("siege")
	)

	button(actions, "FETIH SAVASI BASLAT", war.begin_battle)

	report = Label.new()
	report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actions.add_child(report)

	button(content, "KAPAT", war.toggle_panel)
	panel.visible = false

	# Compact battle information at the top.
	hud = PanelContainer.new()
	hud.name = "BattleStatusHUD"
	hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.offset_left = 14
	hud.offset_top = 110
	hud.offset_right = -14
	hud.offset_bottom = 225
	hud.add_theme_stylebox_override("panel", make_style())
	layer.add_child(hud)

	var hud_content := VBoxContainer.new()
	hud.add_child(hud_content)

	hud_text = Label.new()
	hud_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_text.add_theme_font_size_override("font_size", 15)
	hud_content.add_child(hud_text)

	button(hud_content, "EMIR DEGISTIR", war.next_order)

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
		"SAVAS | " + enemy +
		"\nMAVI: %d | KIRMIZI: %d\n" % [blue, red] +
		wall +
		"\nEMIR: " + order +
		" | SURE: " + str(int(time))
	)
