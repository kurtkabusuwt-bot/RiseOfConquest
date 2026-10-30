extends "res://build101/module_base_101.gd"
# Build 101 | 21/50 | Asker eğitimi
const DOMAIN := "troop_training"
func _ready() -> void:
    configure(DOMAIN, "Asker eğitimi", ["kind", "tier", "quantity"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
