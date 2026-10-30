
extends Node

# RISE OF CONQUEST - BUILD 96.1
# MULTITOUCH GESTURE GUARD
# Godot 4.4.1 / Android

var game: Node

var active_touches: Dictionary = {}
var gesture_blocked := false


func _ready() -> void:
    game = get_parent()

    process_priority = 100
    set_process_input(true)
    set_process_unhandled_input(true)

    print("ROC BUILD 96.1: Touch guard ready")


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
            gesture_blocked = true
            _mark_dragging()
    else:
        active_touches.erase(event.index)

        if gesture_blocked:
            _mark_dragging()

        if active_touches.is_empty():
            # Keep the release event protected.
            # Reset on the next touch sequence.
            gesture_blocked = false


func _handle_drag(event: InputEventScreenDrag) -> void:
    if not active_touches.has(event.index):
        return

    active_touches[event.index] = event.position

    if active_touches.size() >= 2:
        gesture_blocked = true

    if gesture_blocked:
        _mark_dragging()


func _unhandled_input(event: InputEvent) -> void:
    if not is_instance_valid(game):
        return

    if not gesture_blocked:
        return

    if event is InputEventScreenTouch:
        _mark_dragging()

    elif event is InputEventScreenDrag:
        _mark_dragging()


func _mark_dragging() -> void:
    if not is_instance_valid(game):
        return

    game.set("dragging", true)
