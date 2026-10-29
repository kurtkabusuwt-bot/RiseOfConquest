
extends Node3D

# RISE OF CONQUEST
# CINEMATIC INTRO 1.0
# Godot 4.4.1 - Android

const INTRO_DURATION: float = 12.0
const GAME_SCENE: String = "res://main.tscn"

var elapsed: float = 0.0
var entering: bool = false
var intro_finished: bool = false

var camera: Camera3D
var title_label: Label
var subtitle_label: Label
var enter_button: Button
var fade: ColorRect

var flames: Array[MeshInstance3D] = []
var flags: Array[MeshInstance3D] = []

func _ready() -> void:
	create_environment()
	create_castle()
	create_road()
	create_torches()
	create_flags()
	create_army()
	create_camera()
	create_interface()

func create_material(
	color: Color,
	emission: bool = false
) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85

	if emission:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.8

	return mat

func add_box(
	parent: Node3D,
	pos: Vector3,
	size: Vector3,
	color: Color,
	emission: bool = false
) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.material_override = create_material(
		color, emission
	)
	parent.add_child(node)
	return node

func create_environment() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()

	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(
		0.075, 0.085, 0.12
	)

	settings.ambient_light_source = \
		Environment.AMBIENT_SOURCE_COLOR

	settings.ambient_light_color = Color(
		0.30, 0.33, 0.42
	)

	settings.ambient_light_energy = 0.75
	settings.fog_enabled = true
	settings.fog_light_color = Color(
		0.22, 0.24, 0.29
	)
	settings.fog_density = 0.012

	environment.environment = settings
	add_child(environment)

	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(
		-40, -35, 0
	)
	moon.light_color = Color(
		0.75, 0.78, 0.95
	)
	moon.light_energy = 0.8
	moon.shadow_enabled = false
	add_child(moon)

	add_box(
		self,
		Vector3(0, -0.4, 0),
		Vector3(140, 0.8, 150),
		Color(0.19, 0.24, 0.19)
	)

func create_castle() -> void:
	var stone := Color(0.43, 0.43, 0.46)
	var dark := Color(0.29, 0.30, 0.34)

	add_box(
		self,
		Vector3(0, 7, -8),
		Vector3(34, 14, 4),
		stone
	)

	for x in [-15.0, 15.0]:
		add_box(
			self,
			Vector3(x, 11, -5),
			Vector3(7, 22, 7),
			dark
		)

		add_box(
			self,
			Vector3(x, 22.5, -5),
			Vector3(8, 2, 8),
			stone
		)

		for offset in [-2.5, 0.0, 2.5]:
			add_box(
				self,
				Vector3(x + offset, 24, -5),
				Vector3(1.3, 1.4, 7.5),
				stone
			)

	for x in range(-15, 16, 3):
		add_box(
			self,
			Vector3(float(x), 14.7, -8),
			Vector3(1.5, 1.4, 4.5),
			stone
		)

	add_box(
		self,
		Vector3(0, 13, -17),
		Vector3(13, 26, 13),
		dark
	)

	add_box(
		self,
		Vector3(0, 27, -17),
		Vector3(15, 2, 15),
		stone
	)

	add_box(
		self,
		Vector3(0, 5, -5.6),
		Vector3(7, 10, 0.7),
		Color(0.19, 0.13, 0.10)
	)

	for x in [-2.0, 2.0]:
		add_box(
			self,
			Vector3(x, 5, -5.1),
			Vector3(0.18, 9, 0.25),
			Color(0.47, 0.35, 0.24)
		)

	for y in range(2, 10, 2):
		add_box(
			self,
			Vector3(0, float(y), -5.0),
			Vector3(6.5, 0.16, 0.2),
			Color(0.47, 0.35, 0.24)
		)

func create_road() -> void:
	add_box(
		self,
		Vector3(0, 0.04, 36),
		Vector3(10, 0.08, 78),
		Color(0.38, 0.34, 0.29)
	)

	for z in range(3, 72, 5):
		for x in [-5.0, 5.0]:
			add_box(
				self,
				Vector3(x, 0.15, float(z)),
				Vector3(0.35, 0.30, 2.6),
				Color(0.28, 0.27, 0.26)
			)

func create_torches() -> void:
	for z in [8.0, 22.0, 36.0, 50.0]:
		for x in [-6.5, 6.5]:
			var holder := Node3D.new()
			holder.position = Vector3(x, 0, z)
			add_child(holder)

			add_box(
				holder,
				Vector3(0, 1.6, 0),
				Vector3(0.16, 3.2, 0.16),
				Color(0.31, 0.22, 0.14)
			)

			var flame := add_box(
				holder,
				Vector3(0, 3.4, 0),
				Vector3(0.55, 0.85, 0.55),
				Color(1.0, 0.51, 0.14),
				true
			)

			flames.append(flame)

			var light := OmniLight3D.new()
			light.position = Vector3(0, 3.4, 0)
			light.light_color = Color(
				1.0, 0.55, 0.25
			)
			light.light_energy = 0.8
			light.omni_range = 9.0
			light.shadow_enabled = false
			holder.add_child(light)

