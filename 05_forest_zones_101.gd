extends "res://build101/module_base_101.gd"
# Build 101 | 05/50 | Orman alanları
const DOMAIN := "forest_zones"
func _ready() -> void:
    configure(DOMAIN, "Orman alanları", ["wood", "density"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
