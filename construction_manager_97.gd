
extends CanvasLayer

# ============================================================
# RISE OF CONQUEST - BUILD 97.0
# ADVANCED CITY CONSTRUCTION MANAGER
# Godot 4.4.1 / Android
#
# FEATURES
# - City construction dashboard
# - Building selection
# - Resource monitoring
# - Production monitoring
# - Building statistics
# - Construction cost calculation
# - Affordability checks
# - Placement guidance
# - Construction history
# - Responsive mobile layout
# - Safe game integration
# ============================================================

const BUILD_VERSION := "97.0"

const COLOR_BG := Color(0.035, 0.055, 0.09, 0.97)
const COLOR_PANEL := Color(0.075, 0.105, 0.15, 0.97)
const COLOR_GOLD := Color(0.91, 0.73, 0.40)
const COLOR_WHITE := Color(0.95, 0.96, 0.98)
const COLOR_MUTED := Color(0.68, 0.74, 0.81)
const COLOR_GREEN := Color(0.24, 0.72, 0.45)
const COLOR_RED := Color(0.83, 0.32, 0.30)
const COLOR_BLUE := Color(0.24, 0.51, 0.79)

const BUILDINGS := {
    "Ev": {
        "description": "Altin uretimini destekler.",
        "cost": {"woods": 100},
        "category": "Ekonomi"
    },
    "Çiftlik": {
        "description": "Sehir icin yiyecek uretir.",
        "cost": {"woods": 80},
        "category": "Ekonomi"
    },
    "Kereste": {
        "description": "Odun uretimini artirir.",
        "cost": {"coins": 100},
        "category": "Ekonomi"
    },
    "Taşocağı": {
        "description": "Tas uretimini artirir.",
        "cost": {"woods": 100},
        "category": "Ekonomi"
    },
    "Kışla": {
        "description": "Askeri gelisimin temel binasidir.",
        "cost": {"woods": 200},
        "category": "Askeri"
    },
    "Kule": {
        "description": "Sehir savunmasini destekler.",
        "cost": {"coins": 150},
        "category": "Savunma"
    }
}

const RESOURCE_NAMES := {
    "coins": "Altin",
    "woods": "Odun",
    "stones": "Tas",
    "foods": "Yiyecek"
}

var game: Node = null

var root_control: Control
var open_button: Button
var window: PanelContainer
var scroll: ScrollContainer
var main_column: VBoxContainer

var title_label: Label
var resource_label: Label
var production_label: Label
var selected_label: Label
var description_label: Label
var cost_label: Label
var affordability_label: Label
var placement_label: Label
var city_stats_label: Label
var history_label: Label

var building_buttons: Dictionary = {}

var selected_kind := "Ev"
var history: Array[String] = []

var last_pending := false
var last_status := ""
var last_building_count := -1

var refresh_timer := 0.0
var ui_open := false

var current_screen_size := Vector2.ZERO


# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
    layer = 90
    game = get_parent()

    _create_interface()
    _resize_interface()
    _refresh_all()

    get_viewport().size_changed.connect(
        _resize_interface
    )

    set_process(true)


# ============================================================
# STYLING
# ============================================================

func _style_panel(
    color: Color,
    border_color: Color
) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border_color
    style.set_border_width_all(1)
    style.set_corner_radius_all(12)
    style.set_content_margin_all(12)
    return style


func _create_label(
    value: String,
    font_size: int = 14,
    color: Color = COLOR_WHITE
) -> Label:
    var label := Label.new()
    label.text = value
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override(
        "font_size", font_size
    )
    label.add_theme_color_override(
        "font_color", color
    )
    return label


func _create_button(
    value: String,
    color: Color = COLOR_BLUE
) -> Button:
    var button := Button.new()
    button.text = value
    button.custom_minimum_size = Vector2(100, 48)

    var style := _style_panel(
        color,
        color.lightened(0.15)
    )
    style.set_content_margin_all(7)

    var hover := style.duplicate() as StyleBoxFlat
    hover.bg_color = color.lightened(0.12)

    var pressed := style.duplicate() as StyleBoxFlat
    pressed.bg_color = color.darkened(0.16)

    button.add_theme_stylebox_override(
        "normal", style
    )
    button.add_theme_stylebox_override(
        "hover", hover
    )
    button.add_theme_stylebox_override(
        "pressed", pressed
    )

    button.add_theme_color_override(
        "font_color", COLOR_WHITE
    )
    button.add_theme_color_override(
        "font_hover_color", COLOR_WHITE
    )

    return button


