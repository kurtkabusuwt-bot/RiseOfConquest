extends Node
# Build 101: shared validated state container for one gameplay domain.
signal changed(record_id: String)
signal removed(record_id: String)
var domain_id := ""
var display_name := ""
var allowed_fields: Array[String] = []
var records: Dictionary = {}
var revision := 0
const MAX_RECORDS := 2500
func configure(id: String, title: String, fields: Array[String]) -> void:
    domain_id = id
    display_name = title
    allowed_fields = fields.duplicate()
func put_record(id: String, data: Dictionary) -> bool:
    if id.is_empty() or (not records.has(id) and records.size() >= MAX_RECORDS):
        return false
    for field in data.keys():
        if not allowed_fields.has(str(field)):
            return false
    var previous: Dictionary = records.get(id, {})
    var merged := previous.duplicate(true)
    for field in data.keys():
        merged[field] = data[field]
    records[id] = merged
    revision += 1
    changed.emit(id)
    return true
func erase_record(id: String) -> bool:
    if not records.has(id):
        return false
    records.erase(id)
    revision += 1
    removed.emit(id)
    return true
func get_record(id: String) -> Dictionary:
    return (records.get(id, {}) as Dictionary).duplicate(true)
func list_records() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for id in records.keys():
        var data: Dictionary = records[id]
        var row := data.duplicate(true)
        row["id"] = id
        result.append(row)
    return result
func add_number(id: String, field: String, amount: float, minimum: float = 0.0) -> bool:
    if not allowed_fields.has(field):
        return false
    var data := get_record(id)
    var value := maxf(minimum, float(data.get(field, 0.0)) + amount)
    return put_record(id, {field: value})
func export_state() -> Dictionary:
    return {"domain": domain_id, "revision": revision, "records": records.duplicate(true)}
func import_state(data: Dictionary) -> bool:
    if str(data.get("domain", "")) != domain_id:
        return false
    var raw: Variant = data.get("records", {})
    if not (raw is Dictionary) or raw.size() > MAX_RECORDS:
        return false
    var clean: Dictionary = {}
    for id in raw.keys():
        if not (raw[id] is Dictionary):
            return false
        for field in raw[id].keys():
            if not allowed_fields.has(str(field)):
                return false
        clean[str(id)] = (raw[id] as Dictionary).duplicate(true)
    records = clean
    revision = maxi(0, int(data.get("revision", 0)))
    return true
