extends "res://build101/module_base_101.gd"
# Build 101 | 06/50 | Kaynak üretimi
const DOMAIN := "resource_spawns"
func _ready() -> void:
    configure(DOMAIN, "Kaynak üretimi", ["kind", "amount", "level"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
func change_amount(id: String, delta: float) -> bool:
    return add_number(id, "amount", delta)
