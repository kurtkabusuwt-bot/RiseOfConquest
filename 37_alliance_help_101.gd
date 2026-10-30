extends "res://build101/module_base_101.gd"
# Build 101 | 37/50 | İttifak yardımı
const DOMAIN := "alliance_help"
func _ready() -> void:
    configure(DOMAIN, "İttifak yardımı", ["sender", "receiver", "seconds"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
