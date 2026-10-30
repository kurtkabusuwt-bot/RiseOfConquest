extends "res://build101/module_base_101.gd"
# Build 101 | 12/50 | Kutsal alanlar
const DOMAIN := "holy_sites"
func _ready() -> void:
    configure(DOMAIN, "Kutsal alanlar", ["owner", "buff", "level"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
