
extends Node

# ============================================================
# RISE OF CONQUEST
# BUILD 96.2 - ADVANCED MOBILE INPUT PROTECTION
# Godot 4.4.1 / Android
#
# Features:
# - Single touch tracking
# - Multi-touch protection
# - Pinch release protection
# - Drag detection
# - Accidental construction tap prevention
# - Adaptive screen scaling
# - Gesture lifecycle management
# - Input diagnostics
# - Safe state reset
# ============================================================


# ------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------

const BASE_DRAG_THRESHOLD := 12.0
const MIN_DRAG_THRESHOLD := 10.0
const MAX_DRAG_THRESHOLD := 24.0

const REFERENCE_SCREEN_WIDTH := 1080.0

const MAX_TRACKED_TOUCHES := 10

const DEBUG_ENABLED := false


# ------------------------------------------------------------
# GAME REFERENCES
# ------------------------------------------------------------

var game: Node = null
var viewport_ref: Viewport = null


# ------------------------------------------------------------
# TOUCH STATE
# ------------------------------------------------------------

var active_touches: Dictionary = {}

var touch_start_positions: Dictionary = {}

var touch_last_positions: Dictionary = {}

var touch_travel_distances: Dictionary = {}


# ------------------------------------------------------------
# GESTURE STATE
# ------------------------------------------------------------

var gesture_active := false

var gesture_multitouch := false

var gesture_dragging := false

var gesture_blocked := false

var gesture_was_multitouch := false

var gesture_sequence := 0

var gesture_start_time := 0

var gesture_max_fingers := 0


# ------------------------------------------------------------
# SCREEN SETTINGS
# ------------------------------------------------------------

var screen_size := Vector2.ZERO

var drag_threshold := BASE_DRAG_THRESHOLD


# ------------------------------------------------------------
# STATISTICS
# ------------------------------------------------------------

var total_touch_events := 0

var total_drag_events := 0

var total_multitouch_gestures := 0

var total_blocked_releases := 0

var total_completed_gestures := 0


# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
    game = get_parent()

    viewport_ref = get_viewport()

    process_priority = -100

    set_process_input(true)

    _update_screen_settings()

    if viewport_ref != null:
        viewport_ref.size_changed.connect(
            _update_screen_settings
        )

    _reset_all_state()

    _debug("Advanced mobile guard initialized")


# ============================================================
# SCREEN SCALING
# ============================================================

func _update_screen_settings() -> void:
    if viewport_ref == null:
        viewport_ref = get_viewport()

    screen_size = (
        viewport_ref.get_visible_rect().size
    )

    var shortest_side := minf(
        screen_size.x,
        screen_size.y
    )

    var scale_factor := (
        shortest_side / REFERENCE_SCREEN_WIDTH
    )

    drag_threshold = clampf(
        BASE_DRAG_THRESHOLD * scale_factor,
        MIN_DRAG_THRESHOLD,
        MAX_DRAG_THRESHOLD
    )

    _debug(
        "Screen: %s | Threshold: %.1f"
        % [str(screen_size), drag_threshold]
    )


# ============================================================
# INPUT ROUTING
# ============================================================

func _input(event: InputEvent) -> void:
    if not is_instance_valid(game):
        return

    if event is InputEventScreenTouch:
        _process_screen_touch(event)

    elif event is InputEventScreenDrag:
        _process_screen_drag(event)


# ============================================================
# SCREEN TOUCH
# ============================================================

func _process_screen_touch(
    event: InputEventScreenTouch
) -> void:
    total_touch_events += 1

    if event.pressed:
        _touch_pressed(
            event.index,
            event.position
        )
    else:
        _touch_released(
            event.index,
            event.position
        )


# ============================================================
# TOUCH PRESSED
# ============================================================

func _touch_pressed(
    finger_id: int,
    position: Vector2
) -> void:
    if active_touches.is_empty():
        _begin_gesture()

    if active_touches.size() >= MAX_TRACKED_TOUCHES:
        _block_gesture()
        return

    active_touches[finger_id] = position

    touch_start_positions[finger_id] = position

    touch_last_positions[finger_id] = position

    touch_travel_distances[finger_id] = 0.0

    gesture_max_fingers = maxi(
        gesture_max_fingers,
        active_touches.size()
    )

    if active_touches.size() >= 2:
        _activate_multitouch()

    _debug(
        "Finger pressed: %d | Active: %d"
        % [finger_id, active_touches.size()]
    )


# ============================================================
# TOUCH RELEASED
# ============================================================

func _touch_released(
    finger_id: int,
    position: Vector2
) -> void:
    if not active_touches.has(finger_id):
        return

    _update_touch_travel(
        finger_id,
        position
    )

    var was_blocked := gesture_blocked

    var was_multitouch := gesture_was_multitouch

    var was_dragging := gesture_dragging

    active_touches.erase(finger_id)

    touch_start_positions.erase(finger_id)

    touch_last_positions.erase(finger_id)

    touch_travel_distances.erase(finger_id)

    # Critical protection:
    # A release from a multi-touch gesture must never
    # become a ground tap in main.gd.

    if was_blocked or was_multitouch:
        _consume_input()

        total_blocked_releases += 1

        _set_game_dragging(true)

    elif was_dragging:
        # The main camera script also checks dragging.
        # Keep the value true for the release event.
        _set_game_dragging(true)

    if active_touches.is_empty():
        _finish_gesture()
    else:
        # A multi-touch gesture stays blocked even
        # when only one finger remains on screen.
        if gesture_was_multitouch:
            gesture_blocked = true
            _set_game_dragging(true)

    _debug(
        "Finger released: %d | Remaining: %d"
        % [finger_id, active_touches.size()]
    )