func _add_section(
    parent: VBoxContainer,
    heading: String
) -> VBoxContainer:
    var section := VBoxContainer.new()
    section.add_theme_constant_override(
        "separation", 6
    )

    var heading_label := _create_label(
        heading, 16, COLOR_GOLD
    )

    section.add_child(heading_label)
    parent.add_child(section)

    return section


# ============================================================
# INTERFACE
# ============================================================

func _create_interface() -> void:
    root_control = Control.new()
    root_control.name = "ConstructionManagerRoot"
    root_control.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT
    )
    root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root_control)

    open_button = _create_button(
        "INSAAT +", COLOR_GOLD.darkened(0.35)
    )
    open_button.name = "ConstructionManagerOpen"
    open_button.pressed.connect(_toggle_window)
    root_control.add_child(open_button)

    window = PanelContainer.new()
    window.name = "ConstructionManagerWindow"
    window.add_theme_stylebox_override(
        "panel",
        _style_panel(COLOR_BG, COLOR_GOLD)
    )
    root_control.add_child(window)

    var outer := VBoxContainer.new()
    outer.add_theme_constant_override(
        "separation", 10
    )
    window.add_child(outer)

    var header := HBoxContainer.new()
    outer.add_child(header)

    title_label = _create_label(
        "SEHIR INSAAT YONETIMI",
        18,
        COLOR_GOLD
    )
    title_label.size_flags_horizontal = (
        Control.SIZE_EXPAND_FILL
    )
    header.add_child(title_label)

    var close_button := _create_button(
        "X", COLOR_RED
    )
    close_button.custom_minimum_size = Vector2(44, 44)
    close_button.pressed.connect(_close_window)
    header.add_child(close_button)

    scroll = ScrollContainer.new()
    scroll.size_flags_vertical = (
        Control.SIZE_EXPAND_FILL
    )
    outer.add_child(scroll)

    main_column = VBoxContainer.new()
    main_column.size_flags_horizontal = (
        Control.SIZE_EXPAND_FILL
    )
    main_column.add_theme_constant_override(
        "separation", 14
    )
    scroll.add_child(main_column)

    _build_resource_section()
    _build_selection_section()
    _build_cost_section()
    _build_placement_section()
    _build_statistics_section()
    _build_history_section()

    var footer := HBoxContainer.new()
    footer.add_theme_constant_override(
        "separation", 8
    )
    outer.add_child(footer)

    var start_button := _create_button(
        "KONUM SEC", COLOR_GREEN.darkened(0.15)
    )
    start_button.size_flags_horizontal = (
        Control.SIZE_EXPAND_FILL
    )
    start_button.pressed.connect(
        _start_selected_construction
    )
    footer.add_child(start_button)

    var refresh_button := _create_button(
        "YENILE", COLOR_BLUE
    )
    refresh_button.pressed.connect(_refresh_all)
    footer.add_child(refresh_button)

    window.visible = false


# ============================================================
# RESOURCE SECTION
# ============================================================

func _build_resource_section() -> void:
    var section := _add_section(
        main_column, "KAYNAKLAR"
    )

    resource_label = _create_label(
        "Kaynaklar yukleniyor...",
        14,
        COLOR_WHITE
    )
    section.add_child(resource_label)

    production_label = _create_label(
        "Uretim hesaplanıyor...",
        12,
        COLOR_MUTED
    )
    section.add_child(production_label)


# ============================================================
# BUILDING SELECTION
# ============================================================

func _build_selection_section() -> void:
    var section := _add_section(
        main_column, "BINA SECIMI"
    )

    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override(
        "h_separation", 8
    )
    grid.add_theme_constant_override(
        "v_separation", 8
    )
    section.add_child(grid)

    for kind in BUILDINGS.keys():
        var button := _create_button(
            str(kind),
            COLOR_PANEL.lightened(0.15)
        )
        button.size_flags_horizontal = (
            Control.SIZE_EXPAND_FILL
        )
        button.pressed.connect(
            _select_building.bind(str(kind))
        )
        grid.add_child(button)
        building_buttons[kind] = button

    selected_label = _create_label(
        "Secilen bina: Ev",
        15,
        COLOR_GOLD
    )
    section.add_child(selected_label)

    description_label = _create_label(
        "",
        13,
        COLOR_MUTED
    )
    section.add_child(description_label)


