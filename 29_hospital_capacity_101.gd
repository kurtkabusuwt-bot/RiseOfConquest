extends "res://build101/module_base_101.gd"
# Build 101 | 29/50 | Hastane kapasitesi
const DOMAIN := "hospital_capacity"
func _ready() -> void:
    configure(DOMAIN, "Hastane kapasitesi", ["city", "capacity", "wounded"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
