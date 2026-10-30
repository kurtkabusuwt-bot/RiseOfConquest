
extends Node3D

# RISE OF CONQUEST - BUILD 92.5
# 3D CONSTRUCTION GHOST SYSTEM
# Godot 4.4.1 / Android

const VALID_COLOR := Color(0.12, 0.9, 0.35, 0.4)
const INVALID_COLOR := Color(1.0, 0.18, 0.16, 0.48)

var game: Node3D
var ghost_root: Node3D
var ghost_material: StandardMaterial3D

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

	ghost_material = StandardMaterial3D.new()
	ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	ghost_material.albedo_color = VALID_COLOR

	ghost_root = Node3D.new()
	ghost_root.name = "ConstructionGhost"
	add_child(ghost_root)
	ghost_root.visible = false

	set_process(true)

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

	if bool(game.get("world_mode")) or bool(game.get("battle_active")):
		ghost_root.visible = false
		return

	var camera: Camera3D = game.get("camera") as Camera3D

	if not is_instance_valid(camera):
		ghost_root.visible = false
		return

	if not was_placing:
		was_placing = true
		has_pointer = false
		last_pointer = get_viewport().get_visible_rect().size * 0.5

	var kind := str(game.get("selected_building"))

	if kind != last_kind:
		last_kind = kind
		_build_ghost(kind)

	if not has_pointer:
		last_pointer = get_viewport().get_visible_rect().size * 0.5

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

	ghost_material.albedo_color = (
		VALID_COLOR if problem.is_empty() else INVALID_COLOR
	)

func _clear_ghost() -> void:
	for child in ghost_root.get_children():
		ghost_root.remove_child(child)
		child.queue_free()

func _add_box(
	part_name: String,
	size: Vector3,
	offset: Vector3
) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name

	var mesh := BoxMesh.new()
	mesh.size = size

	part.mesh = mesh
	part.material_override = ghost_material
	part.position = offset
	ghost_root.add_child(part)

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
	ghost_root.add_child(part)

func _build_ghost(kind: String) -> void:
	_clear_ghost()

	match kind:
		"Merkez":
			_add_box(
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
			_add_box(
				"Barracks",
				Vector3(4.2, 2.4, 3.5),
				Vector3(0, 1.2, 0)
			)
			_add_box(
				"Roof",
				Vector3(4.7, 0.55, 4.0),
				Vector3(0, 2.65, 0)
			)

		"Ev":
			_add_box(
				"House",
				Vector3(3.0, 2.4, 3.0),
				Vector3(0, 1.2, 0)
			)
			_add_box(
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
			_add_box(
				"Field",
				Vector3(3.5, 0.15, 3.5),
				Vector3(0, 0.1, 0)
			)
			for i in range(4):
				_add_box(
					"Crops",
					Vector3(0.3, 0.55, 2.7),
					Vector3(-1.1 + i * 0.7, 0.38, 0)
				)

		"Kereste":
			_add_box(
				"Workshop",
				Vector3(3.0, 1.8, 2.5),
				Vector3(0, 0.9, 0)
			)
			_add_box(
				"Roof",
				Vector3(3.4, 0.4, 2.9),
				Vector3(0, 2.0, 0)
			)

		"Taşocağı":
			_add_box(
				"StoneBase",
				Vector3(3.5, 0.35, 3.5),
				Vector3(0, 0.18, 0)
			)
			for i in range(3):
				_add_box(
					"Stone",
					Vector3(0.9, 0.9, 0.9),
					Vector3(-1.0 + i, 0.65, 0)
				)

		_:
			_add_box(
				"Default",
				Vector3(4.0, 2.0, 4.0),
				Vector3(0, 1.0, 0)
			)
