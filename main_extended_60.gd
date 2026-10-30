
# RISE OF CONQUEST - BUILD 93.5
# EXTENDED CITY SAVE LOADER

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		return

	var parsed: Variant = JSON.parse_string(
		file.get_as_text()
	)
	file.close()

	if not (parsed is Dictionary):
		return

	var data: Dictionary = parsed

	coins = int(data.get("coins", coins))
	woods = int(data.get("woods", woods))
	stones = int(data.get("stones", stones))
	foods = int(data.get("foods", foods))

	var entries: Variant = data.get("buildings", [])

	if entries is Array:
		for entry in entries:
			if not (entry is Dictionary):
				continue

			var kind := str(entry.get("kind", ""))

			if kind not in [
				"Ev", "Kule", "Kışla",
				"Çiftlik", "Kereste", "Taşocağı"
			]:
				continue

			var x := int(entry.get("x", 0))
			var z := int(entry.get("z", 0))

			if absi(x) > 47 or absi(z) > 47:
				continue

			var position := Vector3(x, 0, z)

			create_building(kind, position)

			var saved_id := str(entry.get("id", ""))
			var building := _find_building_at(
				kind, position
			)

			if is_instance_valid(building):
				if not saved_id.is_empty():
					building.set_meta(
						"building_id", saved_id
					)
				else:
					saved_id = ensure_building_id(
						building
					)

			buildings_saved.append({
				"id": saved_id,
				"kind": kind,
				"x": x,
				"z": z
			})

	ruler.position.x = clampf(
		float(data.get("ruler_x", 3.0)),
		-14.0, 14.0
	)

	ruler.position.z = clampf(
		float(data.get("ruler_z", 4.0)),
		-14.0, 14.0
	)

	status = "Kayitli sehrin yuklendi."
