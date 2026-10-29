
extends "res://main.gd"

# RISE OF CONQUEST - EXTENDED MAIN 6.0
# Godot 4.4.1 / Android
# Keeps all original game systems and saves.

const EXPANDED_BUILD_LIMIT := 43.0
const EXPANDED_CAMERA_MAX := 125.0

func zoom_camera(delta: float) -> void:
	if world_mode:
		camera_distance = clampf(
			camera_distance + delta,
			35.0,
			155.0
		)
	else:
		camera_distance = clampf(
			camera_distance + delta,
			12.0,
			EXPANDED_CAMERA_MAX
		)
	update_camera()

func handle_ground_tap(screen_pos: Vector2) -> void:
	if (
		not world_mode
		and not placing
		and not ruler_mode
		and not battle_active
	):
		return

	var ray_origin := camera.project_ray_origin(
		screen_pos
	)
	var ray_direction := camera.project_ray_normal(
		screen_pos
	)

	if absf(ray_direction.y) < 0.0001:
		return

	var t := -ray_origin.y / ray_direction.y

	if t <= 0.0:
		return

	var hit := ray_origin + ray_direction * t

	if world_mode:
		world_tap(hit)
		return

	if battle_active and not placing and not ruler_mode:
		if (
			hit.x > -13.0
			and hit.x < -3.0
			and hit.z > 3.5
			and hit.z < 12.5
		):
			var best := -1
			var best_dist := 2.1

			for j in range(3, battle_units.size()):
				var enemy: Dictionary = battle_units[j]

				if enemy["hp"] <= 0.0:
					continue

				var enemy_node: Node3D = enemy["node"]
				var dist := enemy_node.position.distance_to(
					Vector3(hit.x, 0, hit.z)
				)

				if dist < best_dist:
					best_dist = dist
					best = j

			if best >= 0:
				selected_target = best
				status = (
					"Dusman hedefi secildi: %d"
					% (best - 2)
				)
			else:
				status = "Kirmizi askere dokun."

			update_ui()
		return

	if (
		absf(hit.x) > EXPANDED_BUILD_LIMIT
		or absf(hit.z) > EXPANDED_BUILD_LIMIT
	):
		status = "Sehir sinirinin disindasin."
		update_ui()
		return

	if ruler_mode:
		ruler_target = Vector3(hit.x, 0, hit.z)
		ruler_walking = true
		status = "Hukumdar ilerliyor."
		update_ui()
		return

	var grid_pos := Vector2i(
		roundi(hit.x),
		roundi(hit.z)
	)

	var min_distance := 4.0
	if selected_building != "Ev":
		min_distance = 4.5

	for cell in occupied:
		if Vector2(grid_pos).distance_to(
			Vector2(cell)
		) < min_distance:
			status = "Burası dolu. Baska yer sec."
			update_ui()
			return

	if selected_building == "Ev":
		if woods < 100:
			status = "Yeterli odun yok."
			update_ui()
			return
		woods -= 100

	elif selected_building == "Kışla":
		if woods < 200:
			status = "Yeterli odun yok."
			update_ui()
			return
		woods -= 200

	elif (
		selected_building == "Çiftlik"
		or selected_building == "Taşocağı"
	):
		var cost := 80
		if selected_building == "Taşocağı":
			cost = 100

		if woods < cost:
			status = "Yeterli odun yok."
			update_ui()
			return

		woods -= cost

	elif selected_building == "Kereste":
		if coins < 100:
			status = "Yeterli altin yok."
			update_ui()
			return
		coins -= 100

	elif selected_building == "Kule":
		if coins < 150:
			status = "Yeterli altin yok."
			update_ui()
			return
		coins -= 150

	create_building(
		selected_building,
		Vector3(
			float(grid_pos.x),
			0.0,
			float(grid_pos.y)
		)
	)

	buildings_saved.append({
		"kind": selected_building,
		"x": grid_pos.x,
		"z": grid_pos.y
	})

	save_game(false)
	status = "%s insa edildi!" % selected_building
	update_ui()
