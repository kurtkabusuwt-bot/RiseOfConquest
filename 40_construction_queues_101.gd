extends "res://build101/module_base_101.gd"
# Build 101 | 40/50 | İnşaat kuyrukları
const DOMAIN := "construction_queues"
func _ready() -> void:
    configure(DOMAIN, "İnşaat kuyrukları", ["building", "slot", "finish"])
func create_entry(id: String, values: Dictionary) -> bool:
    if id.is_empty():
        return false
    return put_record(id, values)
func is_finished(id: String, now_unix: int) -> bool:
    var data := get_record(id)
    return not data.is_empty() and now_unix >= int(data.get("finish", 2147483647))
