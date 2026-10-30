extends "res://build101/module_base_101.gd"
# Build 101 | 25/50 | Savaş karşılaşmaları
const DOMAIN := "battle_encounters"
func _ready() -> void:
    configure(DOMAIN, "Savaş karşılaşmaları", ["attacker", "defender", "round"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
