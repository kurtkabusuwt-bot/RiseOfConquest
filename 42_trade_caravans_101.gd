extends "res://build101/module_base_101.gd"
# Build 101 | 42/50 | Ticaret kervanları
const DOMAIN := "trade_caravans"
func _ready() -> void:
    configure(DOMAIN, "Ticaret kervanları", ["source", "target", "cargo"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
