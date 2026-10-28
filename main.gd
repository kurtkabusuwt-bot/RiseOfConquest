extends Node3D

# Rise of Conquest: asset-free mobile 3D city prototype.
# Controls: drag = orbit, pinch = zoom, tap terrain = place selected building.

const WORLD_SIZE := 38.0
const WORLD_OFFSET := 250.0
var world_mode := false
var world_root: Node3D
var world_army: Node3D
var world_army_target := Vector3.ZERO
var world_army_marching := false
var world_resources: Array[Dictionary] = []
var world_army_count := 0
var world_status := "Haritadan bir kaynak noktasi sec."
var camera: Camera3D
var camera_pivot: Node3D
var camera_distance := 31.0
var camera_yaw := 0.0
var camera_pitch := -0.85
var drag_origin := Vector2.ZERO
var previous_touch := Vector2.ZERO
var dragging := false
var touch_positions: Dictionary = {}
var pinch_last_distance := 0.0
var selected_building := "Ev"
var placing := false
var occupied: Array[Vector2i] = []
var info_label: Label
var mode_label: Label
var coins := 500
var woods := 500
var stones := 250
var foods := 350
var resource_tick := 0.0
var save_tick := 0.0
var buildings_saved: Array[Dictionary] = []
var farm_count := 0
var lumber_count := 0
var mine_count := 0
var last_save_message := ""
var house_count := 0
var tower_count := 0
var ruler: Node3D
var ruler_angle := 0.0
var ruler_mode := false
var ruler_target := Vector3(3, 0, 4)
var ruler_walking := false
var ruler_walk_phase := 0.0
var ruler_left_arm: Node3D
var ruler_right_arm: Node3D
var ruler_left_leg: Node3D
var ruler_right_leg: Node3D
var sun_light: DirectionalLight3D
var world_env: WorldEnvironment
var night_mode := false
var lamps: Array[OmniLight3D] = []
var banners: Array[Node3D] = []
var animation_time := 0.0
var soldiers: Array[Node3D] = []
var soldier_time := 0.0
var unit_animation_time := 0.0
var barracks_count := 0
var status := "Bir bina seç, ardından zemine dokun."
# v0.3 training battle: local demo, no network, no persistent casualties.
var battle_active := false
var battle_units: Array[Dictionary] = []
var battle_timer := 0.0
var battle_round := 0
var selected_unit := 0
var battle_banner: Label
var battle_effects: Array[Dictionary] = []
var battle_hold := false
var battle_retreat := false
var battle_projectiles: Array[Dictionary] = []
var selected_target := -1
const ARENA_CENTER := Vector3(-8.0, 0.0, 8.0)


func _ready() -> void:
	create_environment()
	create_camera()
	create_city()
	create_world_map()
	load_game()
	create_ui()
	update_ui()

var surface_textures: Dictionary = {}

func make_surface_texture(base: Color, kind: String) -> Texture2D:
	var key := kind + "_" + base.to_html()
	if surface_textures.has(key):
		return surface_textures[key]
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var grain := sin(float(x * 17 + y * 37)) * 0.045 + sin(float(x * 7 - y * 11)) * 0.025
			var mortar := false
			if kind == "stone":
				var row := int(y / 16)
				var shifted_x := (x + (row % 2) * 16) % 32
				mortar = y % 16 == 0 or shifted_x == 0
			elif kind == "wood":
				grain += sin(float(x) * 0.6) * 0.065
				mortar = x % 16 == 0
			elif kind == "roof":
				mortar = y % 12 == 0 or (x + (int(y / 12) % 2) * 8) % 16 == 0
			var tint := -0.18 if mortar else grain
			image.set_pixel(x, y, Color(clampf(base.r + tint, 0.0, 1.0), clampf(base.g + tint, 0.0, 1.0), clampf(base.b + tint, 0.0, 1.0)))
	var texture := ImageTexture.create_from_image(image)
	surface_textures[key] = texture
	return texture

func apply_surface(mesh: MeshInstance3D, base: Color, kind: String) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_texture = make_surface_texture(base, kind)
	material.roughness = 0.92
	mesh.material_override = material

