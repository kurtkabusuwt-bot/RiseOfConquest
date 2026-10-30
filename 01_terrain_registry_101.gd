extends "res://build101/module_base_101.gd"
# Build 101 | 01/50 | Arazi kayıtları
const DOMAIN := "terrain_registry"
func _ready() -> void:
    configure(DOMAIN, "Arazi kayıtları", ["type", "walkable", "height"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
