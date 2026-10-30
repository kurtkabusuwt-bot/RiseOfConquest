extends "res://build101/module_base_101.gd"
# Build 101 | 07/50 | Kaynak toplama
const DOMAIN := "resource_harvest"
func _ready() -> void:
    configure(DOMAIN, "Kaynak toplama", ["army", "amount", "finish"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
func change_amount(id: String, delta: float) -> bool:
    return add_number(id, "amount", delta)
func is_finished(id: String, now_unix: int) -> bool:
    var data := get_record(id)
    return not data.is_empty() and now_unix >= int(data.get("finish", 2147483647))
