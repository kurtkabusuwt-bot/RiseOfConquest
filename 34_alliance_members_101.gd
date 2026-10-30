extends "res://build101/module_base_101.gd"
# Build 101 | 34/50 | İttifak üyeleri
const DOMAIN := "alliance_members"
func _ready() -> void:
    configure(DOMAIN, "İttifak üyeleri", ["player", "rank", "power"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
