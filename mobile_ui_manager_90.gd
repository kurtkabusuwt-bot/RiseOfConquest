
extends Node

# RISE OF CONQUEST - BUILD 91.8
# CENTRAL MOBILE UI COORDINATOR
# Godot 4.4.1 / Android

const LEGACY_BUTTONS := [
	"KALE 1.4",
	"KALE 1.5",
	"ORDU 3.0",
	"KRALLIK 4.5",
	"KAHRAMANLAR",
	"KOMUTANLAR",
	"BINA ISIMLERI",
	"SAVAS 4.0"
]

const MODULE_NAMES := [
	"ConquestExpansion",
	"ConquestInterface15",
	"ArmyUpgrade30",
	"WarExpansion45",
	"HeroMenu",
	"WarConquest31",
	"CityInteraction"
]

var game: Node
var active_panel := ""
var refresh_timer := 0.0

func _ready() -> void:
	call_deferred("_initialize")

func _initialize() -> void:
	game = get_tree().current_scene

	if game == null:
		return

	await get_tree().process_frame
	await get_tree().process_frame

	_hide_old_buttons()

func _process(delta: float) -> void:
	if not is_instance_valid(game):
		return

	refresh_timer += delta

	if refresh_timer >= 0.5:
		refresh_timer = 0.0
		_hide_old_buttons()

func _hide_old_buttons() -> void:
	if not is_instance_valid(game):
		return

	for module_name in MODULE_NAMES:
		var module := game.get_node_or_null(module_name)

		if module != null:
			_hide_buttons_recursive(module)

func _hide_buttons_recursive(parent: Node) -> void:
	for child in parent.get_children():
		if child is Button:
			if child.text.strip_edges() in LEGACY_BUTTONS:
				child.visible = false

		_hide_buttons_recursive(child)

func _hide_module_panel(module_name: String) -> void:
	var module := game.get_node_or_null(module_name)

	if module == null:
		return

	for property in module.get_property_list():
		if str(property.get("name", "")) == "panel":
			var panel: Variant = module.get("panel")

			if panel is Control:
				panel.visible = false

			return

func _close_active_panel() -> void:
	if active_panel == "":
		return

	var module := game.get_node_or_null(active_panel)

	if module != null:
		if module.has_method("close_menu"):
			module.call("close_menu")
		else:
			_hide_module_panel(active_panel)

	active_panel = ""
	_hide_old_buttons()

func _close_other_panels(except_name: String) -> void:
	for module_name in [
		"HeroMenu",
		"ArmyUpgrade30",
		"WarExpansion45"
	]:
		if module_name != except_name:
			_hide_module_panel(module_name)

	var war := game.get_node_or_null("WarConquest31")

	if war != null and except_name != "WarConquest31":
		var war_ui: Variant = war.get("war_ui")

		if war_ui != null:
			var war_panel: Variant = war_ui.get("panel")

			if war_panel is Control:
				war_panel.visible = false

func open_heroes() -> void:
	if not is_instance_valid(game):
		return

	_close_active_panel()
	_close_other_panels("HeroMenu")

	var heroes := game.get_node_or_null("HeroMenu")

	if heroes != null and heroes.has_method("open_menu"):
		heroes.open_menu()
		active_panel = "HeroMenu"

	_hide_old_buttons()

func open_army() -> void:
	if not is_instance_valid(game):
		return

	_close_active_panel()
	_close_other_panels("ArmyUpgrade30")

	var army := game.get_node_or_null("ArmyUpgrade30")

	if army == null:
		return

	var panel: Variant = army.get("panel")

	if panel is Control:
		panel.visible = true
		active_panel = "ArmyUpgrade30"

		if army.has_method("update_info"):
			army.update_info()

	_hide_old_buttons()

func open_kingdom() -> void:
	if not is_instance_valid(game):
		return

	_close_active_panel()
	_close_other_panels("WarExpansion45")

	var kingdom := game.get_node_or_null("WarExpansion45")

	if kingdom == null:
		return

	var panel: Variant = kingdom.get("panel")

	if panel is Control:
		panel.visible = true
		active_panel = "WarExpansion45"

		if kingdom.has_method("refresh"):
			kingdom.refresh()

	_hide_old_buttons()

func close_all_panels() -> void:
	if not is_instance_valid(game):
		return

	_close_active_panel()
	_close_other_panels("")
	_hide_old_buttons()
