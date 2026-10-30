extends "res://build101/module_base_101.gd"
# Build 101 | 48/50 | Halk talepleri
const DOMAIN := "npc_requests"
func _ready() -> void:
    configure(DOMAIN, "Halk talepleri", ["npc", "need", "reward"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
