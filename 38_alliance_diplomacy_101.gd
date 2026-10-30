extends "res://build101/module_base_101.gd"
# Build 101 | 38/50 | Diplomasi
const DOMAIN := "alliance_diplomacy"
func _ready() -> void:
    configure(DOMAIN, "Diplomasi", ["source", "target", "relation"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
