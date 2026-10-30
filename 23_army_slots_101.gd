extends "res://build101/module_base_101.gd"
# Build 101 | 23/50 | Ordu yuvaları
const DOMAIN := "army_slots"
func _ready() -> void:
    configure(DOMAIN, "Ordu yuvaları", ["commander", "capacity", "used"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
