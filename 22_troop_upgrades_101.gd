extends "res://build101/module_base_101.gd"
# Build 101 | 22/50 | Asker yükseltme
const DOMAIN := "troop_upgrades"
func _ready() -> void:
    configure(DOMAIN, "Asker yükseltme", ["kind", "from_tier", "to_tier"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
