extends "res://build101/module_base_101.gd"
# Build 101 | 49/50 | Bildirim akışı
const DOMAIN := "notification_feed"
func _ready() -> void:
    configure(DOMAIN, "Bildirim akışı", ["message", "priority", "read"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
