extends "res://build101/module_base_101.gd"
# Build 101 | 09/50 | Tarafsız devriyeler
const DOMAIN := "neutral_patrols"
func _ready() -> void:
    configure(DOMAIN, "Tarafsız devriyeler", ["level", "power", "position"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
