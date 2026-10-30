
func restore_building_ids() -> void:
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
	var grouped: Dictionary = {}

	for building in buildings:
		var kind := building_kind(building)
		if not grouped.has(kind):
			grouped[kind] = []
		grouped[kind].append(building)

	for entry in data:
		if not (entry is Dictionary):
			continue

		var kind := str(entry.get("kind", ""))
		if not grouped.has(kind):
			continue

		var saved_id := str(entry.get("id", ""))
		var x := float(entry.get("x", 0.0))
		var z := float(entry.get("z", 0.0))

		if absf(x) > MOVE_LIMIT:
			continue
		if absf(z) > MOVE_LIMIT:
			continue

		var target: Node3D = null
		var candidates: Array = grouped[kind]

		for candidate in candidates:
			if used.has(candidate.get_instance_id()):
				continue

			if not saved_id.is_empty():
				if str(candidate.get_meta(
					"building_id", ""
				)) == saved_id:
					target = candidate
					break

		if target == null:
			for candidate in candidates:
				if used.has(candidate.get_instance_id()):
					continue

				var current_id := str(
					candidate.get_meta(
						"building_id", ""
					)
				)

				if not current_id.is_empty():
					continue

				if kind == "Merkez":
					target = candidate
					break

				var distance := Vector2(
					candidate.position.x - x,
					candidate.position.z - z
				).length()

				if distance < 0.1:
					target = candidate
					break

		if target == null:
			continue

		used[target.get_instance_id()] = true

		if not saved_id.is_empty():
			if not _id_in_use(saved_id, target):
				target.set_meta(
					"building_id", saved_id
				)

		# The main save restores other buildings.
		# The city hall position is stored here.
		if kind == "Merkez":
			var previous := target.position
			var restored := Vector3(
				x, previous.y, z
			)

			target.position = restored

			var preview := game.get_node_or_null(
				"OttomanCityHallPreview"
			) as Node3D

			if preview != null:
				preview.position += (
					restored - previous
				)

	sync_occupied()
