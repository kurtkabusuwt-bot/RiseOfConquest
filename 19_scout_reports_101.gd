extends "res://build101/module_base_101.gd"
# Build 101 | 19/50 | Keşif raporları
const DOMAIN := "scout_reports"
func _ready() -> void:
    configure(DOMAIN, "Keşif raporları", ["target", "visibility", "expires"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
