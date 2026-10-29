
extends Control

# RISE OF CONQUEST
# CINEMATIC VIDEO INTRO 2.0
# Godot 4.4.1 / Android

const GAME_SCENE: String = "res://main.tscn"
const INTRO_VIDEO = preload("res://rise_of_conquest_intro.ogv")

var video: VideoStreamPlayer
var menu_layer: Control
var title_label: Label
var subtitle_label: Label
var enter_button: Button
var skip_button: Button
var background: ColorRect

var finished: bool = false
var entering: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	build_background()
	build_video()
	build_menu()
	build_skip_button()

	video.play()

func build_background() -> void:
	background = ColorRect.new()
	background.color = Color(0.025, 0.025, 0.035)
	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

func build_video() -> void:
	video = VideoStreamPlayer.new()
	video.name = "WarCinematicVideo"
	video.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	video.expand = true
	video.stream = INTRO_VIDEO
	video.loop = false
	video.finished.connect(on_video_finished)
	add_child(video)

func build_menu() -> void:
	menu_layer = Control.new()
	menu_layer.name = "MainMenu"
	menu_layer.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	menu_layer.visible = false
	add_child(menu_layer)

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.65)
	overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	menu_layer.add_child(center)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(550, 220)
	content.add_theme_constant_override(
		"separation", 22
	)
	center.add_child(content)

	title_label = Label.new()
	title_label.text = "RISE OF CONQUEST"
	title_label.horizontal_alignment = \
		HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override(
		"font_size", 48
	)
	title_label.add_theme_color_override(
		"font_color",
		Color(0.96, 0.78, 0.38)
	)
	content.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "KRALLIKLARIN YUKSELISI"
	subtitle_label.horizontal_alignment = \
		HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override(
		"font_size", 20
	)
	subtitle_label.add_theme_color_override(
		"font_color",
		Color(0.85, 0.85, 0.85)
	)
	content.add_child(subtitle_label)

	enter_button = Button.new()
	enter_button.text = "KRALLIGA GIR"
	enter_button.custom_minimum_size = Vector2(270, 65)
	enter_button.size_flags_horizontal = \
		Control.SIZE_SHRINK_CENTER
	enter_button.add_theme_font_size_override(
		"font_size", 24
	)
	enter_button.pressed.connect(enter_game)
	content.add_child(enter_button)

func build_skip_button() -> void:
	skip_button = Button.new()
	skip_button.text = "ATLA"
	skip_button.name = "SkipIntro"
	skip_button.custom_minimum_size = Vector2(110, 48)

	skip_button.set_anchors_preset(
		Control.PRESET_TOP_RIGHT
	)
	skip_button.position = Vector2(-130, 20)

	skip_button.pressed.connect(skip_intro)
	add_child(skip_button)

func skip_intro() -> void:
	if finished:
		return

	video.stop()
	on_video_finished()

func on_video_finished() -> void:
	if finished:
		return

	finished = true
	video.hide()
	skip_button.hide()
	menu_layer.show()

func enter_game() -> void:
	if entering:
		return

	entering = true
	get_tree().change_scene_to_file(
		GAME_SCENE
	)

func _unhandled_key_input(
	event: InputEvent
) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not finished:
			skip_intro()
