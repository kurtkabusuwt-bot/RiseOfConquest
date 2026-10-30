
extends Node

# RISE OF CONQUEST - BUILD 94.7
# LEGACY HUD CLEANUP
# Godot 4.4.1 / Android

var game: Node
var completed := false

const NEW_UI_NAMES := [
	"MobileResources90",
	"MobileMenu90",
	"ConquestInterface15",
	"HeroMenu"
]

func _ready() -> void:
	call_deferred("_setup")

func _setup() -> void:
	game = get_parent()

	if not is_instance_valid(game):
		return

	await get_tree().process_frame
	await get_tree().process_frame

	_hide_old_main_hud()

func _hide_old_main_hud() -> void:
	if not is_instance_valid(game):
		return

	for child in game.get_children():
		if not child is CanvasLayer:
			continue

		if child.name in NEW_UI_NAMES:
			continue

		if child.name.begins_with("@CanvasLayer"):
			if _contains_old_main_ui(child):
				child.visible = false
				completed = true

func _contains_old_main_ui(node: Node) -> bool:
	if node is Label:
		var text_value := node.text.to_upper()

		if "RISE OF CONQUEST" in text_value:
			return true

		if "ALTIN" in text_value and "ODUN" in text_value:
			return true

		if "PROTOTIP" in text_value:
			return true

	for child in node.get_children():
		if _contains_old_main_ui(child):
			return true

	return false
