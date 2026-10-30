
extends Node

# RISE OF CONQUEST - BUILD 90.3
# Legacy main HUD cleanup
# Godot 4.4.1 / Android

var game: Node
var completed := false

func _ready() -> void:
	call_deferred("_setup")

func _setup() -> void:
	game = get_tree().current_scene
	if game == null:
		return

	# Wait for the existing main UI to finish building.
	await get_tree().process_frame
	await get_tree().process_frame

	_hide_old_main_hud()

func _hide_old_main_hud() -> void:
	if game == null:
		return

	for child in game.get_children():
		if not child is CanvasLayer:
			continue

		# Only the original main.gd HUD has an
		# unnamed CanvasLayer directly under the scene.
		if child.name.begins_with("@CanvasLayer"):
			var found_old_hud := false

			for control in child.get_children():
				if control is Control:
					if _contains_old_main_ui(control):
						found_old_hud = true
						break

			if found_old_hud:
				child.visible = false
				completed = true

func _contains_old_main_ui(node: Node) -> bool:
	if node is Label:
		if "PROTOTIP 1.2" in node.text:
			return true

	for child in node.get_children():
		if _contains_old_main_ui(child):
			return true

	return false
