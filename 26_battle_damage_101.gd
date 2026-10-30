extends "res://build101/module_base_101.gd"
# Build 101 | 26/50 | Savaş hasarı
const DOMAIN := "battle_damage"
func _ready() -> void:
    configure(DOMAIN, "Savaş hasarı", ["source", "target", "amount"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
func change_amount(id: String, delta: float) -> bool:
    return add_number(id, "amount", delta)
