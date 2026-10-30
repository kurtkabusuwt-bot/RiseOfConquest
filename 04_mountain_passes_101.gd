extends "res://build101/module_base_101.gd"
# Build 101 | 04/50 | Dağ geçitleri
const DOMAIN := "mountain_passes"
func _ready() -> void:
    configure(DOMAIN, "Dağ geçitleri", ["open", "toll"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
