
extends Node3D

# RISE OF CONQUEST - BUILD 92.6
# 3D GHOST + PLACEMENT INDICATORS
# Godot 4.4.1 / Android

const VALID_COLOR := Color(0.12, 0.9, 0.35, 0.42)
const INVALID_COLOR := Color(1.0, 0.18, 0.16, 0.5)
const GROUND_HEIGHT := 0.055

var game: Node3D
var ghost_root: Node3D
var model_root: Node3D
var guide_root: Node3D

var ghost_material: StandardMaterial3D
var guide_material: StandardMaterial3D

var last_pointer := Vector2.ZERO
var has_pointer := false
var touch_active := false
var was_placing := false
var last_kind := ""

func _ready() -> void:
	set_process(false)
	call_deferred("_initialize")

func _initialize() -> void:
	game = get_parent() as Node3D
	if not is_instance_valid(game):
		return

	ghost_material = _make_material(VALID_COLOR)
	guide_material = _make_material(VALID_COLOR)

	ghost_root = Node3D.new()
	ghost_root.name = "ConstructionGhost"
	add_child(ghost_root)

	model_root = Node3D.new()
	model_root.name = "BuildingModel"
	ghost_root.add_child(model_root)

	guide_root = Node3D.new()
	guide_root.name = "PlacementGuides"
	ghost_root.add_child(guide_root)

	ghost_root.visible = false
	set_process(true)

func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	material.albedo_color = color
	return material

func _input(event: InputEvent) -> void:
	if not is_instance_valid(game):
		return

	if not bool(game.get("placing")):
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			touch_active = true
			last_pointer = event.position
			has_pointer = true
		else:
			touch_active = false

	elif event is InputEventScreenDrag:
		if touch_active:
			last_pointer = event.position
			has_pointer = true

	elif event is InputEventMouseMotion:
		last_pointer = event.position
		has_pointer = true

func _process(_delta: float) -> void:
	if not is_instance_valid(game):
		return

	if not is_instance_valid(ghost_root):
		return

	var placing := bool(game.get("placing"))

	if not placing:
		ghost_root.visible = false
		was_placing = false
		has_pointer = false
		touch_active = false
		last_kind = ""
		return

	if bool(game.get("world_mode")):
		ghost_root.visible = false
		return

	if bool(game.get("battle_active")):
		ghost_root.visible = false
		return

	var camera: Camera3D = game.get("camera") as Camera3D

	if not is_instance_valid(camera):
		ghost_root.visible = false
		return

	if not was_placing:
		was_placing = true
		has_pointer = false
		last_pointer = (
			get_viewport().get_visible_rect().size * 0.5
		)

	var kind := str(game.get("selected_building"))

	if kind != last_kind:
		last_kind = kind
		_build_ghost(kind)

	if not has_pointer:
		last_pointer = (
			get_viewport().get_visible_rect().size * 0.5
		)

	var origin := camera.project_ray_origin(last_pointer)
	var direction := camera.project_ray_normal(last_pointer)

	if absf(direction.y) < 0.0001:
		ghost_root.visible = false
		return

	var distance := -origin.y / direction.y

	if distance <= 0.0:
		ghost_root.visible = false
		return

	var hit := origin + direction * distance

	var target := Vector3(
		float(roundi(hit.x)),
		0.0,
		float(roundi(hit.z))
	)

	ghost_root.global_position = target
	ghost_root.visible = true

	var problem := ""

	if game.has_method("construction_check"):
		problem = str(
			game.call("construction_check", kind, target)
		)

	var color := VALID_COLOR
	if not problem.is_empty():
		color = INVALID_COLOR

	ghost_material.albedo_color = color

	guide_material.albedo_color = Color(
		color.r,
		color.g,
		color.b,
		0.8
	)

func _clear_root(root: Node3D) -> void:
	for child in root.get_children():
		root.remove_child(child)
		child.queue_free()

func _add_box(
	root: Node3D,
	part_name: String,
	size: Vector3,
	offset: Vector3,
	material: Material
) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name

	var mesh := BoxMesh.new()
	mesh.size = size

	part.mesh = mesh
	part.material_override = material
	part.position = offset
	root.add_child(part)

func _add_cylinder(
	part_name: String,
	radius: float,
	height: float,
	offset: Vector3
) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name

	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height

	part.mesh = mesh
	part.material_override = ghost_material
	part.position = offset
	model_root.add_child(part)

