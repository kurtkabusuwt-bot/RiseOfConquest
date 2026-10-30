extends "res://war_conquest_70.gd"

# Extend 7.3 without replacing siege, commander bonuses, XP or save formats.
const HeroAbilities = preload("res://hero_abilities.gd")
var abilities = HeroAbilities.new()
var ability_panel: PanelContainer
var ability_buttons: Array[Button] = []
var ability_feedback: Label

func setup_commanders() -> void:
	super.setup_commanders()
	if commander_canvas != null:
		build_ability_ui()

func build_ability_ui() -> void:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	commander_canvas.add_child(screen)
	ability_panel = PanelContainer.new()
	screen.add_child(ability_panel)
	ability_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ability_panel.offset_left = -310
	ability_panel.offset_top = -220
	ability_panel.offset_right = -12
	ability_panel.offset_bottom = -12
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	ability_panel.add_child(content)
	ability_feedback = Label.new()
	ability_feedback.text = "KOMUTAN YETENEKLERİ | #88.1"
	ability_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(ability_feedback)
	for slot in range(2):
		var button := Button.new()
		button.custom_minimum_size = Vector2(286, 64)
		button.pressed.connect(cast_ability.bind(slot))
		content.add_child(button)
		ability_buttons.append(button)
	ability_panel.hide()

func begin_battle() -> void:
	if fighting:
		return
	super.begin_battle()
	if not fighting:
		return
	abilities.reset(active_commander, active_secondary)
	combat.attack_damage_modifier = Callable(abilities, "attack_damage")
	siege.damage_modifier = Callable(abilities, "wall_damage")
	if commander_panel != null:
		commander_panel.hide()
	if ability_feedback != null:
		ability_feedback.text = "KOMUTAN YETENEKLERİ | #88.1"
	update_ability_ui()

func cast_ability(slot: int) -> void:
	if abilities.cast(self, slot):
		if ability_feedback != null:
			ability_feedback.text = str(abilities.definition(slot)["name"]) + " kullanıldı!"
		update_panel()
	update_ability_ui()

func update_ability_ui() -> void:
	if ability_panel == null:
		return
	ability_panel.visible = fighting
	for slot in range(ability_buttons.size()):
		var button := ability_buttons[slot]
		var ability: Dictionary = abilities.definition(slot)
		var role := "ANA" if slot == 0 else "YARDIMCI"
		button.disabled = not fighting or not abilities.ready(slot)
		if ability.is_empty():
			button.text = role + "\nAktif yetenek yok"
			button.tooltip_text = "Fatih, Halid veya Hasan Sabbah atayın."
		else:
			var timer: float = abilities.remaining[slot]
			button.text = role + " | " + str(ability["name"]) + "\n"
			var status := "HAZIR"
			if abilities.active_time[slot] > 0.0:
				status = "AKTİF %d sn" % ceili(abilities.active_time[slot])
			elif not abilities.pending[slot].is_empty():
				status = "İLK VURUŞ: %d birlik" % abilities.pending[slot].size()
			if timer > 0.0:
				status += " | BEKLEME %d sn" % ceili(timer)
				if status.begins_with("HAZIR"):
					status = "BEKLEME %d sn" % ceili(timer)
			button.text += status
			button.tooltip_text = abilities.commanders[slot] + "\n" + str(ability["description"])

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
