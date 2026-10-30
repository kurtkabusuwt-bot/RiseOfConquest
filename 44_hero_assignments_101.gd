extends "res://build101/module_base_101.gd"
# Build 101 | 44/50 | Kahraman atamaları
const DOMAIN := "hero_assignments"
func _ready() -> void:
    configure(DOMAIN, "Kahraman atamaları", ["hero", "army", "role"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
