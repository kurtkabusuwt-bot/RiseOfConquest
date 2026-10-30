extends "res://build101/module_base_101.gd"
# Build 101 | 02/50 | Bölge yönetimi
const DOMAIN := "region_control"
func _ready() -> void:
    configure(DOMAIN, "Bölge yönetimi", ["owner", "tax", "security"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
