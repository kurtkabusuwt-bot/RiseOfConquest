
extends Node

# RISE OF CONQUEST - BUILD 91.1
# CENTRAL MOBILE UI MANAGER
# Godot 4.4.1 / Android

const LEGACY_BUTTONS := [
	"KALE 1.4",
	"KALE 1.5",
	"ORDU 3.0",
	"KRALLIK 4.5",
	"KAHRAMANLAR",
	"KOMUTANLAR",
	"BINA ISIMLERI"
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
	if game == null:
		return

	refresh_timer += delta

	if refresh_timer >= 0.5:
		refresh_timer = 0.0
		_hide_old_buttons()

func _hide_old_buttons() -> void:
	# Existing game logic stays active.
	# Only legacy launcher buttons are hidden.

	_hide_buttons_recursive(
		game.get_node_or_null("ConquestInterface15")
	)

	_hide_buttons_recursive(
		game.get_node_or_null("HeroMenu")
	)

	_hide_module_canvas("ConquestExpansion", "canvas")
	_hide_module_canvas("ArmyUpgrade30", "ui")
	_hide_module_canvas("WarExpansion45", "canvas")
	_hide_module_canvas("WarConquest31", "commander_canvas")

	var interaction := game.get_node_or_null("CityInteraction")

	if interaction != null:
		var names: Variant = interaction.get("names_button")
		if names is Button:
			names.visible = false

func _hide_module_canvas(
	module_name: String,
	property_name: String
) -> void:
	var module := game.get_node_or_null(module_name)

	if module == null:
		return

	var properties := module.get_property_list()
	var found := false

	for property in properties:
		if str(property.get("name", "")) == property_name:
			found = true
			break

	if not found:
		return

	var canvas: Variant = module.get(property_name)

	if canvas is Node:
		_hide_buttons_recursive(canvas)

func _hide_buttons_recursive(parent: Node) -> void:
	if parent == null:
		return

	for child in parent.get_children():
		if child is Button:
			if child.text.strip_edges() in LEGACY_BUTTONS:
				child.visible = false

		_hide_buttons_recursive(child)

func _close_active_panel() -> void:
	if game == null:
		return

	if active_panel == "":
		return

	var previous := game.get_node_or_null(active_panel)

	if previous != null:
		var panel: Variant = previous.get("panel")

		if panel is Control:
			panel.visible = false

		if previous.has_method("close_menu"):
			previous.call("close_menu")

	active_panel = ""

func open_heroes() -> void:
	_close_active_panel()

	var heroes := game.get_node_or_null("HeroMenu")

	if heroes != null and heroes.has_method("open_menu"):
		heroes.open_menu()
		active_panel = "HeroMenu"

	_hide_old_buttons()

func open_army() -> void:
	_close_active_panel()

	var army := game.get_node_or_null("ArmyUpgrade30")

	if army == null:
		return

	var panel: Variant = army.get("panel")

	if panel is Control:
		panel.visible = true

		if army.has_method("update_info"):
			army.update_info()

		active_panel = "ArmyUpgrade30"

	_hide_old_buttons()

func open_kingdom() -> void:
	_close_active_panel()

	var kingdom := game.get_node_or_null("WarExpansion45")

	if kingdom == null:
		return

	var panel: Variant = kingdom.get("panel")

	if panel is Control:
		panel.visible = true

		if kingdom.has_method("refresh"):
			kingdom.refresh()

		active_panel = "WarExpansion45"

	_hide_old_buttons()

func close_all_panels() -> void:
	_close_active_panel()
	_hide_old_buttons()
