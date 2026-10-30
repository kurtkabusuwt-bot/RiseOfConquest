extends "res://build101/module_base_101.gd"
# Build 101 | 32/50 | Takviye birlikleri
const DOMAIN := "reinforcements"
func _ready() -> void:
    configure(DOMAIN, "Takviye birlikleri", ["city", "army", "arrival"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
