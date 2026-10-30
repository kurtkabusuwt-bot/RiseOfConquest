
extends Node

# RISE OF CONQUEST - BUILD 90.4
# Central Mobile UI Manager
# Godot 4.4.1 / Android

var game: Node
var active_legacy_panel: String = ""

func _ready() -> void:
	call_deferred("_initialize")

func _initialize() -> void:
	game = get_tree().current_scene

	if game == null:
		return

	await get_tree().process_frame
	await get_tree().process_frame

	_hide_legacy_launchers()

func _hide_legacy_launchers() -> void:
	# Hide old navigation buttons, not gameplay nodes.
	_hide_button_in_layer("ConquestInterface15", "KALE 1.5")
	_hide_button_in_layer("HeroMenu", "KAHRAMANLAR")

	_hide_module_button("ArmyUpgrade30", "ui", "ORDU 3.0")
	_hide_module_button("WarExpansion45", "canvas", "KRALLIK 4.5")

func _hide_button_in_layer(node_name: String, caption: String) -> void:
	if game == null:
		return

	var node := game.get_node_or_null(node_name)
	if node == null:
		return

	_hide_matching_buttons(node, caption)

func _hide_module_button(
	node_name: String,
	property_name: String,
	caption: String
) -> void:
	if game == null:
		return

	var module := game.get_node_or_null(node_name)
	if module == null:
		return

	var canvas: Node = module.get(property_name)
	if canvas == null:
		return

	_hide_matching_buttons(canvas, caption)

func _hide_matching_buttons(parent: Node, caption: String) -> void:
	for child in parent.get_children():
		if child is Button:
			if caption in child.text:
				child.visible = false

		_hide_matching_buttons(child, caption)

func open_heroes() -> void:
	_close_active_panel()

	var heroes := game.get_node_or_null("HeroMenu")
	if heroes != null and heroes.has_method("open_menu"):
		heroes.open_menu()
		active_legacy_panel = "HeroMenu"

func open_army() -> void:
	_close_active_panel()

	var army := game.get_node_or_null("ArmyUpgrade30")
	if army != null and army.has_method("toggle_panel"):
		army.toggle_panel()
		active_legacy_panel = "ArmyUpgrade30"

func open_kingdom() -> void:
	_close_active_panel()

	var kingdom := game.get_node_or_null("WarExpansion45")
	if kingdom != null and kingdom.has_method("toggle_panel"):
		kingdom.toggle_panel()
		active_legacy_panel = "WarExpansion45"

func _close_active_panel() -> void:
	if game == null:
		return

	var previous := game.get_node_or_null(active_legacy_panel)
	if previous == null:
		active_legacy_panel = ""
		return

	if previous.get("panel") is Control:
		previous.get("panel").visible = false

	active_legacy_panel = ""