# ============================================================
# SCREEN DRAG
# ============================================================

func _process_screen_drag(
    event: InputEventScreenDrag
) -> void:
    total_drag_events += 1

    var finger_id := event.index

    if not active_touches.has(finger_id):
        return

    _update_touch_travel(
        finger_id,
        event.position
    )

    if active_touches.size() >= 2:
        _activate_multitouch()

    var distance := float(
        touch_travel_distances.get(
            finger_id,
            0.0
        )
    )

    if distance >= drag_threshold:
        gesture_dragging = true

    if gesture_multitouch:
        gesture_dragging = true

    if gesture_blocked:
        _set_game_dragging(true)

    elif gesture_dragging:
        _set_game_dragging(true)

    _debug(
        "Drag: %d | Travel: %.1f"
        % [finger_id, distance]
    )


# ============================================================
# GESTURE LIFECYCLE
# ============================================================

func _begin_gesture() -> void:
    gesture_sequence += 1

    gesture_start_time = (
        Time.get_ticks_msec()
    )

    gesture_active = true

    gesture_multitouch = false

    gesture_dragging = false

    gesture_blocked = false

    gesture_was_multitouch = false

    gesture_max_fingers = 0


func _activate_multitouch() -> void:
    if not gesture_was_multitouch:
        total_multitouch_gestures += 1

    gesture_multitouch = true

    gesture_was_multitouch = true

    gesture_dragging = true

    gesture_blocked = true

    _set_game_dragging(true)


func _block_gesture() -> void:
    gesture_blocked = true

    gesture_dragging = true

    _set_game_dragging(true)


func _finish_gesture() -> void:
    total_completed_gestures += 1

    _debug(
        "Gesture completed: %d | Fingers: %d"
        % [
            gesture_sequence,
            gesture_max_fingers
        ]
    )

    _reset_gesture_state()


func _reset_gesture_state() -> void:
    gesture_active = false

    gesture_multitouch = false

    gesture_dragging = false

    gesture_blocked = false

    gesture_was_multitouch = false

    gesture_max_fingers = 0


func _reset_all_state() -> void:
    active_touches.clear()

    touch_start_positions.clear()

    touch_last_positions.clear()

    touch_travel_distances.clear()

    _reset_gesture_state()


# ============================================================
# MOVEMENT TRACKING
# ============================================================

func _update_touch_travel(
    finger_id: int,
    position: Vector2
) -> void:
    if not touch_last_positions.has(finger_id):
        return

    var last_position: Vector2 = (
        touch_last_positions[finger_id]
    )

    var movement := last_position.distance_to(
        position
    )

    var previous_distance := float(
        touch_travel_distances.get(
            finger_id,
            0.0
        )
    )

    touch_travel_distances[finger_id] = (
        previous_distance + movement
    )

    touch_last_positions[finger_id] = position

    active_touches[finger_id] = position


# ============================================================
# GAME STATE BRIDGE
# ============================================================

func _set_game_dragging(
    value: bool
) -> void:
    if not is_instance_valid(game):
        return

    if not _game_has_property("dragging"):
        return

    game.set("dragging", value)


func _game_has_property(
    property_name: String
) -> bool:
    if not is_instance_valid(game):
        return false

    for property_data in game.get_property_list():
        if str(
            property_data.get("name", "")
        ) == property_name:
            return true

    return false


# ============================================================
# EVENT CONSUMPTION
# ============================================================

func _consume_input() -> void:
    if viewport_ref == null:
        return

    viewport_ref.set_input_as_handled()


# ============================================================
# PUBLIC STATUS API
# ============================================================

func is_multitouch_active() -> bool:
    return gesture_multitouch


func is_gesture_blocked() -> bool:
    return gesture_blocked


func is_dragging_active() -> bool:
    return gesture_dragging


func get_active_finger_count() -> int:
    return active_touches.size()


func get_drag_threshold() -> float:
    return drag_threshold


func get_gesture_sequence() -> int:
    return gesture_sequence


func get_gesture_duration_ms() -> int:
    if not gesture_active:
        return 0

    return (
        Time.get_ticks_msec()
        - gesture_start_time
    )


# ============================================================
# DIAGNOSTICS
# ============================================================

func get_input_statistics() -> Dictionary:
    return {
        "build": "96.2",
        "touch_events": total_touch_events,
        "drag_events": total_drag_events,
        "multitouch_gestures": total_multitouch_gestures,
        "blocked_releases": total_blocked_releases,
        "completed_gestures": total_completed_gestures,
        "active_fingers": active_touches.size(),
        "gesture_active": gesture_active,
        "gesture_blocked": gesture_blocked,
        "gesture_dragging": gesture_dragging,
        "screen_size": screen_size,
        "drag_threshold": drag_threshold
    }


func reset_input_statistics() -> void:
    total_touch_events = 0

    total_drag_events = 0

    total_multitouch_gestures = 0

    total_blocked_releases = 0

    total_completed_gestures = 0


func _debug(message: String) -> void:
    if not DEBUG_ENABLED:
        return

    print(
        "[ROC INPUT 96.2] " + message
    )


# ============================================================
# SAFETY
# ============================================================

func _exit_tree() -> void:
    _reset_all_state()
