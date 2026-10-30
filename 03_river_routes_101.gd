extends "res://build101/module_base_101.gd"
# Build 101 | 03/50 | Nehir geçitleri
const DOMAIN := "river_routes"
func _ready() -> void:
    configure(DOMAIN, "Nehir geçitleri", ["crossable", "cost"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
