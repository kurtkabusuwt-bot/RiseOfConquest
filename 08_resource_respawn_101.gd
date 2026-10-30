extends "res://build101/module_base_101.gd"
# Build 101 | 08/50 | Kaynak yenilenme
const DOMAIN := "resource_respawn"
func _ready() -> void:
    configure(DOMAIN, "Kaynak yenilenme", ["kind", "ready"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
