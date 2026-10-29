
extends Node

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

	if not war.has_method("build_ui"):
		status.text = "HATA 4: Savas fonksiyonlari yok."
		return

	if war.get("expansion") == null:
		status.text = "HATA 5: Ordu baglantisi yok."
		return

	var war_panel: Variant = war.get("panel")
	if war_panel is PanelContainer:
		war_panel.visible = not war_panel.visible
		status.text = "SAVAS PANELI HAZIR."
	else:
		status.text = "HATA 6: Panel olusturulmamis."
