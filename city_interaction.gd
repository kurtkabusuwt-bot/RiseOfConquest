
extends Node

# RISE OF CONQUEST - BUILD 91.2
# MOBILE CITY BUILDING INTERACTION
# Godot 4.4.1 / Android

const HOLD_TIME := 0.55
const MOVE_LIMIT := 47.0
const MIN_SPACING := 4.5
const SAVE_PATH := "user://city_layout_v3.json"

const TYPES := [
	"Merkez", "Ev", "Kule", "Kışla",
	"Çiftlik", "Kereste", "Taşocağı"
]

var game: Node3D
var camera: Camera3D
var overlay: Control
var fps_label: Label
var names_button: Button
var labels: Dictionary = {}

var finger := -1
var pressing := false
var holding := false
var names_enabled := false
var hold_timer := 0.0
var press_point := Vector2.ZERO
var selected: Node3D
var selected_origin := Vector3.ZERO
var moved := false
var fps_timer := 0.0
var refresh_timer := 0.0

func _ready() -> void:
	call_deferred("initialize")

func initialize() -> void:
	game = get_parent() as Node3D

	if game == null:
		return

	camera = game.get("camera") as Camera3D

	create_interface()
	load_positions()
	refresh_labels()

func create_interface() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)

	fps_label = Label.new()
	fps_label.set_anchors_preset(
		Control.PRESET_TOP_RIGHT
	)
	fps_label.offset_left = -150
	fps_label.offset_right = -12
	fps_label.offset_top = 58
	fps_label.offset_bottom = 92
	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fps_label.add_theme_font_size_override("font_size", 18)
	overlay.add_child(fps_label)

	names_button = Button.new()
	names_button.text = "BINA ISIMLERI"
	names_button.position = Vector2(15, 70)
	names_button.custom_minimum_size = Vector2(170, 48)
	names_button.toggle_mode = true
	overlay.add_child(names_button)

	names_button.toggled.connect(
		func(enabled: bool) -> void:
			names_enabled = enabled
			update_labels()
	)

func _process(delta: float) -> void:
	if game == null or camera == null:
		return

	fps_timer += delta
	refresh_timer += delta

	if fps_timer >= 0.5:
		fps_timer = 0.0
		var fps := Engine.get_frames_per_second()
		fps_label.text = "FPS: %d" % fps

	if refresh_timer >= 0.5:
		refresh_timer = 0.0
		refresh_labels()

	if pressing and not holding:
		if not interaction_allowed():
			cancel_press()
		else:
			hold_timer += delta

			if hold_timer >= HOLD_TIME:
				begin_hold()

	if names_enabled or holding:
		update_labels()

func building_kind(node: Node3D) -> String:
	var name_text := String(node.name)

	for kind in TYPES:
		if name_text == kind:
			return kind

		if name_text.begins_with(kind):
			var suffix := name_text.substr(kind.length())

			if suffix.is_valid_int():
				return kind

		if name_text.begins_with("@" + kind + "@"):
			return kind

	return ""

func get_buildings() -> Array[Node3D]:
	var result: Array[Node3D] = []

	if game == null:
		return result

	for child in game.get_children():
		if child is Node3D:
			var building := child as Node3D

			if building_kind(building) != "":
				result.append(building)

	return result

func building_title(node: Node3D) -> String:
	match building_kind(node):
		"Merkez":
			return "Osmanlı Belediye Binası"
		"Kule":
			return "Gözetleme Kulesi"
		"Kereste":
			return "Kereste Atölyesi"
		"Taşocağı":
			return "Taş Ocağı"

	return building_kind(node)

func refresh_labels() -> void:
	if overlay == null:
		return

	for building in get_buildings():
		var id := building.get_instance_id()

		if labels.has(id):
			continue

		var label := Label.new()
		label.text = building_title(building)
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override(
			"font_color", Color.WHITE
		)
		label.add_theme_color_override(
			"font_shadow_color", Color.BLACK
		)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.visible = false
		overlay.add_child(label)

		labels[id] = {
			"building": building,
			"label": label
		}

	update_labels()

func update_labels() -> void:
	if camera == null:
		return

	for id in labels.keys():
		var entry: Dictionary = labels[id]
		var building: Node3D = entry["building"]
		var label: Label = entry["label"]

		if not is_instance_valid(building):
			label.queue_free()
			labels.erase(id)
			continue

		var height := 3.5

		if building_kind(building) == "Merkez":
			height = 7.0
		elif building_kind(building) == "Kule":
			height = 5.0

		var world_pos := building.global_position
		world_pos.y += height

		var visible_now := names_enabled or holding

		if camera.is_position_behind(world_pos):
			visible_now = false

		label.visible = visible_now

		if visible_now:
			var screen_pos := camera.unproject_position(
				world_pos
			)
			label.position = screen_pos - Vector2(
				label.size.x * 0.5, 0
			)

func interaction_allowed() -> bool:
	if game == null or camera == null:
		return false

	if bool(game.get("world_mode")):
		return false

	if bool(game.get("placing")):
		return false

	if bool(game.get("battle_active")):
		return false

	if bool(game.get("ruler_mode")):
		return false

	var mobile := game.get_node_or_null("MobileMenu90")

	if mobile != null:
		var panel: Variant = mobile.get("action_panel")

		if panel is Control and panel.visible:
			return false

	return true

