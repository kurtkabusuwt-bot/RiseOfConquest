
extends Node3D

# RISE OF CONQUEST
# OTTOMAN CITY HALL - TEST 1.0
# Godot 4.4.1

const CITY_HALL = preload(
	"res://ottoman_cityhall_preview.glb"
)

const TARGET_WIDTH: float = 7.0

var game: Node3D
var model: Node3D
var old_center: Node3D
var old_decorations: Node3D

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	game = get_parent() as Node3D
	if game == null:
		return

	var instance = CITY_HALL.instantiate()
	if not (instance is Node3D):
		push_error("Osmanli 3D modeli acilamadi.")
		return

	model = instance as Node3D
	model.name = "OttomanCityHall"
	add_child(model)

	adjust_model()
	hide_original_building()

func adjust_model() -> void:
	var bounds := calculate_bounds(model)

	if bounds.size.length() < 0.001:
		push_warning("Model boyutlari okunamadi.")
		return

	var horizontal_size: float = maxf(
		bounds.size.x,
		bounds.size.z
	)

	if horizontal_size <= 0.001:
		return

	var scale_factor: float = \
		TARGET_WIDTH / horizontal_size

	model.scale = Vector3.ONE * scale_factor

	var center: Vector3 = bounds.get_center()

	model.position = Vector3(
		-center.x * scale_factor,
		-bounds.position.y * scale_factor,
		-center.z * scale_factor
	)

func calculate_bounds(root: Node3D) -> AABB:
	var stack: Array[Node] = [root]
	var found: bool = false
	var bounds := AABB()

	while not stack.is_empty():
		var node: Node = stack.pop_back()

		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D

			if mesh_node.mesh != null:
				var relative_transform: Transform3D = \
					root.global_transform.affine_inverse() \
					* mesh_node.global_transform

				var part_bounds: AABB = \
					relative_transform * mesh_node.get_aabb()

				if not found:
					bounds = part_bounds
					found = true
				else:
					bounds = bounds.merge(part_bounds)

		for child in node.get_children():
			stack.append(child)

	return bounds

func hide_original_building() -> void:
	old_center = game.get_node_or_null(
		"Merkez"
	) as Node3D

	if old_center != null:
		old_center.visible = false

	old_decorations = game.get_node_or_null(
		"CityUpgrade30/CityDecorations30/CastleUpgrades"
	) as Node3D

	if old_decorations != null:
		old_decorations.visible = false

func _process(_delta: float) -> void:
	if is_instance_valid(old_center):
		if old_center.visible:
			old_center.visible = false

	if is_instance_valid(old_decorations):
		if old_decorations.visible:
			old_decorations.visible = false

func _exit_tree() -> void:
	if is_instance_valid(old_center):
		old_center.visible = true

	if is_instance_valid(old_decorations):
		old_decorations.visible = true
