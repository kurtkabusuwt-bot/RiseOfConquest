extends "res://build101/module_base_101.gd"
# Build 101 | 18/50 | Yürüyüş hızları
const DOMAIN := "march_speed"
func _ready() -> void:
    configure(DOMAIN, "Yürüyüş hızları", ["army", "multiplier", "duration"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
