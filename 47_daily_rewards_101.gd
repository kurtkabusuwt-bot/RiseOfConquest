extends "res://build101/module_base_101.gd"
# Build 101 | 47/50 | Günlük ödüller
const DOMAIN := "daily_rewards"
func _ready() -> void:
    configure(DOMAIN, "Günlük ödüller", ["day", "claimed", "amount"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
func change_amount(id: String, delta: float) -> bool:
    return add_number(id, "amount", delta)
func claim(id: String) -> bool:
    if get_record(id).is_empty() or bool(get_record(id).get("claimed", false)):
        return false
    return put_record(id, {"claimed": true})
