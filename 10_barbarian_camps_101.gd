extends "res://build101/module_base_101.gd"
# Build 101 | 10/50 | Barbar kampları
const DOMAIN := "barbarian_camps"
func _ready() -> void:
    configure(DOMAIN, "Barbar kampları", ["level", "health", "reward"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
func apply_damage(id: String, damage: float) -> bool:
    return add_number(id, "health", -maxf(0.0, damage))
