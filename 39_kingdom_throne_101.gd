extends "res://build101/module_base_101.gd"
# Build 101 | 39/50 | Krallık tahtı
const DOMAIN := "kingdom_throne"
func _ready() -> void:
    configure(DOMAIN, "Krallık tahtı", ["owner", "term", "score"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
