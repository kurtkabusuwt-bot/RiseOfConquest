extends Node

# RISE OF CONQUEST - WAR UI DIAGNOSTIC
# Compatible with war_conquest_31.gd and war_ui_40.gd

var war: Node
var status: Label

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	var button := Button.new()
	button.text = "SAVAS TEST"
	button.position = Vector2(170, 100)
	button.custom_minimum_size = Vector2(155, 46)
	canvas.add_child(button)
	button.pressed.connect(diagnose)

	status = Label.new()
	status.position = Vector2(170, 150)
	status.add_theme_color_override(
		"font_color",
		Color(1.0, 0.9, 0.3)
	)
	canvas.add_child(status)

	diagnose()

func diagnose() -> void:
	if status == null:
		return

	var scene := get_tree().current_scene
	if scene == null:
		status.text = "HATA 1: Ana sahne yok."
		return

	war = scene.get_node_or_null("WarConquest31")
	if war == null:
		status.text = "HATA 2: Savas dugumu yok."
		return

	if war.get_script() == null:
		status.text = "HATA 3: Savas kodu yuklenemedi."
		return

	if not war.has_method("begin_battle"):
		status.text = "HATA 4: Savas fonksiyonlari yok."
		return

	if war.get("expansion") == null:
		status.text = "HATA 5: Ordu baglantisi yok."
		return

	var ui: Variant = war.get("war_ui")
	if ui == null:
		status.text = "HATA 6: Arayuz sistemi yok."
		return

	var war_panel: Variant = ui.get("panel")
	if not (war_panel is PanelContainer):
		status.text = "HATA 7: Panel olusturulmamis."
		return

	if not is_instance_valid(war_panel):
		status.text = "HATA 8: Panel gecersiz."
		return

	if bool(war.get("fighting")):
		status.text = "SAVAS DEVAM EDIYOR."
		return

	war_panel.visible = not war_panel.visible
	status.text = "SAVAS PANELI HAZIR."
