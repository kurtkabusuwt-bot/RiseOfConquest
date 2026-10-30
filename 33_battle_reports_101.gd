extends "res://build101/module_base_101.gd"
# Build 101 | 33/50 | Savaş raporları
const DOMAIN := "battle_reports"
func _ready() -> void:
    configure(DOMAIN, "Savaş raporları", ["winner", "losses", "time"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