func create_flags() -> void:
	for x in [-13.0, 13.0]:
		add_box(
			self,
			Vector3(x, 27, -5),
			Vector3(0.15, 7, 0.15),
			Color(0.36, 0.25, 0.16)
		)

		var flag := add_box(
			self,
			Vector3(x + 1.5, 28.5, -5),
			Vector3(2.8, 1.8, 0.12),
			Color(0.63, 0.10, 0.14)
		)

		flags.append(flag)

func create_army() -> void:
	for row in range(3):
		for col in range(7):
			var x := (float(col) - 3.0) * 2.0
			var z := 14.0 + float(row) * 4.0

			var soldier := Node3D.new()
			soldier.position = Vector3(x, 0, z)
			add_child(soldier)

			add_box(
				soldier,
				Vector3(0, 1, 0),
				Vector3(0.65, 1.25, 0.5),
				Color(0.29, 0.33, 0.43)
			)

			add_box(
				soldier,
				Vector3(0, 1.95, 0),
				Vector3(0.48, 0.48, 0.48),
				Color(0.58, 0.59, 0.62)
			)

			for side in [-1.0, 1.0]:
				add_box(
					soldier,
					Vector3(side * 0.2, 0.35, 0),
					Vector3(0.18, 0.7, 0.25),
					Color(0.24, 0.25, 0.29)
				)

			add_box(
				soldier,
				Vector3(0.52, 1, 0),
				Vector3(0.12, 1.8, 0.12),
				Color(0.72, 0.73, 0.76)
			)

func create_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 65.0
	camera.position = Vector3(0, 7, 72)
	add_child(camera)
	camera.look_at(
		Vector3(0, 11, -10),
		Vector3.UP
	)

func create_interface() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)

	var center := VBoxContainer.new()
	center.set_anchors_preset(
		Control.PRESET_CENTER
	)
	center.position = Vector2(-300, -80)
	center.custom_minimum_size = Vector2(600, 180)
	center.add_theme_constant_override(
		"separation", 12
	)
	ui.add_child(center)

	title_label = Label.new()
	title_label.text = "RISE OF CONQUEST"
	title_label.horizontal_alignment = \
		HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override(
		"font_size", 48
	)
	title_label.add_theme_color_override(
		"font_color",
		Color(0.95, 0.79, 0.43)
	)
	title_label.modulate.a = 0.0
	center.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "KRALLIKLARIN YUKSELISI"
	subtitle_label.horizontal_alignment = \
		HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override(
		"font_size", 20
	)
	subtitle_label.modulate.a = 0.0
	center.add_child(subtitle_label)

	enter_button = Button.new()
	enter_button.text = "KRALLIGA GIR"
	enter_button.custom_minimum_size = Vector2(260, 55)
	enter_button.size_flags_horizontal = \
		Control.SIZE_SHRINK_CENTER
	enter_button.visible = false
	enter_button.pressed.connect(enter_game)
	center.add_child(enter_button)

	var skip := Button.new()
	skip.text = "ATLA"
	skip.position = Vector2(15, 15)
	skip.custom_minimum_size = Vector2(95, 42)
	skip.pressed.connect(show_menu)
	layer.add_child(skip)

	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)

func show_menu() -> void:
	elapsed = INTRO_DURATION
	intro_finished = true
	title_label.modulate.a = 1.0
	subtitle_label.modulate.a = 1.0
	enter_button.visible = true
	fade.modulate.a = 0.0

func enter_game() -> void:
	if entering:
		return

	entering = true
	get_tree().change_scene_to_file(
		GAME_SCENE
	)

func _process(delta: float) -> void:
	if entering:
		return

	elapsed += delta

	var t := clampf(
		elapsed / INTRO_DURATION,
		0.0,
		1.0
	)

	var start := Vector3(0, 7, 72)
	var finish := Vector3(18, 18, 36)

	camera.position = start.lerp(
		finish,
		smoothstep(0.0, 1.0, t)
	)

	camera.look_at(
		Vector3(0, 11, -10),
		Vector3.UP
	)

	if elapsed < 2.0:
		fade.modulate.a = \
			1.0 - elapsed / 2.0
	else:
		fade.modulate.a = 0.0

	if elapsed > 7.0:
		title_label.modulate.a = clampf(
			(elapsed - 7.0) / 2.0,
			0.0,
			1.0
		)

	if elapsed > 9.0:
		subtitle_label.modulate.a = clampf(
			(elapsed - 9.0) / 2.0,
			0.0,
			1.0
		)

	if elapsed >= INTRO_DURATION:
		intro_finished = true
		enter_button.visible = true

	for i in range(flames.size()):
		var flame: MeshInstance3D = flames[i]

		if not is_instance_valid(flame):
			continue

		var flicker := sin(
			elapsed * 8.0 + float(i)
		) * 0.12

		flame.scale = Vector3(
			1.0 + flicker,
			1.0 + flicker * 0.5,
			1.0 + flicker
		)

	for i in range(flags.size()):
		var flag: MeshInstance3D = flags[i]

		if is_instance_valid(flag):
			flag.scale.x = 1.0 + \
				sin(elapsed * 2.0 + float(i)) * 0.05
