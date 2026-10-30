extends "res://build101/module_base_101.gd"
# Build 101 | 16/50 | Yürüyüş emirleri
const DOMAIN := "march_orders"
func _ready() -> void:
    configure(DOMAIN, "Yürüyüş emirleri", ["army", "target", "eta"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
