
extends Node3D

# RISE OF CONQUEST - BUILD 92.2
# CONSTRUCTION PLACEMENT PREVIEW
# Godot 4.4.1 / Android

const VALID_COLOR := Color(0.15, 0.9, 0.35, 0.42)
const INVALID_COLOR := Color(1.0, 0.2, 0.18, 0.48)

var game: Node3D
var preview: MeshInstance3D
var preview_material: StandardMaterial3D
var last_pointer := Vector2.ZERO
var has_pointer := false
var last_kind := ""

func _ready() -> void:
	call_deferred("_initialize")

func _initialize() -> void:
	game = get_tree().current_scene

	if not is_instance_valid(game):
		return

	_create_preview()
	set_process(true)

func _create_preview() -> void:
	preview = MeshInstance3D.new()
	preview.name = "ConstructionGhost"
	add_child(preview)

	var mesh := BoxMesh.new()
	mesh.size = Vector3(4.0, 0.18, 4.0)
	preview.mesh = mesh

	preview_material = StandardMaterial3D.new()
	preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	preview_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	preview_material.albedo_color = VALID_COLOR
	preview_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	preview.material_override = preview_material

	preview.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			last_pointer = event.position
			has_pointer = true

	elif event is InputEventScreenDrag:
		last_pointer = event.position
		has_pointer = true

	elif event is InputEventMouseMotion:
		last_pointer = event.position
		has_pointer = true

func _process(_delta: float) -> void:
	if not is_instance_valid(game):
		return

	if not is_instance_valid(preview):
		return

	if not bool(game.get("placing")):
		preview.visible = false
		last_kind = ""
		return

	if bool(game.get("world_mode")):
		preview.visible = false
		return

	if bool(game.get("battle_active")):
		preview.visible = false
		return

	var camera: Camera3D = game.get("camera") as Camera3D

	if not is_instance_valid(camera):
		preview.visible = false
		return

	var kind := str(game.get("selected_building"))

	if kind != last_kind:
		last_kind = kind
		_update_mesh_size(kind)

	if not has_pointer:
		last_pointer = get_viewport().get_visible_rect().size * 0.5

	var origin := camera.project_ray_origin(last_pointer)
	var direction := camera.project_ray_normal(last_pointer)

	if absf(direction.y) < 0.0001:
		preview.visible = false
		return

	var distance := -origin.y / direction.y

	if distance <= 0.0:
		preview.visible = false
		return

	var hit := origin + direction * distance

	var target := Vector3(
		float(roundi(hit.x)),
		0.12,
		float(roundi(hit.z))
	)

	preview.global_position = target
	preview.visible = true

	var problem := ""

	if game.has_method("construction_check"):
		problem = str(
			game.call(
				"construction_check",
				kind,
				Vector3(target.x, 0.0, target.z)
			)
		)

	if problem.is_empty():
		preview_material.albedo_color = VALID_COLOR
	else:
		preview_material.albedo_color = INVALID_COLOR

func _update_mesh_size(kind: String) -> void:
	if not is_instance_valid(preview):
		return

	var mesh := preview.mesh as BoxMesh

	if mesh == null:
		return

	match kind:
		"Merkez":
			mesh.size = Vector3(6.0, 0.18, 6.0)
		"Kışla":
			mesh.size = Vector3(4.7, 0.18, 4.0)
		"Çiftlik":
			mesh.size = Vector3(3.5, 0.18, 3.5)
		"Kereste":
			mesh.size = Vector3(3.5, 0.18, 3.0)
		"Taşocağı":
			mesh.size = Vector3(3.5, 0.18, 3.5)
		"Kule":
			mesh.size = Vector3(3.0, 0.18, 3.0)
		"Ev":
			mesh.size = Vector3(3.5, 0.18, 3.5)
		_:
			mesh.size = Vector3(4.0, 0.18, 4.0)
