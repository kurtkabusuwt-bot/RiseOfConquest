extends "res://build101/module_base_101.gd"
# Build 101 | 24/50 | Ordu morali
const DOMAIN := "army_morale"
func _ready() -> void:
    configure(DOMAIN, "Ordu morali", ["army", "value", "modifier"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