func make_material(color: Color, roughness := 0.85) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func add_box(parent: Node3D, name: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.material_override = make_material(color)
	parent.add_child(mesh_instance)
	if name in ["StoneBase", "Tower", "Barracks", "House", "GateLintel", "GatePillar", "Workshop"]:
		apply_surface(mesh_instance, color, "stone" if name != "Workshop" else "wood")
	elif name in ["Roof", "Eaves"]:
		apply_surface(mesh_instance, color, "roof")
	elif name in ["Door", "Gate", "TimberFrame"]:
		apply_surface(mesh_instance, color, "wood")
	return mesh_instance

func add_cylinder(parent: Node3D, name: String, top_radius: float, bottom_radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	node.mesh = mesh
	node.position = pos
	node.material_override = make_material(color)
	parent.add_child(node)
	if name in ["Tower"]:
		apply_surface(node, color, "stone")
	elif name == "Roof":
		apply_surface(node, color, "roof")
	return node

func create_environment() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("a8c8d7")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e2d7c1")
	env.ambient_light_energy = 0.48
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	world_env = environment
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	add_child(sun)
	sun_light = sun
	add_box(self, "Terrain", Vector3(WORLD_SIZE, 0.35, WORLD_SIZE), Vector3(0, -0.2, 0), Color("778f62"))
	for x in range(-18, 19, 6):
		add_box(self, "PathEast", Vector3(5.8, 0.02, 1.3), Vector3(float(x), 0.01, 6), Color("cdbb94"))
	for z in range(-18, 19, 6):
		add_box(self, "PathNorth", Vector3(1.3, 0.02, 5.8), Vector3(6, 0.012, float(z)), Color("cdbb94"))
	for i in range(24):
		var angle := float(i) * TAU / 24.0
		var r := 16.0 + float(i % 3) * 0.65
		var p := Vector3(cos(angle) * r, 0, sin(angle) * r)
		add_cylinder(self, "TreeTrunk", 0.13, 0.19, 1.2, p + Vector3(0, 0.6, 0), Color("6a4932"))
		add_cylinder(self, "TreeCrown", 0.05, 0.95, 2.3, p + Vector3(0, 2.1, 0), Color("3c6442"))

func create_camera() -> void:
	camera_pivot = Node3D.new()
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 55
	camera_pivot.add_child(camera)
	update_camera()

func update_camera() -> void:
	camera_pivot.rotation = Vector3(0, camera_yaw, 0)
	camera.position = Vector3(0, sin(-camera_pitch) * camera_distance, cos(-camera_pitch) * camera_distance)
	camera.look_at(camera_pivot.global_position + Vector3(0, 0.5, 0), Vector3.UP)

func create_city() -> void:
	create_building("Merkez", Vector3(0, 0, 0))
	create_building("Ev", Vector3(-6, 0, -5))
	create_building("Ev", Vector3(-10, 0, 1))
	create_building("Kule", Vector3(10, 0, -8))
	for i in range(-2, 3):
		add_box(self, "WallNorth", Vector3(3.1, 2.6, 0.8), Vector3(float(i) * 3.2, 1.3, -12), Color("99948a"))
		add_box(self, "WallSouth", Vector3(3.1, 2.6, 0.8), Vector3(float(i) * 3.2, 1.3, 12), Color("99948a"))
		for j in range(3):
			var bx := float(i) * 3.2 - 1.0 + float(j)
			add_box(self, "NorthBattlement", Vector3(0.65, 0.65, 0.85), Vector3(bx, 2.85, -12), Color("bcb6a7"))
			add_box(self, "SouthBattlement", Vector3(0.65, 0.65, 0.85), Vector3(bx, 2.85, 12), Color("bcb6a7"))
	create_ruler()
	create_patrols()
	create_training_arena()
	decorate_city()
	create_lanterns()
	decorate_environment_v11()
	apply_lighting()

func create_world_map() -> void:
	# Separate 3D landscape around an offset origin. City systems remain unchanged.
	world_root = Node3D.new()
	world_root.name = "WorldMap"
	world_root.position = Vector3(WORLD_OFFSET, 0, 0)
	add_child(world_root)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12026
	add_box(world_root, "WorldGround", Vector3(190, 0.28, 190), Vector3(0, -0.17, 0), Color("738f5b"))
	# Distinct land patches and a winding river. Simple meshes for Android compatibility.
	for i in range(75):
		var px := rng.randf_range(-87, 87)
		var pz := rng.randf_range(-87, 87)
		var patch := add_box(world_root, "GrassPatch", Vector3(rng.randf_range(5, 15), 0.025, rng.randf_range(5, 15)), Vector3(px, 0.005, pz), Color("688755") if i % 2 == 0 else Color("7e9964"))
		patch.rotation.y = rng.randf_range(-0.8, 0.8)
	for i in range(16):
		var rz := -85.0 + float(i) * 11.2
		var rx := -28.0 + sin(float(i) * 0.43) * 13.0
		var river := add_box(world_root, "River", Vector3(10.5, 0.045, 12.2), Vector3(rx, 0.037, rz), Color("468aa0"))
		river.rotation.y = -cos(float(i) * 0.43) * 0.4
	# Roads and two bridges, placed above water for clear visibility.
	for i in range(-8, 9):
		add_box(world_root, "TradeRoad", Vector3(10.8, 0.05, 10.8), Vector3(float(i) * 10.6, 0.085, 9), Color("b7a078"))
	for z in [-48.0, 46.0]:
		add_box(world_root, "StoneBridge", Vector3(18, 0.22, 6), Vector3(-29, 0.21, z), Color("a9a398"))
	for i in range(95):
		var px := rng.randf_range(-88, 88)
		var pz := rng.randf_range(-88, 88)
		if absf(pz - 9.0) < 9.0 or absf(px + 28.0 - sin((pz + 85.0) / 11.2 * 0.43) * 13.0) < 10.0:
			continue
		add_cylinder(world_root, "ForestTrunk", 0.22, 0.3, 2.2, Vector3(px, 1.1, pz), Color("60432d"))
		add_cylinder(world_root, "ForestCrown", 0.05, rng.randf_range(1.2, 2.0), rng.randf_range(3.2, 5.0), Vector3(px, 4.0, pz), Color("355f42") if i % 3 else Color("4b7145"))
	for i in range(18):
		var px := rng.randf_range(-82, 82)
		var pz := rng.randf_range(-82, 82)
		if absf(pz - 9) < 15:
			continue
		add_cylinder(world_root, "Mountain", 0.0, rng.randf_range(3.5, 7.5), rng.randf_range(5, 11), Vector3(px, 3.4, pz), Color("777e70"))
	# Main city, alliance fort and resource points are actual 3D map landmarks.
	add_cylinder(world_root, "PlayerCityBase", 6, 8, 2.0, Vector3(42, 1, 9), Color("b8ac8b"))
	add_box(world_root, "PlayerCityWalls", Vector3(9, 4, 9), Vector3(42, 3.5, 9), Color("c4bba7"))
	add_cylinder(world_root, "CityBlueDome", 0.0, 3.6, 3.5, Vector3(42, 7.1, 9), Color("52839b"))
	add_box(world_root, "AllianceFort", Vector3(9, 5, 9), Vector3(-65, 2.6, -58), Color("9a9282"))
	for dx in [-4.0, 4.0]:
		for dz in [-4.0, 4.0]:
			add_cylinder(world_root, "FortTower", 1.5, 1.6, 8, Vector3(-65 + dx, 4, -58 + dz), Color("aea695"))
	var spots := [Vector3(63, 0, -43), Vector3(4, 0, -63), Vector3(-60, 0, 52), Vector3(64, 0, 65), Vector3(3, 0, 58)]
	var kinds := ["Odun", "Tas", "Yiyecek", "Altin", "Odun"]
	for i in range(spots.size()):
		var point: Vector3 = spots[i]
		var node := Node3D.new()
		node.position = point
		node.name = "Resource_%d" % i
		world_root.add_child(node)
		add_cylinder(node, "ResourceMarker", 0.3, 2.0, 3.0, Vector3(0, 1.5, 0), Color("d2ad4f") if i == 3 else Color("698ba0") if i == 1 else Color("5c965b"))
		var sign := Label3D.new()
		sign.text = kinds[i]
		sign.font_size = 38
		sign.pixel_size = 0.008
		sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sign.position = Vector3(0, 4.3, 0)
		node.add_child(sign)
		world_resources.append({"position": point, "kind": kinds[i], "node": node})
	world_army = Node3D.new()
	world_army.name = "PlayerMarch"
	world_army.position = Vector3(42, 0, 16)
	world_root.add_child(world_army)
	add_cylinder(world_army, "ArmyBase", 1.1, 1.2, 0.5, Vector3(0, 0.25, 0), Color("376caa"))
	add_cylinder(world_army, "ArmyFlagPole", 0.09, 0.1, 3.5, Vector3(0, 2, 0), Color("e1d7c3"))
	add_box(world_army, "ArmyFlag", Vector3(1.5, 0.9, 0.1), Vector3(0.8, 3.2, 0), Color("376caa"))
	world_root.visible = false

func toggle_world_map() -> void:
	world_mode = not world_mode
	world_root.visible = world_mode
	placing = false
	ruler_mode = false
	if world_mode:
		camera_pivot.position = Vector3(WORLD_OFFSET, 0, 0)
		camera_distance = 115.0
		camera_pitch = -1.0
		status = "DUNYA HARITASI | Kaynak isaretine dokun, ORDU GONDER'e bas."
	else:
		camera_pivot.position = Vector3.ZERO
		camera_distance = 31.0
		camera_pitch = -0.85
		status = "SEHIR | Bina insa edebilir veya savas baslatabilirsin."
	update_camera()
	update_ui()

func send_world_army() -> void:
	if not world_mode:
		status = "Once DUNYA HARITASI'na gec."
	elif world_army_target == Vector3.ZERO:
		status = "Once haritada kaynak noktasi sec."
	else:
		world_army_marching = true
		status = "Ordu hedefe yuruyor..."
	update_ui()

func world_tap(hit: Vector3) -> void:
	var local_hit := Vector3(hit.x - WORLD_OFFSET, 0, hit.z)
	var nearest := -1
	var distance := 13.0
	for i in range(world_resources.size()):
		var point: Vector3 = world_resources[i]["position"]
		var d := point.distance_to(local_hit)
		if d < distance:
			nearest = i
			distance = d
	if nearest < 0:
		status = "Kaynak isaretlerinden birine dokun."
	else:
		var chosen: Dictionary = world_resources[nearest]
		world_army_target = chosen["position"]
		world_status = str(chosen["kind"])
		status = "%s secildi. ORDU GONDER'e bas." % world_status
	update_ui()

func update_world_army(delta: float) -> void:
	if not world_army_marching:
		return
	var direction := world_army_target - world_army.position
	if direction.length() < 0.8:
		world_army.position = world_army_target
		world_army_marching = false
		world_army_count += 1
		match world_status:
			"Odun": woods += 75
			"Tas": stones += 75
			"Yiyecek": foods += 75
			"Altin": coins += 75
		status = "Ordu hedefe ulasti: +75 %s (demo)." % world_status
		world_army_target = Vector3.ZERO
		update_ui()
	else:
		world_army.position += direction.normalized() * minf(15.0 * delta, direction.length())
		world_army.rotation.y = atan2(direction.x, direction.z)

func create_building(kind: String, pos: Vector3) -> void:
	var building := Node3D.new()
	building.name = kind
	building.position = pos
	add_child(building)
	if kind == "Merkez":
		add_box(building, "StoneBase", Vector3(5.5, 3.0, 5.5), Vector3(0, 1.5, 0), Color("d5c9a9"))
		add_cylinder(building, "Dome", 0.4, 2.3, 2.1, Vector3(0, 4.05, 0), Color("718e9b"))
		for x in [-2.0, 2.0]:
			add_cylinder(building, "Minaret", 0.2, 0.35, 5.0, Vector3(x, 2.5, -2.8), Color("e0d7bf"))
		add_box(building, "Door", Vector3(1.2, 2, 0.12), Vector3(0, 1, 2.81), Color("5a3b2b"))
		decorate_palace(building)
	elif kind == "Kışla":
		add_box(building, "Barracks", Vector3(4.2, 2.4, 3.5), Vector3(0, 1.2, 0), Color("bca58a"))
		add_box(building, "Roof", Vector3(4.7, 0.55, 4), Vector3(0, 2.65, 0), Color("895b4c"))
		add_box(building, "Gate", Vector3(1.2, 1.8, 0.15), Vector3(0, 0.9, 1.82), Color("584336"))
		for side in [-1.0, 1.0]:
			add_cylinder(building, "BannerPole", 0.07, 0.07, 3.5, Vector3(side * 1.7, 3.7, 1.5), Color("65523d"))
			add_box(building, "Banner", Vector3(0.8, 0.8, 0.06), Vector3(side * 1.7 + 0.4, 4.4, 1.5), Color("ad4940"))
		decorate_barracks(building)
		barracks_count += 1
	elif kind == "Çiftlik":
		add_box(building, "Field", Vector3(3.3, 0.12, 3.3), Vector3(0, 0.1, 0), Color("997648"))
		for i in range(4):
			add_box(building, "Crop", Vector3(0.32, 0.55, 2.7), Vector3(-1.1 + i * 0.7, 0.36, 0), Color("b9ad4d"))
		add_box(building, "Shed", Vector3(1.3, 1.5, 1.1), Vector3(0, 0.75, -1), Color("d0b58c"))
		farm_count += 1
	elif kind == "Kereste":
		add_box(building, "Workshop", Vector3(3, 1.7, 2.5), Vector3(0, 0.85, 0), Color("9c7251"))
		add_box(building, "Roof", Vector3(3.3, 0.3, 2.9), Vector3(0, 1.9, 0), Color("725443"))
		for i in range(3):
			add_cylinder(building, "Logs", 0.27, 0.27, 2.2, Vector3(-0.8 + i * 0.7, 0.34, 1.5), Color("67462d"))
		lumber_count += 1
	elif kind == "Taşocağı":
		add_box(building, "StoneBase", Vector3(3.2, 0.35, 3.2), Vector3(0, 0.18, 0), Color("777773"))
		for i in range(5):
			add_box(building, "Stone", Vector3(0.9, 0.55 + i * 0.15, 0.8), Vector3(-1.0 + float(i % 3), 0.45, -0.8 + float(i / 3)), Color("aaa69b"))
		mine_count += 1
	elif kind == "Ev":
		add_box(building, "House", Vector3(2.6, 2.2, 2.6), Vector3(0, 1.1, 0), Color("d8c5a4"))
		add_cylinder(building, "Roof", 0.3, 2.0, 1.5, Vector3(0, 2.95, 0), Color("a46b50"))
		add_box(building, "Door", Vector3(0.65, 1.3, 0.12), Vector3(0, 0.65, 1.36), Color("6b4632"))
		decorate_house(building)
		house_count += 1
	elif kind == "Kule":
		add_cylinder(building, "Tower", 1.15, 1.35, 4.8, Vector3(0, 2.4, 0), Color("b5ac97"))
		add_cylinder(building, "Roof", 0.0, 1.55, 1.8, Vector3(0, 5.65, 0), Color("845747"))
		decorate_tower(building)
		tower_count += 1
	occupied.append(Vector2i(roundi(pos.x), roundi(pos.z)))


# v0.7 procedural Ottoman-inspired details: no external 3D assets required.
func decorate_palace(building: Node3D) -> void:
	for x in [-2.0, 0.0, 2.0]:
		add_box(building, "FacadeWindow", Vector3(0.58, 0.85, 0.09), Vector3(x, 2.05, 2.81), Color("456e78"))
		add_box(building, "WindowLintel", Vector3(0.82, 0.16, 0.2), Vector3(x, 2.57, 2.85), Color("f0dfbd"))
	for x in [-2.0, 2.0]:
		add_cylinder(building, "MinaretBalcony", 0.54, 0.54, 0.22, Vector3(x, 4.1, -2.8), Color("e7d8b9"))
		add_cylinder(building, "MinaretSpire", 0.0, 0.33, 0.85, Vector3(x, 5.43, -2.8), Color("8b7152"))
	add_cylinder(building, "DomeFinial", 0.0, 0.17, 0.72, Vector3(0, 5.43, 0), Color("d3b45b"))
	add_box(building, "EntranceStep", Vector3(2.0, 0.18, 0.95), Vector3(0, 0.09, 3.2), Color("e0d1b5"))

func decorate_house(building: Node3D) -> void:
	for x in [-0.85, 0.85]:
		add_box(building, "TimberFrame", Vector3(0.12, 2.1, 0.16), Vector3(x, 1.1, 1.38), Color("73533c"))
		add_box(building, "Window", Vector3(0.48, 0.55, 0.13), Vector3(x, 1.4, 1.41), Color("497a82"))
		add_box(building, "WindowFrame", Vector3(0.68, 0.12, 0.19), Vector3(x, 1.74, 1.42), Color("6e4b35"))
	add_box(building, "Eaves", Vector3(3.15, 0.16, 3.15), Vector3(0, 2.3, 0), Color("785342"))
	add_cylinder(building, "Chimney", 0.16, 0.18, 0.9, Vector3(0.92, 3.2, -0.7), Color("a78e78"))

func decorate_barracks(building: Node3D) -> void:
	for x in [-1.45, 1.45]:
		add_box(building, "BarracksWindow", Vector3(0.6, 0.65, 0.12), Vector3(x, 1.35, 1.8), Color("4d727b"))
		add_box(building, "WindowStone", Vector3(0.8, 0.15, 0.18), Vector3(x, 1.75, 1.83), Color("e3d4b9"))
	add_box(building, "BarracksThreshold", Vector3(1.65, 0.17, 0.8), Vector3(0, 0.08, 2.12), Color("c9b99e"))

func decorate_tower(building: Node3D) -> void:
	for i in range(8):
		var a := TAU * float(i) / 8.0
		add_box(building, "TowerCrenellation", Vector3(0.55, 0.55, 0.55), Vector3(cos(a) * 1.12, 4.95, sin(a) * 1.12), Color("d1c7b0"))
	add_box(building, "ArrowSlit", Vector3(0.18, 0.9, 0.09), Vector3(0, 3.0, 1.32), Color("383b3a"))

func decorate_city() -> void:
	# Small paving slabs around the palace, kept away from the combat arena.
	for x in range(-2, 3):
		for z in range(3, 6):
			if (x + z) % 3 == 0:
				add_box(self, "CourtyardTile", Vector3(0.88, 0.035, 0.88), Vector3(float(x), 0.035, float(z)), Color("d9c8a5"))
	# Simple entrance gate and banners on the southern defensive line.
	for x in [-2.0, 2.0]:
		add_cylinder(self, "GatePillar", 0.5, 0.62, 3.7, Vector3(x, 1.85, 12), Color("bdb4a4"))
		add_cylinder(self, "GateCap", 0.0, 0.67, 0.8, Vector3(x, 4.1, 12), Color("77594b"))
	add_box(self, "GateLintel", Vector3(4.4, 0.55, 1.0), Vector3(0, 3.55, 12), Color("b7ad9d"))
	for x in [-1.6, 1.6]:
		var flag := Node3D.new()
		flag.position = Vector3(x, 2.55, 12.55)
		add_child(flag)
		add_box(flag, "AnimatedBanner", Vector3(0.7, 1.15, 0.08), Vector3.ZERO, Color("a13f38"))
		banners.append(flag)
	# Decorative market stalls at the far edge of the city.
	for x in [-9.0, -5.0]:
		add_box(self, "MarketStand", Vector3(2.1, 0.18, 1.4), Vector3(x, 0.95, 10), Color("835b3e"))
		for side in [-0.85, 0.85]:
			add_box(self, "MarketPost", Vector3(0.12, 2.0, 0.12), Vector3(x + side, 1.1, 10), Color("71513b"))
		add_box(self, "MarketAwning", Vector3(2.5, 0.14, 1.8), Vector3(x, 2.18, 10), Color("a95547"))


# v0.8: lightweight lighting presets and warm lanterns for mobile GL Compatibility.
func decorate_environment_v11() -> void:
	# Mobile-friendly props: geometry and procedural textures, no external downloads.
	for i in range(24):
		var x := -15.0 + float((i * 11) % 30)
		var z := -15.0 + float((i * 17) % 30)
		if absf(x) < 7.0 or absf(z) < 7.0:
			continue
		add_box(self, "GrassPatch", Vector3(0.45, 0.08, 0.38), Vector3(x, 0.04, z), Color("607c4d"))
	for i in range(10):
		var x := -11.0 + float(i % 5) * 1.1
		var z := 8.5 + float(i / 5) * 0.7
		add_box(self, "MarketCrate", Vector3(0.55, 0.45, 0.55), Vector3(x, 0.25, z), Color("886244"))
	for x in [-3.0, 3.0]:
		for z in [-3.0, 3.0]:
			add_box(self, "PalacePlanter", Vector3(0.8, 0.38, 0.8), Vector3(x, 0.2, z), Color("8a7058"))
			add_cylinder(self, "Shrub", 0.3, 0.43, 0.7, Vector3(x, 0.7, z), Color("416b43"))

func create_lanterns() -> void:
	for p in [Vector3(-3.5, 2.5, 3.5), Vector3(3.5, 2.5, 3.5), Vector3(-6.0, 2.5, 9.0), Vector3(6.0, 2.5, 9.0)]:
		add_cylinder(self, "LanternPost", 0.06, 0.09, 2.4, Vector3(p.x, 1.2, p.z), Color("584531"))
		add_box(self, "LanternGlass", Vector3(0.33, 0.42, 0.33), p, Color("efc27d"))
		var light := OmniLight3D.new()
		light.position = p
		light.light_color = Color("ffd39a")
		light.light_energy = 0.8
		light.omni_range = 5.0
		light.shadow_enabled = false
		add_child(light)
		lamps.append(light)

func apply_lighting() -> void:
	if world_env == null or sun_light == null:
		return
	var env := world_env.environment
	if night_mode:
		env.background_color = Color("17283e")
		env.ambient_light_color = Color("8298b7")
		env.ambient_light_energy = 0.25
		sun_light.light_energy = 0.11
	else:
		env.background_color = Color("a8c8d7")
		env.ambient_light_color = Color("e2d7c1")
		env.ambient_light_energy = 0.48
		sun_light.light_energy = 0.75
	for lamp in lamps:
		lamp.visible = night_mode

func toggle_day_night() -> void:
	night_mode = not night_mode
	apply_lighting()
	status = "Gece aydınlatması açıldı." if night_mode else "Gündüz aydınlatması açıldı."
	update_ui()

func create_ruler() -> void:
	ruler = Node3D.new()
	ruler.position = Vector3(3, 0, 4)
	add_child(ruler)
	add_cylinder(ruler, "Body", 0.35, 0.42, 1.35, Vector3(0, 1.0, 0), Color("36567a"))
	add_cylinder(ruler, "Head", 0.3, 0.3, 0.55, Vector3(0, 1.95, 0), Color("d7ac80"))
	add_cylinder(ruler, "Hat", 0.2, 0.35, 0.45, Vector3(0, 2.42, 0), Color("a24e43"))
	add_box(ruler, "Cloak", Vector3(0.74, 1.10, 0.13), Vector3(0, 1.08, -0.33), Color("702f3c"))
	add_box(ruler, "GoldSash", Vector3(0.76, 0.10, 0.45), Vector3(0, 0.88, 0), Color("c5a45d"))
	ruler_left_arm = Node3D.new()
	ruler_left_arm.position = Vector3(-0.49, 1.55, 0)
	ruler.add_child(ruler_left_arm)
	add_cylinder(ruler_left_arm, "LeftArm", 0.14, 0.16, 0.85, Vector3(0, -0.37, 0), Color("36567a"))
	ruler_right_arm = Node3D.new()
	ruler_right_arm.position = Vector3(0.49, 1.55, 0)
	ruler.add_child(ruler_right_arm)
	add_cylinder(ruler_right_arm, "RightArm", 0.14, 0.16, 0.85, Vector3(0, -0.37, 0), Color("36567a"))
	ruler_left_leg = Node3D.new()
	ruler_left_leg.position = Vector3(-0.20, 0.45, 0)
	ruler.add_child(ruler_left_leg)
	add_cylinder(ruler_left_leg, "LeftLeg", 0.13, 0.16, 0.85, Vector3(0, -0.15, 0), Color("263c50"))
	ruler_right_leg = Node3D.new()
	ruler_right_leg.position = Vector3(0.20, 0.45, 0)
	ruler.add_child(ruler_right_leg)
	add_cylinder(ruler_right_leg, "RightLeg", 0.13, 0.16, 0.85, Vector3(0, -0.15, 0), Color("263c50"))
	add_unit_gear_v11(ruler, 2)
	attach_ottoman_assets(ruler)

# v0.9: Lightweight procedural Ottoman-inspired character detailing.
# Mesh-based rigging is deliberately used until licensed GLB assets are available.
func add_character_details(body: Node3D, faction_color: Color, archer: bool = false, cavalry: bool = false) -> void:
	add_box(body, "LeatherBelt", Vector3(0.64, 0.12, 0.42), Vector3(0, 0.82, 0), Color("513d2e"))
	add_box(body, "BeltBuckle", Vector3(0.13, 0.12, 0.05), Vector3(0, 0.82, 0.24), Color("d2b879"))
	add_box(body, "ChestArmor", Vector3(0.48, 0.52, 0.15), Vector3(0, 1.20, 0.30), Color("8a887a"))
	add_box(body, "ChestTrim", Vector3(0.53, 0.07, 0.17), Vector3(0, 1.38, 0.32), faction_color.lightened(0.2))
	add_box(body, "BootLeft", Vector3(0.22, 0.28, 0.38), Vector3(-0.18, 0.16, 0.10), Color("342b26"))
	add_box(body, "BootRight", Vector3(0.22, 0.28, 0.38), Vector3(0.18, 0.16, 0.10), Color("342b26"))
	add_box(body, "ShoulderLeft", Vector3(0.27, 0.16, 0.34), Vector3(-0.39, 1.39, 0), Color("6b6b68"))
	add_box(body, "ShoulderRight", Vector3(0.27, 0.16, 0.34), Vector3(0.39, 1.39, 0), Color("6b6b68"))
	add_box(body, "HelmetBand", Vector3(0.56, 0.09, 0.45), Vector3(0, 1.83, 0), Color("b59c68"))
	if archer:
		add_box(body, "Quiver", Vector3(0.22, 0.58, 0.22), Vector3(0.33, 1.15, -0.33), Color("5e412b"))
		for n in range(3):
			add_box(body, "QuiverArrow", Vector3(0.035, 0.55, 0.035), Vector3(0.25 + n * 0.08, 1.56, -0.33), Color("c9b994"))
	if cavalry:
		add_box(body, "HorseMane", Vector3(0.22, 0.40, 0.18), Vector3(0, 0.83, -0.65), Color("322a25"))
		add_box(body, "HorseSaddle", Vector3(0.65, 0.13, 0.65), Vector3(0, 0.85, -0.10), Color("6c3130"))

# v1.0: Real binary glTF (GLB) accessory meshes, imported by Godot.
# Existing lightweight character rigs still animate procedurally.
func add_unit_gear_v11(character: Node3D, kind: int) -> void:
	# Three visibly distinct roles; lightweight accessories compatible with GL mobile.
	if kind == 0:
		add_box(character, "InfantryChestPlate", Vector3(0.54, 0.62, 0.12), Vector3(0, 1.17, 0.28), Color("7b8584"))
		add_box(character, "InfantryBelt", Vector3(0.66, 0.12, 0.43), Vector3(0, 0.77, 0), Color("654c35"))
		add_box(character, "InfantryBuckle", Vector3(0.13, 0.12, 0.07), Vector3(0, 0.77, 0.26), Color("c6a96b"))
	elif kind == 1:
		add_box(character, "ArcherTunic", Vector3(0.55, 0.70, 0.11), Vector3(0, 1.10, 0.26), Color("58745d"))
		add_box(character, "ArcherStrap", Vector3(0.10, 0.82, 0.12), Vector3(-0.08, 1.18, 0.34), Color("68462d"))
		add_box(character, "ArcherArmGuard", Vector3(0.18, 0.4, 0.16), Vector3(-0.38, 1.0, 0.15), Color("69462d"))
	else:
		add_box(character, "CavalryChestArmor", Vector3(0.62, 0.72, 0.13), Vector3(0, 1.15, 0.3), Color("7e6c5a"))
		add_box(character, "CavalryGoldTrim", Vector3(0.63, 0.10, 0.15), Vector3(0, 1.44, 0.32), Color("d1ad65"))

func attach_ottoman_assets(character: Node3D, shield: bool = false) -> void:
	var helmet_scene: PackedScene = load("res://assets/ottoman_helmet.glb")
	if helmet_scene != null:
		var helmet_model := helmet_scene.instantiate() as Node3D
		helmet_model.name = "ImportedGLBHelmet"
		helmet_model.position = Vector3(0, 1.95, 0)
		character.add_child(helmet_model)
	if shield:
		var shield_scene: PackedScene = load("res://assets/ottoman_shield.glb")
		if shield_scene != null:
			var shield_model := shield_scene.instantiate() as Node3D
			shield_model.name = "ImportedGLBShield"
			shield_model.position = Vector3(-0.38, 1.03, 0.20)
			character.add_child(shield_model)

func create_patrols() -> void:
	for i in range(4):
		var soldier := Node3D.new()
		soldier.name = "Patrol_%d" % i
		add_child(soldier)
		add_cylinder(soldier, "Uniform", 0.27, 0.32, 1.1, Vector3(0, 0.83, 0), Color("824a3d"))
		add_cylinder(soldier, "Head", 0.22, 0.22, 0.4, Vector3(0, 1.6, 0), Color("d5ae83"))
		add_character_details(soldier, Color("824a3d"))
		add_unit_gear_v11(soldier, i % 3)
		attach_ottoman_assets(soldier, true)
		soldiers.append(soldier)

func _process(delta: float) -> void:
	update_world_army(delta)
	if ruler_walking:
		var direction := ruler_target - ruler.position
		if direction.length() <= 0.08:
			ruler.position = ruler_target
			ruler_walking = false
			ruler_left_arm.rotation.x = 0.0
			ruler_right_arm.rotation.x = 0.0
			ruler_left_leg.rotation.x = 0.0
			ruler_right_leg.rotation.x = 0.0
		else:
			ruler.position += direction.normalized() * minf(3.5 * delta, direction.length())
			ruler.rotation.y = atan2(direction.x, direction.z)
			ruler_walk_phase += delta * 9.0
			ruler_left_arm.rotation.x = sin(ruler_walk_phase) * 0.4
			ruler_right_arm.rotation.x = -sin(ruler_walk_phase) * 0.4
			ruler_left_leg.rotation.x = -sin(ruler_walk_phase) * 0.35
			ruler_right_leg.rotation.x = sin(ruler_walk_phase) * 0.35
	resource_tick += delta
	save_tick += delta
	if resource_tick >= 5.0:
		resource_tick -= 5.0
		woods += lumber_count * 8 + 2
		foods += farm_count * 10 + 2
		stones += mine_count * 6
		coins += house_count * 3 + 1
		update_ui()
	if save_tick >= 30.0:
		save_tick = 0.0
		save_game(false)
	soldier_time += delta
	for i in range(soldiers.size()):
		var angle := soldier_time * (0.35 + i * 0.06) + float(i) * TAU / 4.0
		var soldier := soldiers[i]
		soldier.position = Vector3(9.0 + cos(angle) * 3.0, 0, 6.0 + sin(angle) * 3.0)
		soldier.rotation.y = -angle
		soldier.position.y = absf(sin(soldier_time * 5.5 + float(i))) * 0.055
	unit_animation_time += delta
	animation_time += delta
	for i in range(banners.size()):
		banners[i].rotation.y = sin(animation_time * 2.0 + float(i)) * 0.12
	update_battle(delta)


func create_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	canvas.add_child(root)
	var top := PanelContainer.new()
	style_panel(top, Color("1c2928"))
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 55
	root.add_child(top)
	var top_row := HBoxContainer.new()
	top.add_child(top_row)
	var title := Label.new()
	title.text = "  RISE OF CONQUEST  |  PROTOTIP 1.2"
	title.add_theme_font_size_override("font_size", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title)
	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 18)
	top_row.add_child(info_label)
	var bottom := PanelContainer.new()
	style_panel(bottom, Color("1c2928"))
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -140
	root.add_child(bottom)
	var column := VBoxContainer.new()
	bottom.add_child(column)
	mode_label = Label.new()
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(mode_label)
	battle_banner = Label.new()
	battle_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle_banner.add_theme_font_size_override("font_size", 16)
	column.add_child(battle_banner)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 64)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_BEGIN
	scroll.add_child(buttons)
	add_ui_button(buttons, "DUNYA / SEHIR", toggle_world_map)
	add_ui_button(buttons, "ORDU GONDER", send_world_army)
	add_ui_button(buttons, "EV (100 odun)", func(): choose_building("Ev"))
	add_ui_button(buttons, "KULE (150 altin)", func(): choose_building("Kule"))
	add_ui_button(buttons, "KISLA (200 odun)", func(): choose_building("Kışla"))
	add_ui_button(buttons, "CIFTLIK (80 odun)", func(): choose_building("Çiftlik"))
	add_ui_button(buttons, "KERESTE (100 altin)", func(): choose_building("Kereste"))
	add_ui_button(buttons, "TASOCAGI (100 odun)", func(): choose_building("Taşocağı"))
	add_ui_button(buttons, "GUN / GECE", toggle_day_night)
	add_ui_button(buttons, "KAMERA +", func(): zoom_camera(-3))
	add_ui_button(buttons, "KAMERA -", func(): zoom_camera(3))
	add_ui_button(buttons, "HUKUMDAR", toggle_ruler)
	add_ui_button(buttons, "SAVAS BASLAT", start_battle)
	add_ui_button(buttons, "HEDEF DEGISTIR", select_next_unit)
	add_ui_button(buttons, "SALDIR", order_attack)
	add_ui_button(buttons, "SAVUN", toggle_hold)
	add_ui_button(buttons, "GERI CEKIL", retreat_battle)
	add_ui_button(buttons, "KAYDET", func(): save_game(true))
	add_ui_button(buttons, "IPTAL", cancel_placement)

