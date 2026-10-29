
extends Node

# Rise of Conquest 3.1 - War UI visibility fix

var war: Node
var status: Label

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	var game := get_tree().current_scene
	if game == null:
		return

	war = game.get_node_or_null("WarConquest31")
	if war == null:
		return

	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	var button := Button.new()
	button.text = "SAVAS 3.1"
	button.position = Vector2(170, 100)
	button.custom_minimum_size = Vector2(155, 46)
	canvas.add_child(button)
	button.pressed.connect(open_war)

	status = Label.new()
	status.position = Vector2(170, 150)
	status.add_theme_color_override(
		"font_color", Color(1, 0.9, 0.4)
	)
	canvas.add_child(status)

func open_war() -> void:
	if war == null:
		return

	var war_panel: Variant = war.get("panel")

	if war_panel is PanelContainer:
		war_panel.visible = not war_panel.visible
		if war.has_method("update_panel"):
			war.call("update_panel")
		status.text = ""
	else:
		status.text = "Savas modulu baslatilamadi."
