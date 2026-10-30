extends "res://build101/module_base_101.gd"
# Build 101 | 35/50 | İttifak toprağı
const DOMAIN := "alliance_territory"
func _ready() -> void:
    configure(DOMAIN, "İttifak toprağı", ["alliance", "region", "control"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