func style_panel(panel: PanelContainer, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("a38a58")
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)

func add_ui_button(parent: HBoxContainer, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(135, 58)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("344a47")
	normal.border_color = Color("a38a58")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", normal)
	var pressed_style := normal.duplicate()
	pressed_style.bg_color = Color("597068")
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color", Color("f4e9cf"))
	button.pressed.connect(callback)
	parent.add_child(button)

func choose_building(kind: String) -> void:
	if world_mode:
		status = "Bina insasi icin sehre don."
		update_ui()
		return
	ruler_mode = false
	selected_building = kind
	placing = true
	status = "%s seçildi. Boş zemine dokun." % kind
	update_ui()

func cancel_placement() -> void:
	placing = false
	status = "Yerleştirme iptal edildi."
	update_ui()

func toggle_ruler() -> void:
	if world_mode:
		status = "Hukumdar modu icin sehre don."
		update_ui()
		return
	ruler_mode = not ruler_mode
	placing = false
	status = "Hükümdar modu: zemine dokunarak ilerle." if ruler_mode else "Şehir kamerası etkin."
	update_ui()

func zoom_camera(delta: float) -> void:
	camera_distance = clampf(camera_distance + delta, 35, 155) if world_mode else clampf(camera_distance + delta, 12, 52)
	update_camera()

func update_ui() -> void:
	if info_label != null:
		info_label.text = "Altin %d | Odun %d | Tas %d | Yiyecek %d  " % [coins, woods, stones, foods]
	if mode_label != null:
		mode_label.text = status
	if battle_banner != null:
		battle_banner.text = get_battle_status()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_positions[event.index] = event.position
			previous_touch = event.position
			drag_origin = event.position
			dragging = false
		else:
			touch_positions.erase(event.index)
			if not dragging and touch_positions.is_empty():
				handle_ground_tap(event.position)
			pinch_last_distance = 0.0
	elif event is InputEventScreenDrag:
		touch_positions[event.index] = event.position
		if touch_positions.size() >= 2:
			var pts := touch_positions.values()
			var distance: float = pts[0].distance_to(pts[1])
			if pinch_last_distance > 0:
				zoom_camera((pinch_last_distance - distance) * 0.04)
			pinch_last_distance = distance
			dragging = true
		else:
			if event.position.distance_to(drag_origin) > 12:
				dragging = true
			if dragging:
				camera_yaw -= event.relative.x * 0.006
				camera_pitch = clampf(camera_pitch - event.relative.y * 0.003, -1.25, -0.35)
				update_camera()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_camera(-2)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_camera(2)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_origin = event.position
				dragging = false
			else:
				if not dragging:
					handle_ground_tap(event.position)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if event.position.distance_to(drag_origin) > 12:
			dragging = true
		if dragging:
			camera_yaw -= event.relative.x * 0.006
			update_camera()

func handle_ground_tap(screen_pos: Vector2) -> void:
	if not world_mode and not placing and not ruler_mode and not battle_active:
		return
	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_direction := camera.project_ray_normal(screen_pos)
	if absf(ray_direction.y) < 0.0001:
		return
	var t := -ray_origin.y / ray_direction.y
	if t <= 0:
		return
	var hit := ray_origin + ray_direction * t
	if world_mode:
		world_tap(hit)
		return
	if battle_active and not placing and not ruler_mode:
		if hit.x > -13.0 and hit.x < -3.0 and hit.z > 3.5 and hit.z < 12.5:
			var best := -1
			var best_dist := 2.1
			for j in range(3, battle_units.size()):
				var enemy: Dictionary = battle_units[j]
				if enemy["hp"] <= 0.0: continue
				var enemy_node: Node3D = enemy["node"]
				var dist := enemy_node.position.distance_to(Vector3(hit.x, 0, hit.z))
				if dist < best_dist:
					best_dist = dist
					best = j
			if best >= 0:
				selected_target = best
				status = "Düşman hedefi seçildi: %d" % (best - 2)
			else:
				status = "Hedef için kırmızı askere dokun."
			update_ui()
		return
	if absf(hit.x) > 14 or absf(hit.z) > 14:
		status = "Şehir sınırlarının dışına yerleştiremezsin."
		update_ui()
		return
	if ruler_mode:
		ruler_target = Vector3(hit.x, 0, hit.z)
		ruler_walking = true
		status = "Hükümdar hedefe yürüyor."
		update_ui()
		return
	var grid_pos := Vector2i(roundi(hit.x), roundi(hit.z))
	var min_distance := 4.0 if selected_building == "Ev" else 4.5
	for cell in occupied:
		if Vector2(grid_pos).distance_to(Vector2(cell)) < min_distance:
			status = "Burası dolu. Daha uzak bir nokta seç."
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
	elif selected_building == "Çiftlik" or selected_building == "Taşocağı":
		var cost := 80 if selected_building == "Çiftlik" else 100
		if woods < cost:
			status = "Yeterli odun yok."
			update_ui()
			return
		woods -= cost
	elif selected_building == "Kereste":
		if coins < 100:
			status = "Yeterli altın yok."
			update_ui()
			return
		coins -= 100
	elif selected_building == "Kule":
		if coins < 150:
			status = "Yeterli altın yok."
			update_ui()
			return
		coins -= 150
	create_building(selected_building, Vector3(grid_pos.x, 0, grid_pos.y))
	buildings_saved.append({"kind": selected_building, "x": grid_pos.x, "z": grid_pos.y})
	save_game(false)
	status = "%s inşa edildi!" % selected_building
	update_ui()


# TRAINING ARENA: simplified 3D soldiers, hit flashes and HP indicators.
func create_training_arena() -> void:
	add_box(self, "ArenaFloor", Vector3(9.0, 0.05, 8.0), ARENA_CENTER + Vector3(0, 0.035, 0), Color("9b906d"))
	for i in range(4):
		var z := 4.8 + float(i) * 2.1
		add_cylinder(self, "ArenaPost", 0.12, 0.14, 1.8, Vector3(-12.6, 0.9, z), Color("685039"))
		add_cylinder(self, "ArenaPost", 0.12, 0.14, 1.8, Vector3(-3.4, 0.9, z), Color("685039"))
	for i in range(3):
		var ally := make_battle_soldier(true, i)
		ally.position = ARENA_CENTER + Vector3(-2.0, 0, float(i - 1) * 1.8)
		var enemy := make_battle_soldier(false, i)
		enemy.position = ARENA_CENTER + Vector3(2.0, 0, float(i - 1) * 1.8)

func make_battle_soldier(ally: bool, index: int) -> Node3D:
	var node := Node3D.new()
	node.name = ("Ally_" if ally else "Enemy_") + str(index)
	add_child(node)
	var color := Color("326d9d") if ally else Color("a4483e")
	var unit_kinds: Array[String] = ["Piyade", "Okçu", "Süvari"]
	var unit_kind: String = unit_kinds[index]
	add_cylinder(node, "Torso", 0.24, 0.30, 1.02, Vector3(0, 0.91, 0), color)
	add_cylinder(node, "Head", 0.22, 0.22, 0.38, Vector3(0, 1.62, 0), Color("d9ae84"))
	add_character_details(node, color, index == 1, index == 2)
	add_unit_gear_v11(node, index)
	attach_ottoman_assets(node, index == 0)
	if index == 0:
		pass # GLB shield attached above
	elif index == 1:
		add_box(node, "Bow", Vector3(0.08, 1.0, 0.12), Vector3(-0.36, 1.2, 0), Color("855c37"))
	else:
		add_box(node, "HorseBody", Vector3(0.85, 0.7, 1.4), Vector3(0, 0.48, -0.15), Color("77563f"))
		for x in [-0.28, 0.28]:
			for z in [-0.65, 0.35]:
				add_box(node, "HorseLeg", Vector3(0.17, 0.6, 0.17), Vector3(x, 0.2, z), Color("5d4533"))
	var weapon := Node3D.new()
	weapon.name = "WeaponPivot"
	weapon.position = Vector3(0.35, 1.35, 0)
	node.add_child(weapon)
	add_box(weapon, "Sword", Vector3(0.08, 0.88, 0.10), Vector3(0, 0.38, 0), Color("c4c9c6"))
	var hp_bg := add_box(node, "HPBackground", Vector3(0.9, 0.10, 0.08), Vector3(0, 2.45, 0), Color("382e2b"))
	hp_bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var hp_bar := add_box(node, "HPFill", Vector3(0.84, 0.075, 0.09), Vector3(0, 2.45, 0.055), Color("57c37d") if ally else Color("ed7762"))
	hp_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	battle_units.append({"node": node, "ally": ally, "hp": 100.0, "max_hp": 100.0, "index": index, "weapon": weapon, "hp_bar": hp_bar, "cooldown": 0.0, "swing": 0.0, "target": -1, "kind": unit_kind})
	return node

func start_battle() -> void:
	if world_mode:
		status = "Egitim savasi icin sehre don."
		update_ui()
		return
	battle_round += 1
	battle_active = true
	battle_timer = 0.0
	selected_unit = 0
	selected_target = -1
	battle_hold = false
	battle_retreat = false
	for u in battle_units:
		u["hp"] = 100.0
		u["cooldown"] = 0.5
		u["swing"] = 0.0
		u["target"] = -1
		var node: Node3D = u["node"]
		node.visible = true
		var side := -2.0 if u["ally"] else 2.0
		node.position = ARENA_CENTER + Vector3(side, 0, float(u["index"] - 1) * 1.8)
		update_hp_visual(u)
	status = "Eğitim savaşı başladı! SALDIR düğmesine dokun."
	update_ui()

func select_next_unit() -> void:
	selected_unit = (selected_unit + 1) % 3
	status = "Seçilen: %s" % str(battle_units[selected_unit]["kind"])
	update_ui()

func order_attack() -> void:
	if not battle_active:
		status = "Önce SAVAS BASLAT düğmesine dokun."
		update_ui()
		return
	var ally := battle_units[selected_unit]
	if ally["hp"] <= 0:
		status = "Bu asker yaralı. Başka bir asker seç."
		update_ui()
		return
	var best := -1
	var best_dist := INF
	if selected_target >= 3 and battle_units[selected_target]["hp"] > 0:
		best = selected_target
	for j in range(3, 6):
		var enemy := battle_units[j]
		if enemy["hp"] <= 0: continue
		var d: float = ally["node"].position.distance_to(enemy["node"].position)
		if best == -1 and d < best_dist:
			best_dist = d
			best = j
	if best >= 0:
		ally["target"] = best
		ally["cooldown"] = 0.0
		status = "Asker %d hedefe saldırıyor." % (selected_unit + 1)
	else:
		status = "Tüm düşmanlar yenildi!"
	update_ui()

func toggle_hold() -> void:
	battle_hold = not battle_hold
	status = "Mavi ordu savunma konumunda." if battle_hold else "Mavi ordu ilerleyebilir."
	update_ui()

func retreat_battle() -> void:
	if not battle_active:
		status = "Aktif savaş yok."
	else:
		battle_retreat = true
		status = "Geri çekilme başladı; askerler çıkışa yürüyor."
	update_ui()

func update_hp_visual(u: Dictionary) -> void:
	var bar: MeshInstance3D = u["hp_bar"]
	var fraction: float = clampf(float(u["hp"]) / 100.0, 0.0, 1.0)
	bar.scale.x = maxf(0.001, fraction)
	bar.position.x = -0.42 * (1.0 - fraction)
	if u["hp"] <= 0:
		var node: Node3D = u["node"]
		node.visible = false

func update_battle(delta: float) -> void:
	if not battle_active:
		return
	battle_timer += delta
	if battle_retreat:
		var remaining := 0
		for k in range(3):
			var escaping: Dictionary = battle_units[k]
			if escaping["hp"] <= 0: continue
			var runner: Node3D = escaping["node"]
			var exit_pos := ARENA_CENTER + Vector3(-5.2, 0, float(k - 1) * 1.8)
			runner.position = runner.position.move_toward(exit_pos, delta * 2.6)
			if runner.position.distance_to(exit_pos) > 0.1:
				remaining += 1
		if remaining == 0:
			battle_active = false
			status = "Geri çekilme tamamlandı."
			update_ui()
			return
	for i in range(battle_units.size()):
		var unit := battle_units[i]
		if unit["hp"] <= 0: continue
		var node: Node3D = unit["node"]
		unit["cooldown"] = maxf(0.0, float(unit["cooldown"]) - delta)
		unit["swing"] = maxf(0.0, float(unit["swing"]) - delta)
		var weapon: Node3D = unit["weapon"]
		weapon.rotation.z = -sin(float(unit["swing"]) * 16.0) * 0.9
		if unit["kind"] != "Süvari":
			node.position.y = absf(sin(battle_timer * 8.0 + float(i))) * 0.045 if unit["swing"] <= 0.0 else 0.0
		var target_index: int = int(unit["target"])
		if target_index < 0 or battle_units[target_index]["hp"] <= 0:
			target_index = find_nearest_opponent(i)
			unit["target"] = target_index
		if target_index < 0: continue
		var target := battle_units[target_index]
		var target_node: Node3D = target["node"]
		var direction: Vector3 = target_node.position - node.position
		var distance := direction.length()
		var range_limit := 4.2 if unit["kind"] == "Okçu" else 1.0
		if distance > range_limit:
			if not (unit["ally"] and (battle_hold or battle_retreat)):
				var speed := 2.0 if unit["kind"] == "Süvari" else 1.25
				node.position += direction.normalized() * minf(delta * speed, distance - range_limit + 0.05)
			node.rotation.y = atan2(direction.x, direction.z)
		elif unit["cooldown"] <= 0.0:
			unit["cooldown"] = 1.8 if unit["kind"] == "Okçu" else (1.35 if unit["kind"] == "Süvari" else 1.2)
			if not unit["ally"]:
				unit["cooldown"] += 0.35
			unit["swing"] = 0.5
			var damage := 17.0 if unit["kind"] == "Okçu" else (25.0 if unit["kind"] == "Süvari" else 21.0)
			if not unit["ally"]: damage *= 0.75
			if target["ally"] and battle_hold: damage *= 0.75
			if unit["kind"] == "Okçu":
				spawn_arrow(node.position + Vector3(0, 1.45, 0), target_node.position + Vector3(0, 1.1, 0))
			target["hp"] = maxf(0.0, float(target["hp"]) - damage)
			update_hp_visual(target)
			spawn_hit_flash(target_node.position)
	for j in range(battle_projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = battle_projectiles[j]
		projectile["time"] = float(projectile["time"]) + delta * 4.0
		var arrow: Node3D = projectile["node"]
		arrow.position = projectile["start"].lerp(projectile["end"], minf(1.0, float(projectile["time"])))
		if projectile["time"] >= 1.0:
			arrow.queue_free()
			battle_projectiles.remove_at(j)
	for i in range(battle_effects.size() - 1, -1, -1):
		var fx := battle_effects[i]
		fx["time"] = float(fx["time"]) - delta
		var mesh: MeshInstance3D = fx["node"]
		mesh.scale = Vector3.ONE * maxf(0.01, float(fx["time"]) * 2.5)
		if fx["time"] <= 0.0:
			mesh.queue_free()
			battle_effects.remove_at(i)
	var allies_alive := 0
	var enemies_alive := 0
	for u in battle_units:
		if u["hp"] > 0:
			if u["ally"]: allies_alive += 1
			else: enemies_alive += 1
	if allies_alive == 0 or enemies_alive == 0:
		battle_active = false
		status = "ZAFER!" if enemies_alive == 0 else "YENİLGİ!"
		status += " Tekrar oynamak için SAVAS BASLAT."
	update_ui()

func find_nearest_opponent(index: int) -> int:
	var unit := battle_units[index]
	var best := -1
	var distance := INF
	for j in range(battle_units.size()):
		var candidate := battle_units[j]
		if candidate["ally"] == unit["ally"] or candidate["hp"] <= 0: continue
		var d: float = unit["node"].position.distance_to(candidate["node"].position)
		if d < distance:
			distance = d
			best = j
	return best

func spawn_arrow(start: Vector3, finish: Vector3) -> void:
	var arrow := Node3D.new()
	add_child(arrow)
	add_box(arrow, "Arrow", Vector3(0.07, 0.07, 0.8), Vector3.ZERO, Color("e6c78c"))
	arrow.position = start
	arrow.look_at(finish, Vector3.UP)
	battle_projectiles.append({"node": arrow, "start": start, "end": finish, "time": 0.0})

func spawn_hit_flash(position: Vector3) -> void:
	var flash := add_box(self, "HitEffect", Vector3(0.4, 0.4, 0.4), position + Vector3(0, 1.3, 0), Color("f9c36a"))
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	battle_effects.append({"node": flash, "time": 0.24})

func get_battle_status() -> String:
	if not battle_active:
		return "EĞİTİM ALANI | Mavi: 3 asker | Kırmızı: 3 asker | SAVAŞ BAŞLAT"
	var blue := 0
	var red := 0
	for u in battle_units:
		if u["hp"] > 0:
			if u["ally"]: blue += 1
			else: red += 1
	return "SAVAŞ | Mavi: %d | Kırmızı: %d | %s | %s" % [blue, red, str(battle_units[selected_unit]["kind"]), "SAVUNMA" if battle_hold else "HUCUM"]


# LOCAL SAVE: stores resources and user-built structures on the Android device.
const SAVE_PATH := "user://rise_of_conquest_save.json"

func save_game(show_message: bool) -> void:
	var data := {
		"version": 1,
		"coins": coins, "woods": woods, "stones": stones, "foods": foods,
		"buildings": buildings_saved,
		"ruler_x": ruler.position.x, "ruler_z": ruler.position.z
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		status = "Kayit hatasi: dosya acilamadi."
		update_ui()
		return
	file.store_string(JSON.stringify(data))
	file.close()
	if show_message:
		status = "Sehir kaydedildi!"
		update_ui()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
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
			var kind: String = str(entry.get("kind", ""))
			if kind not in ["Ev", "Kule", "Kışla", "Çiftlik", "Kereste", "Taşocağı"]:
				continue
			var x := int(entry.get("x", 0))
			var z := int(entry.get("z", 0))
			if absi(x) > 14 or absi(z) > 14:
				continue
			create_building(kind, Vector3(x, 0, z))
			buildings_saved.append({"kind": kind, "x": x, "z": z})
	ruler.position.x = clampf(float(data.get("ruler_x", 3.0)), -14.0, 14.0)
	ruler.position.z = clampf(float(data.get("ruler_z", 4.0)), -14.0, 14.0)
	status = "Kayitli sehrin yuklendi."