# ============================================================
# COST SECTION
# ============================================================

func _build_cost_section() -> void:
    var section := _add_section(
        main_column, "INSAAT MALIYETI"
    )

    cost_label = _create_label(
        "", 14, COLOR_WHITE
    )
    section.add_child(cost_label)

    affordability_label = _create_label(
        "", 13, COLOR_GREEN
    )
    section.add_child(affordability_label)


# ============================================================
# PLACEMENT SECTION
# ============================================================

func _build_placement_section() -> void:
    var section := _add_section(
        main_column, "YERLESTIRME DURUMU"
    )

    placement_label = _create_label(
        "", 13, COLOR_WHITE
    )
    section.add_child(placement_label)


# ============================================================
# STATISTICS SECTION
# ============================================================

func _build_statistics_section() -> void:
    var section := _add_section(
        main_column, "SEHIR ISTATISTIKLERI"
    )

    city_stats_label = _create_label(
        "", 13, COLOR_WHITE
    )
    section.add_child(city_stats_label)


# ============================================================
# HISTORY SECTION
# ============================================================

func _build_history_section() -> void:
    var section := _add_section(
        main_column, "INSAAT GECMISI"
    )

    history_label = _create_label(
        "Henuz yeni insaat kaydi yok.",
        12,
        COLOR_MUTED
    )
    section.add_child(history_label)


# ============================================================
# RESPONSIVE LAYOUT
# ============================================================

func _resize_interface() -> void:
    if not is_instance_valid(root_control):
        return

    current_screen_size = (
        get_viewport().get_visible_rect().size
    )

    var width := current_screen_size.x
    var height := current_screen_size.y

    var button_width := 125.0
    var button_height := 48.0

    open_button.set_anchors_preset(
        Control.PRESET_TOP_RIGHT
    )
    open_button.offset_left = -button_width - 12.0
    open_button.offset_right = -12.0
    open_button.offset_top = 90.0
    open_button.offset_bottom = (
        90.0 + button_height
    )

    var panel_width := minf(
        width * 0.92,
        470.0
    )

    var panel_height := minf(
        height * 0.84,
        720.0
    )

    window.set_anchors_preset(
        Control.PRESET_CENTER
    )

    window.offset_left = -panel_width * 0.5
    window.offset_right = panel_width * 0.5
    window.offset_top = -panel_height * 0.5
    window.offset_bottom = panel_height * 0.5

    window.custom_minimum_size = Vector2(
        panel_width,
        panel_height
    )


# ============================================================
# WINDOW CONTROL
# ============================================================

func _toggle_window() -> void:
    ui_open = not ui_open
    window.visible = ui_open

    if ui_open:
        _refresh_all()


func _close_window() -> void:
    ui_open = false
    window.visible = false


# ============================================================
# BUILDING SELECTION
# ============================================================

func _select_building(kind: String) -> void:
    if not BUILDINGS.has(kind):
        return

    selected_kind = kind
    _refresh_all()


# ============================================================
# GAME RESOURCE ACCESS
# ============================================================

func _resource_value(key: String) -> int:
    if not is_instance_valid(game):
        return 0

    return int(game.get(key))


func _resource_display_name(key: String) -> String:
    return str(
        RESOURCE_NAMES.get(key, key)
    )


func _get_building_cost(kind: String) -> Dictionary:
    if not BUILDINGS.has(kind):
        return {}

    var info: Dictionary = BUILDINGS[kind]
    return info.get("cost", {})


func _get_affordability_problem(
    kind: String
) -> String:
    var costs := _get_building_cost(kind)

    if costs.is_empty():
        return "Bina maliyeti tanimli degil."

    for key in costs.keys():
        var required := int(costs[key])
        var available := _resource_value(str(key))

        if available < required:
            return (
                "%s eksik: %d"
                % [
                    _resource_display_name(str(key)),
                    required - available
                ]
            )

    if is_instance_valid(game):
        if game.has_method(
            "_construction_cost_problem"
        ):
            var game_problem := str(
                game.call(
                    "_construction_cost_problem",
                    kind
                )
            )
            if not game_problem.is_empty():
                return game_problem

    return ""


# ============================================================
# RESOURCE DISPLAY
# ============================================================

