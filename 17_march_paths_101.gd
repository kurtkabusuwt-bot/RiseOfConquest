extends "res://build101/module_base_101.gd"
# Build 101 | 17/50 | Yürüyüş yolları
const DOMAIN := "march_paths"
func _ready() -> void:
    configure(DOMAIN, "Yürüyüş yolları", ["army", "points", "cost"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
