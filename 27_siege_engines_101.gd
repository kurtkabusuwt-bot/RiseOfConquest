extends "res://build101/module_base_101.gd"
# Build 101 | 27/50 | Kuşatma makineleri
const DOMAIN := "siege_engines"
func _ready() -> void:
    configure(DOMAIN, "Kuşatma makineleri", ["kind", "level", "attack"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
