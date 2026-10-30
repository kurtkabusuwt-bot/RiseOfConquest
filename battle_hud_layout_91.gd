
extends Node

# RISE OF CONQUEST - BUILD 91.5
# RESPONSIVE BATTLE ABILITY HUD
# Godot 4.4.1 / Android

const TOP_RESERVED := 235.0
const BOTTOM_RESERVED := 105.0
const SIDE_MARGIN := 12.0

var war: Node
var ability_panel: PanelContainer
var last_screen_size := Vector2.ZERO

func _ready() -> void:
	call_deferred("_initialize")

func _initialize() -> void:
	var game := get_tree().current_scene

	if game == null:
		return

	war = game.get_node_or_null("WarConquest31")

	if war == null:
		push_warning("Build 91.5: Savas modulu bulunamadi.")
		return

	_find_panel()
	_update_layout()

func _process(_delta: float) -> void:
	if not is_instance_valid(war):
		return

	if not is_instance_valid(ability_panel):
		_find_panel()

	if not is_instance_valid(ability_panel):
		return

	var screen_size := get_viewport().get_visible_rect().size

	if screen_size != last_screen_size:
		_update_layout()

	# Existing war system decides whether
	# the ability panel should be visible.
	# This module only adjusts its layout.

func _find_panel() -> void:
	if not is_instance_valid(war):
		return

	var value: Variant = war.get("ability_panel")

	if value is PanelContainer:
		ability_panel = value
		last_screen_size = Vector2.ZERO

func _update_layout() -> void:
	if not is_instance_valid(ability_panel):
		return

	var viewport := get_viewport()
	var rect := viewport.get_visible_rect()
	var screen_size := rect.size

	if screen_size.x <= 0 or screen_size.y <= 0:
		return

	var safe := rect

	if OS.get_name() == "Android" and viewport is Window:
		var physical := Rect2(
			DisplayServer.get_display_safe_area()
		)

		if physical.has_area():
			var logical: Rect2 = (
				viewport.get_screen_transform().affine_inverse()
				* physical
			)

			var clipped := rect.intersection(logical)

			if clipped.has_area():
				safe = clipped

	var left := safe.position.x + SIDE_MARGIN
	var right := safe.end.x - SIDE_MARGIN
	var top := safe.position.y + TOP_RESERVED
	var bottom := safe.end.y - BOTTOM_RESERVED

	var available_width := maxf(1.0, right - left)
	var available_height := maxf(1.0, bottom - top)

	var minimum := ability_panel.get_combined_minimum_size()

	var desired := Vector2(
		maxf(300.0, minimum.x),
		maxf(185.0, minimum.y)
	)

	var factor := minf(
		1.0,
		minf(
			available_width / desired.x,
			available_height / desired.y
		)
	)

	ability_panel.size = desired
	ability_panel.scale = Vector2.ONE * factor

	var displayed_size := desired * factor

	ability_panel.position = Vector2(
		right - displayed_size.x,
		top
	)

	last_screen_size = screen_size
