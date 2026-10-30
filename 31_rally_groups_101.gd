extends "res://build101/module_base_101.gd"
# Build 101 | 31/50 | Toplu saldırılar
const DOMAIN := "rally_groups"
func _ready() -> void:
    configure(DOMAIN, "Toplu saldırılar", ["leader", "target", "limit"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
