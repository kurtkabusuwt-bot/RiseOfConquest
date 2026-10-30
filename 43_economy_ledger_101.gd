extends "res://build101/module_base_101.gd"
# Build 101 | 43/50 | Ekonomi kayıtları
const DOMAIN := "economy_ledger"
func _ready() -> void:
    configure(DOMAIN, "Ekonomi kayıtları", ["kind", "amount", "reason"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
func change_amount(id: String, delta: float) -> bool:
    return add_number(id, "amount", delta)
