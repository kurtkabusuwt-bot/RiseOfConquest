
extends Node

# Rise of Conquest 3.1 - War interface recovery

var war: Node
var status: Label
var open_button: Button

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	var game := get_tree().current_scene
	if game == null:
		return

	war = game.get_node_or_null("WarConquest31")

	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	open_button = Button.new()
	open_button.text = "SAVAS 3.1"
	open_button.position = Vector2(170, 100)
	open_button.custom_minimum_size = Vector2(155, 46)
	canvas.add_child(open_button)
	open_button.pressed.connect(open_war)

	status = Label.new()
	status.position = Vector2(170, 150)
	status.add_theme_color_override(
		"font_color",
		Color(1.0, 0.9, 0.4)
	)
	canvas.add_child(status)

	if war == null:
		status.text = "HATA: WarConquest31 bulunamadi."
	else:
		status.text = "Savas modulu baglandi."

func open_war() -> void:
	if war == null:
		status.text = "HATA: Savas dugumu yok."
		return

	var existing_panel: Variant = war.get("panel")

	if not (existing_panel is PanelContainer):
		if war.has_method("build_ui"):
			war.call("build_ui")

	var current_panel: Variant = war.get("panel")

	if current_panel is PanelContainer:
		current_panel.visible = not current_panel.visible

		if war.has_method("update_panel"):
			war.call("update_panel")

		status.text = "Savas paneli hazir."
	else:
		status.text = "HATA: Panel olusturulamadi."