func _footprint(kind: String) -> Vector2:
	match kind:
		"Merkez":
			return Vector2(6.0, 6.0)
		"Kışla":
			return Vector2(4.8, 4.1)
		"Çiftlik":
			return Vector2(3.7, 3.7)
		"Kereste":
			return Vector2(3.6, 3.2)
		"Taşocağı":
			return Vector2(3.7, 3.7)
		"Kule":
			return Vector2(3.3, 3.3)
		"Ev":
			return Vector2(3.7, 3.7)
		_:
			return Vector2(4.0, 4.0)

func _build_guides(kind: String) -> void:
	_clear_root(guide_root)

	var size := _footprint(kind)
	var half_x := size.x * 0.5
	var half_z := size.y * 0.5
	var line_width := 0.12

	# Four edges around the building footprint.
	for side in [-1.0, 1.0]:
		_add_box(
			guide_root,
			"EdgeX",
			Vector3(size.x, 0.06, line_width),
			Vector3(
				0.0,
				GROUND_HEIGHT,
				side * half_z
			),
			guide_material
		)

		_add_box(
			guide_root,
			"EdgeZ",
			Vector3(line_width, 0.06, size.y),
			Vector3(
				side * half_x,
				GROUND_HEIGHT,
				0.0
			),
			guide_material
		)

	# Ground cross marks the placement center.
	_add_box(
		guide_root,
		"CenterX",
		Vector3(1.0, 0.065, 0.1),
		Vector3(0.0, GROUND_HEIGHT + 0.015, 0.0),
		guide_material
	)

	_add_box(
		guide_root,
		"CenterZ",
		Vector3(0.1, 0.065, 1.0),
		Vector3(0.0, GROUND_HEIGHT + 0.015, 0.0),
		guide_material
	)

func _model_box(
	part_name: String,
	size: Vector3,
	offset: Vector3
) -> void:
	_add_box(
		model_root,
		part_name,
		size,
		offset,
		ghost_material
	)

func _build_ghost(kind: String) -> void:
	_clear_root(model_root)
	_build_guides(kind)

	match kind:
		"Merkez":
			_model_box(
				"PalaceBase",
				Vector3(5.5, 3.0, 5.5),
				Vector3(0, 1.5, 0)
			)
			_add_cylinder(
				"PalaceDome",
				2.2, 1.4,
				Vector3(0, 3.7, 0)
			)
			for side in [-1.0, 1.0]:
				_add_cylinder(
					"Minaret",
					0.32, 5.0,
					Vector3(side * 2.5, 2.5, -2.8)
				)

		"Kışla":
			_model_box(
				"Barracks",
				Vector3(4.2, 2.4, 3.5),
				Vector3(0, 1.2, 0)
			)
			_model_box(
				"Roof",
				Vector3(4.7, 0.55, 4.0),
				Vector3(0, 2.65, 0)
			)

		"Ev":
			_model_box(
				"House",
				Vector3(3.0, 2.4, 3.0),
				Vector3(0, 1.2, 0)
			)
			_model_box(
				"Roof",
				Vector3(3.4, 0.65, 3.4),
				Vector3(0, 2.7, 0)
			)

		"Kule":
			_add_cylinder(
				"Tower",
				1.2, 5.0,
				Vector3(0, 2.5, 0)
			)
			_add_cylinder(
				"Top",
				1.6, 0.6,
				Vector3(0, 5.2, 0)
			)

		"Çiftlik":
			_model_box(
				"Field",
				Vector3(3.5, 0.15, 3.5),
				Vector3(0, 0.1, 0)
			)
			for i in range(4):
				_model_box(
					"Crops",
					Vector3(0.3, 0.55, 2.7),
					Vector3(-1.1 + i * 0.7, 0.38, 0)
				)

		"Kereste":
			_model_box(
				"Workshop",
				Vector3(3.0, 1.8, 2.5),
				Vector3(0, 0.9, 0)
			)
			_model_box(
				"Roof",
				Vector3(3.4, 0.4, 2.9),
				Vector3(0, 2.0, 0)
			)

		"Taşocağı":
			_model_box(
				"StoneBase",
				Vector3(3.5, 0.35, 3.5),
				Vector3(0, 0.18, 0)
			)
			for i in range(3):
				_model_box(
					"Stone",
					Vector3(0.9, 0.9, 0.9),
					Vector3(-1.0 + i, 0.65, 0)
				)

		_:
			_model_box(
				"Default",
				Vector3(4.0, 2.0, 4.0),
				Vector3(0, 1.0, 0)
			)
