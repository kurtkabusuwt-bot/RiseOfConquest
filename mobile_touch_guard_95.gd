
extends Node

# RISE OF CONQUEST - BUILD 95.3
# MOBILE TOUCH GESTURE GUARD
# Godot 4.4.1 / Android

var game: Node

var active_touches: Dictionary = {}
var multitouch_gesture := false
var blocked_until_release := false


func _ready() -> void:
    game = get_parent()
    set_process_input(true)
    process_priority = -100

    print("ROC BUILD 95.3: Touch guard ready")


func _input(event: InputEvent) -> void:
    if not is_instance_valid(game):
        return

    if event is InputEventScreenTouch:
        _handle_touch(event)

    elif event is InputEventScreenDrag:
        _handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
    if event.pressed:
        active_touches[event.index] = event.position

        if active_touches.size() >= 2:
            multitouch_gesture = true
            blocked_until_release = true
            _block_ground_tap()

    else:
        active_touches.erase(event.index)

        if multitouch_gesture:
            _block_ground_tap()

        if active_touches.is_empty():
            multitouch_gesture = false
            blocked_until_release = false


func _handle_drag(event: InputEventScreenDrag) -> void:
    if not active_touches.has(event.index):
        return

    active_touches[event.index] = event.position

    if active_touches.size() >= 2:
        multitouch_gesture = true
        blocked_until_release = true

    if multitouch_gesture or blocked_until_release:
        _block_ground_tap()


func _block_ground_tap() -> void:
    if not is_instance_valid(game):
        return

    if _has_property("dragging"):
        game.set("dragging", true)


func _has_property(property_name: String) -> bool:
    if not is_instance_valid(game):
        return false

    for property in game.get_property_list():
        if str(property.get("name", "")) == property_name:
            return true

    return false