func screen_to_ground(pos: Vector2) -> Vector3:
	var origin := camera.project_ray_origin(pos)
	var direction := camera.project_ray_normal(pos)

	if absf(direction.y) < 0.0001:
		return Vector3.INF

	var distance := -origin.y / direction.y

	if distance <= 0.0:
		return Vector3.INF

	return origin + direction * distance

func find_building(pos: Vector2) -> Node3D:
	var best: Node3D = null
	var best_distance := INF

	for building in get_buildings():
		var height := 2.0
		var radius := 85.0

		if building_kind(building) == "Merkez":
			height = 4.0
			radius = 140.0

		var center := building.global_position
		center.y += height

		if camera.is_position_behind(center):
			continue

		var screen_center := camera.unproject_position(center)
		var distance := pos.distance_to(screen_center)

		if distance < radius and distance < best_distance:
			best_distance = distance
			best = building

	return best

func _input(event: InputEvent) -> void:
	if not interaction_allowed():
		if finger != -1:
			cancel_press()
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			if finger != -1:
				cancel_press()
				return

			start_press(event.position, event.index)

		elif event.index == finger:
			var was_holding := holding
			finish_press()

			if was_holding:
				get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag:
		if event.index != finger:
			return

		if holding:
			move_building(event.position)
			get_viewport().set_input_as_handled()

		elif event.position.distance_to(press_point) > 22.0:
			pressing = false

	elif event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if event.pressed:
			start_press(event.position, -2)

		elif finger == -2:
			var was_holding := holding
			finish_press()

			if was_holding:
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		if finger != -2:
			return

		if holding:
			move_building(event.position)
			get_viewport().set_input_as_handled()

		elif event.position.distance_to(press_point) > 22.0:
			pressing = false

func start_press(pos: Vector2, index: int) -> void:
	if finger != -1:
		return

	var screen := get_viewport().get_visible_rect().size

	if pos.y < 145.0:
		return

	if pos.y > screen.y - 100.0:
		return

	var building := find_building(pos)

	if building == null:
		return

	finger = index
	pressing = true
	holding = false
	moved = false
	hold_timer = 0.0
	press_point = pos
	selected = building
	selected_origin = building.position

func begin_hold() -> void:
	if not pressing or selected == null:
		return

	holding = true
	pressing = false
	game.set("dragging", true)
	update_labels()

func valid_position(target: Vector3) -> bool:
	if absf(target.x) > MOVE_LIMIT:
		return false

	if absf(target.z) > MOVE_LIMIT:
		return false

	for other in get_buildings():
		if other == selected:
			continue

		var distance := Vector2(
			target.x - other.position.x,
			target.z - other.position.z
		).length()

		if distance < MIN_SPACING:
			return false

	return true

func move_building(pos: Vector2) -> void:
	if not holding or selected == null:
		return

	var ground := screen_to_ground(pos)

	if not ground.is_finite():
		return

	var target := Vector3(
		roundf(ground.x),
		selected.position.y,
		roundf(ground.z)
	)

	if not valid_position(target):
		return

	var offset := target - selected.position

	if offset.length_squared() < 0.001:
		return

	selected.position = target
	moved = true

	if building_kind(selected) == "Merkez":
		var preview := game.get_node_or_null(
			"OttomanCityHallPreview"
		) as Node3D

		if preview != null:
			preview.position += offset

	update_labels()

func finish_press() -> void:
	if holding and selected != null and moved:
		save_positions()

	var was_holding := holding

	finger = -1
	pressing = false
	holding = false
	moved = false
	selected = null

	if was_holding:
		game.set("dragging", true)

	update_labels()

func cancel_press() -> void:
	finger = -1
	pressing = false
	holding = false
	moved = false
	selected = null
	update_labels()

func save_positions() -> void:
	var entries: Array[Dictionary] = []

	for building in get_buildings():
		entries.append({
			"kind": building_kind(building),
			"x": building.position.x,
			"z": building.position.z
		})

	var file := FileAccess.open(
		SAVE_PATH, FileAccess.WRITE
	)

	if file != null:
		file.store_string(JSON.stringify(entries))
		file.close()

func load_positions() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(
		SAVE_PATH, FileAccess.READ
	)

	if file == null:
		return

	var data: Variant = JSON.parse_string(
		file.get_as_text()
	)
	file.close()

	if not (data is Array):
		return

	var buildings := get_buildings()
	var used: Dictionary = {}

	for entry in data:
		if not (entry is Dictionary):
			continue

		var kind := str(entry.get("kind", ""))
		var target: Node3D = null

		for building in buildings:
			var id := building.get_instance_id()

			if building_kind(building) == kind and not used.has(id):
				target = building
				used[id] = true
				break

		if target == null:
			continue

		var new_pos := Vector3(
			clampf(
				float(entry.get("x", target.position.x)),
				-MOVE_LIMIT,
				MOVE_LIMIT
			),
			target.position.y,
			clampf(
				float(entry.get("z", target.position.z)),
				-MOVE_LIMIT,
				MOVE_LIMIT
			)
		)

		var valid := true

		for other in buildings:
			if other == target:
				continue

			var distance := Vector2(
				new_pos.x - other.position.x,
				new_pos.z - other.position.z
			).length()

			if distance < MIN_SPACING:
				valid = false
				break

		if not valid:
			continue

		var offset := new_pos - target.position
		target.position = new_pos

		if building_kind(target) == "Merkez":
			var preview := game.get_node_or_null(
				"OttomanCityHallPreview"
			) as Node3D

			if preview != null:
				preview.position += offset