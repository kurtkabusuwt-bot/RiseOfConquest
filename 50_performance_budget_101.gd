extends "res://build101/module_base_101.gd"
# Build 101 | 50/50 | Performans bütçesi
const DOMAIN := "performance_budget"
func _ready() -> void:
    configure(DOMAIN, "Performans bütçesi", ["quality", "limit", "active"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
