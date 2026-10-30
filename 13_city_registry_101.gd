extends "res://build101/module_base_101.gd"
# Build 101 | 13/50 | Şehir kayıtları
const DOMAIN := "city_registry"
func _ready() -> void:
    configure(DOMAIN, "Şehir kayıtları", ["owner", "x", "y", "level"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
func set_position(id: String, x: int, y: int) -> bool:
    if x < 0 or y < 0 or x >= 1200 or y >= 1200:
        return false
    return put_record(id, {"x": x, "y": y})
