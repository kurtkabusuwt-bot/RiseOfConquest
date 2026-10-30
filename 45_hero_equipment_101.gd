extends "res://build101/module_base_101.gd"
# Build 101 | 45/50 | Kahraman ekipmanları
const DOMAIN := "hero_equipment"
func _ready() -> void:
    configure(DOMAIN, "Kahraman ekipmanları", ["hero", "slot", "item"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
