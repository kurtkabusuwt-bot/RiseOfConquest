extends "res://build101/module_base_101.gd"
# Build 101 | 46/50 | Görev ilerlemesi
const DOMAIN := "quest_progress"
func _ready() -> void:
    configure(DOMAIN, "Görev ilerlemesi", ["goal", "current", "reward"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
