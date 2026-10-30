extends "res://build101/module_base_101.gd"
# Build 101 | 28/50 | Sur dayanıklılığı
const DOMAIN := "wall_integrity"
func _ready() -> void:
    configure(DOMAIN, "Sur dayanıklılığı", ["city", "health", "max_health"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
func apply_damage(id: String, damage: float) -> bool:
    return add_number(id, "health", -maxf(0.0, damage))
