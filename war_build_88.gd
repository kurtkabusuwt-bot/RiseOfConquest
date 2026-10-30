
extends "res://war_conquest_70.gd"

# RISE OF CONQUEST - BUILD 91.7
# COMMANDER ABILITIES AND RESPONSIVE HUD
# Godot 4.4.1 / Android

const HeroAbilities = preload("res://hero_abilities.gd")

var abilities = HeroAbilities.new()
var ability_panel: PanelContainer
var ability_buttons: Array[Button] = []
var ability_feedback: Label

const ABILITY_LAYER := 120

var ability_canvas: CanvasLayer
var ability_screen: Control
var ability_content: VBoxContainer
var ability_ui_error_reported := false

func setup_commanders() -> void:
	if not is_instance_valid(commander_canvas):
		super.setup_commanders()

	if build_ability_ui():
		update_ability_ui()

func ability_ui_valid() -> bool:
	if not is_instance_valid(ability_canvas):
		return false

	if ability_canvas.is_queued_for_deletion():
		return false

	if not is_instance_valid(ability_screen):
		return false

	if not is_instance_valid(ability_panel):
		return false

	if ability_panel.is_queued_for_deletion():
		return false

	if ability_screen.is_queued_for_deletion():
		return false

	if not is_instance_valid(ability_content):
		return false

	if not is_instance_valid(ability_feedback):
		return false

	if not ability_panel.is_inside_tree():
		return false

	if ability_panel.get_parent() != ability_screen:
		return false

	if ability_buttons.size() != 2:
		return false

	for button in ability_buttons:
		if not is_instance_valid(button):
			return false

		if button.is_queued_for_deletion():
			return false

		if button.get_parent() != ability_content:
			return false

	return true

func build_ability_ui() -> bool:
	if ability_ui_valid():
		return true

	if not is_inside_tree():
		if not ability_ui_error_reported:
			push_error(
				"Build 91.7: Ability HUD cannot be created."
			)
			ability_ui_error_reported = true
		return false

	if is_instance_valid(ability_canvas):
		ability_canvas.hide()
		ability_canvas.queue_free()

	ability_buttons.clear()

	ability_canvas = CanvasLayer.new()
	ability_canvas.name = "BattleAbilitiesHUD"
	ability_canvas.layer = ABILITY_LAYER
	add_child(ability_canvas)

	ability_screen = Control.new()
	ability_screen.name = "AbilityScreen"
	ability_canvas.add_child(ability_screen)

	ability_screen.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	ability_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE

	ability_panel = PanelContainer.new()
	ability_panel.name = "AbilityPanel"
	ability_screen.add_child(ability_panel)
	ability_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.09, 0.96)
	style.border_color = Color(0.85, 0.65, 0.25)
	style.set_border_width_all(2)
	style.set_content_margin_all(8)
	style.set_corner_radius_all(12)
	ability_panel.add_theme_stylebox_override("panel", style)

	ability_content = VBoxContainer.new()
	ability_content.add_theme_constant_override(
		"separation", 8
	)
	ability_panel.add_child(ability_content)

	ability_feedback = Label.new()
	ability_feedback.text = "KOMUTAN YETENEKLERI"
	ability_feedback.add_theme_font_size_override(
		"font_size", 16
	)
	ability_feedback.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
	ability_content.add_child(ability_feedback)

	for slot in range(2):
		var button := Button.new()
		button.name = "CommanderAbility%d" % slot
		button.custom_minimum_size = Vector2(286, 64)
		button.add_theme_font_size_override(
			"font_size", 16
		)
		button.clip_text = true
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.pressed.connect(
			cast_ability.bind(slot)
		)
		ability_content.add_child(button)
		ability_buttons.append(button)

	ability_panel.visible = fighting

	var resize_action := Callable(
		self, "layout_ability_ui"
	)

	if not get_viewport().size_changed.is_connected(
		resize_action
	):
		get_viewport().size_changed.connect(
			resize_action
		)

	ability_ui_error_reported = false

	layout_ability_ui()
	call_deferred("layout_ability_ui")

	return true

func ability_safe_rect() -> Rect2:
	var viewport := get_viewport()
	var visible := viewport.get_visible_rect()

	if OS.get_name() != "Android":
		return visible

	if not (viewport is Window):
		return visible

	var physical_safe := Rect2(
		DisplayServer.get_display_safe_area()
	)

	if not physical_safe.has_area():
		return visible

	return screen_safe_to_viewport(
		physical_safe,
		viewport.get_screen_transform(),
		visible
	)