func _refresh_resources() -> void:
    if not is_instance_valid(game):
        return

    resource_label.text = (
        "Altin: %d\n"
        + "Odun: %d\n"
        + "Tas: %d\n"
        + "Yiyecek: %d"
    ) % [
        _resource_value("coins"),
        _resource_value("woods"),
        _resource_value("stones"),
        _resource_value("foods")
    ]

    if game.has_method(
        "get_resource_production_per_minute"
    ):
        var production: Dictionary = game.call(
            "get_resource_production_per_minute"
        )

        production_label.text = (
            "Dakikalik uretim\n"
            + "Altin: %d | Odun: %d\n"
            + "Tas: %d | Yiyecek: %d"
        ) % [
            int(production.get("coins", 0)),
            int(production.get("woods", 0)),
            int(production.get("stones", 0)),
            int(production.get("foods", 0))
        ]
    else:
        production_label.text = (
            "Uretim bilgisi kullanilamiyor."
        )


# ============================================================
# COST DISPLAY
# ============================================================

func _refresh_cost() -> void:
    if not BUILDINGS.has(selected_kind):
        return

    var info: Dictionary = BUILDINGS[selected_kind]

    selected_label.text = (
        "Secilen bina: " + selected_kind
    )

    description_label.text = str(
        info.get("description", "")
    )

    var costs := _get_building_cost(selected_kind)
    var lines: PackedStringArray = []

    for key in costs.keys():
        lines.append(
            "%d %s"
            % [
                int(costs[key]),
                _resource_display_name(str(key))
            ]
        )

    cost_label.text = (
        "Gereken: " + ", ".join(lines)
    )

    var problem := _get_affordability_problem(
        selected_kind
    )

    if problem.is_empty():
        affordability_label.text = (
            "Kaynaklar yeterli."
        )
        affordability_label.add_theme_color_override(
            "font_color",
            COLOR_GREEN
        )
    else:
        affordability_label.text = problem
        affordability_label.add_theme_color_override(
            "font_color",
            COLOR_RED
        )

    for kind in building_buttons.keys():
        var button: Button = building_buttons[kind]

        if kind == selected_kind:
            button.modulate = COLOR_GOLD
        else:
            button.modulate = COLOR_WHITE


# ============================================================
# PLACEMENT DISPLAY
# ============================================================

func _refresh_placement() -> void:
    if not is_instance_valid(game):
        return

    var placing := bool(game.get("placing"))

    var pending := false

    if game.has_method(
        "get_construction_pending"
    ):
        pending = bool(
            game.call("get_construction_pending")
        )

    if pending:
        var position := Vector3.ZERO

        if game.has_method(
            "get_construction_position"
        ):
            position = game.call(
                "get_construction_position"
            )

        placement_label.text = (
            "Konum onay bekliyor.\n"
            + "X: %d | Z: %d\n"
            + "Insaat onay panelini kullan."
        ) % [
            roundi(position.x),
            roundi(position.z)
        ]

    elif placing:
        placement_label.text = (
            "Konum secimi aktif.\n"
            + "Sehir zeminine dokun."
        )

    else:
        placement_label.text = (
            "Konum secimi pasif."
        )


# ============================================================
# CITY STATISTICS
# ============================================================

func _get_building_counts() -> Dictionary:
    var counts := {}

    for kind in BUILDINGS.keys():
        counts[kind] = 0

    if not is_instance_valid(game):
        return counts

    if not game.has_method("_all_buildings"):
        return counts

    var buildings: Array = game.call(
        "_all_buildings"
    )

    for building in buildings:
        if not is_instance_valid(building):
            continue

        var kind := ""

        if game.has_method("_kind_from_name"):
            kind = str(
                game.call(
                    "_kind_from_name",
                    str(building.name)
                )
            )

        if counts.has(kind):
            counts[kind] += 1

    return counts


func _refresh_statistics() -> void:
    var counts := _get_building_counts()

    var total := 0
    var lines: PackedStringArray = []

    for kind in BUILDINGS.keys():
        var amount := int(
            counts.get(kind, 0)
        )

        total += amount

        lines.append(
            "%s: %d" % [kind, amount]
        )

    city_stats_label.text = (
        "Toplam bina: %d\n%s"
        % [
            total,
            "\n".join(lines)
        ]
    )


# ============================================================
# CONSTRUCTION HISTORY
# ============================================================

func _refresh_history() -> void:
    if history.is_empty():
        history_label.text = (
            "Bu oturumda yeni insaat yok."
        )
        return

    var lines: PackedStringArray = []

    for i in range(
        history.size() - 1,
        -1,
        -1
    ):
        li
