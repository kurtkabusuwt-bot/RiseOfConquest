
extends Node

# RISE OF CONQUEST - BUILD 95.0
# SAFE MOBILE HUD CLEANUP
# Godot 4.4.1 / Android

const PROTECTED_UI_NAMES := [
    "MobileResources90",
    "MobileMenu90",
    "ConquestInterface15",
    "HeroMenu"
]

const OLD_HUD_MARKERS := [
    "RISE OF CONQUEST",
    "PROTOTIP"
]

var game: Node
var completed := false
var refresh_elapsed := 0.0


func _ready() -> void:
    call_deferred("_initialize")


func _initialize() -> void:
    game = get_parent()

    if not is_instance_valid(game):
        push_warning("HUD cleanup: Game node missing")
        return

    await get_tree().process_frame
    await get_tree().process_frame

    _protect_mobile_ui()
    _hide_old_main_hud()

    set_process(true)


func _process(delta: float) -> void:
    refresh_elapsed += delta

    if refresh_elapsed < 2.0:
        return

    refresh_elapsed = 0.0

    if not is_instance_valid(game):
        return

    _protect_mobile_ui()

    if not completed:
        _hide_old_main_hud()


func _protect_mobile_ui() -> void:
    for node_name in PROTECTED_UI_NAMES:
        var node := game.get_node_or_null(node_name)

        if node == null:
            continue

        if node is CanvasLayer:
            node.visible = true


func _hide_old_main_hud() -> void:
    for child in game.get_children():
        if not child is CanvasLayer:
            continue

        if child.name in PROTECTED_UI_NAMES:
            continue

        if not child.name.begins_with("@CanvasLayer"):
            continue

        if _contains_old_main_ui(child):
            child.visible = false
            completed = true

            print(
                "ROC BUILD 95: Old HUD hidden: ",
                child.name
            )


func _contains_old_main_ui(node: Node) -> bool:
    if node is Label:
        var label_text := node.text.to_upper()

        for marker in OLD_HUD_MARKERS:
            if marker in label_text:
                return true

    for child in node.get_children():
        if _contains_old_main_ui(child):
            return true

    return false