func screen_safe_to_viewport(
	physical_safe: Rect2,
	screen_transform: Transform2D,
	visible: Rect2
) -> Rect2:
	var logical_safe: Rect2 = (
		screen_transform.affine_inverse()
		* physical_safe
	)

	var safe := visible.intersection(logical_safe)

	if safe.has_area():
		return safe

	return visible

func layout_ability_ui() -> void:
	if not ability_ui_valid():
		return

	# Build 91.7:
	# The external layout module is the single
	# authority for ability panel positioning.

	var layout_manager := get_tree().current_scene.get_node_or_null(
		"BattleHUDLayout91"
	)

	if layout_manager != null:
		if layout_manager.has_method("_update_layout"):
			layout_manager.call("_update_layout")
			return

	# Fallback if the layout module is unavailable.
	var safe := ability_safe_rect()
	var margin := 12.0
	var available := safe.grow(-margin)

	if not available.has_area():
		return

	var minimum := ability_panel.get_combined_minimum_size()

	var desired := Vector2(
		maxf(320.0, minimum.x),
		maxf(190.0, minimum.y)
	)

	var factor := minf(
		1.0,
		minf(
			available.size.x / desired.x,
			available.size.y / desired.y
		)
	)

	ability_panel.size = desired
	ability_panel.scale = Vector2.ONE * factor
	ability_panel.position = (
		available.end - desired * factor
	)

func begin_battle() -> void:
	if fighting:
		update_ability_ui()
		return

	super.begin_battle()

	if not fighting:
		return

	abilities.reset(
		active_commander,
		active_secondary
	)

	combat.attack_damage_modifier = Callable(
		abilities, "attack_damage"
	)

	siege.damage_modifier = Callable(
		abilities, "wall_damage"
	)

	if is_instance_valid(commander_panel):
		commander_panel.hide()

	if is_instance_valid(ability_feedback):
		ability_feedback.text = "KOMUTAN YETENEKLERI"

	update_ability_ui()

func cast_ability(slot: int) -> void:
	if abilities.cast(self, slot):
		if is_instance_valid(ability_feedback):
			ability_feedback.text = (
				str(abilities.definition(slot)["name"])
				+ " kullanildi!"
			)

		update_panel()

	update_ability_ui()

func update_ability_ui() -> void:
	if not ability_ui_valid():
		if not fighting:
			return

		push_warning(
			"Build 91.7: Rebuilding missing ability HUD."
		)

		if not build_ability_ui():
			return

	ability_canvas.visible = true
	ability_screen.show()
	ability_panel.visible = fighting

	for slot in range(ability_buttons.size()):
		var button := ability_buttons[slot]
		var ability: Dictionary = abilities.definition(slot)

		var role := (
			"ANA" if slot == 0 else "YARDIMCI"
		)

		button.disabled = (
			not fighting
			or not abilities.ready(slot)
		)

		if ability.is_empty():
			button.text = (
				role + "\nAktif yetenek yok"
			)
			button.tooltip_text = (
				"Fatih, Halid veya Hasan Sabbah atayin."
			)
		else:
			var timer: float = abilities.remaining[slot]

			button.text = (
				role + " | "
				+ str(ability["name"])
				+ "\n"
			)

			var status := "HAZIR"

			if abilities.active_time[slot] > 0.0:
				status = (
					"AKTIF %d sn"
					% ceili(abilities.active_time[slot])
				)

			elif not abilities.pending[slot].is_empty():
				status = (
					"ILK VURUS: %d birlik"
					% abilities.pending[slot].size()
				)

			if timer > 0.0:
				if status == "HAZIR":
					status = (
						"BEKLEME %d sn"
						% ceili(timer)
					)
				else:
					status += (
						" | BEKLEME %d sn"
						% ceili(timer)
					)

			button.text += status

			button.tooltip_text = (
				abilities.commanders[slot]
				+ "\n"
				+ str(ability["description"])
			)

	layout_ability_ui()

func _process(delta: float) -> void:
	if fighting:
		abilities.update(delta)

	super._process(delta)
	update_ability_ui()

func finish_battle() -> void:
	super.finish_battle()

	combat.attack_damage_modifier = Callable()
	siege.damage_modifier = Callable()

	abilities.reset("", "")
	update_ability_ui()
