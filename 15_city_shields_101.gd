extends "res://build101/module_base_101.gd"
# Build 101 | 15/50 | Şehir kalkanları
const DOMAIN := "city_shields"
func _ready() -> void:
    configure(DOMAIN, "Şehir kalkanları", ["city", "expires"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
