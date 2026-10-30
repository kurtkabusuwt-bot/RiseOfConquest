extends Node
class_name ROC40CivilizationBonus

# RISE OF CONQUEST | KINGDOM BUILD 100 | MODULE 40/50
# Medeniyet bonusları
# Godot 4.4.1 | Local prototype implementation
# The module is isolated and can be integrated incrementally.

signal record_changed(record_id: String)
signal record_removed(record_id: String)
signal event_logged(event_name: String, payload: Dictionary)

const MODULE_ID := "civilization_bonus"
const MODULE_NUMBER := 40
const MAX_EVENTS := 100

var records: Dictionary = {}
var event_log: Array[Dictionary] = []
var settings: Dictionary = {"enabled": true, "max_records": 5000}
var elapsed_seconds := 0.0
var active := true

func _process(delta: float) -> void:
    if active:
        elapsed_seconds += maxf(delta, 0.0)

func create_record(record_id: String, payload: Dictionary) -> bool:
    if record_id.is_empty() or records.has(record_id):
        return false
    if records.size() >= int(settings.get("max_records", 5000)):
        return false
    records[record_id] = payload.duplicate(true)
    _log("created", {"id": record_id})
    record_changed.emit(record_id)
    return true

func update_record(record_id: String, changes: Dictionary) -> bool:
    if not records.has(record_id):
        return false
    var current: Dictionary = records[record_id]
    for key in changes.keys():
        current[key] = changes[key]
    records[record_id] = current
    _log("updated", {"id": record_id})
    record_changed.emit(record_id)
    return true

func remove_record(record_id: String) -> bool:
    if not records.has(record_id):
        return false
    records.erase(record_id)
    _log("removed", {"id": record_id})
    record_removed.emit(record_id)
    return true

func get_record(record_id: String) -> Dictionary:
    if not records.has(record_id):
        return {}
    return (records[record_id] as Dictionary).duplicate(true)

func get_records_by(field: String, value: Variant) -> Array[Dictionary]:
    var found: Array[Dictionary] = []
    for record in records.values():
        if record is Dictionary and record.get(field) == value:
            found.append(record.duplicate(true))
    return found

func set_enabled(value: bool) -> void:
    active = value
    settings["enabled"] = value

func _log(name: String, payload: Dictionary) -> void:
    event_log.append({"name": name, "payload": payload.duplicate(true), "time": elapsed_seconds})
    if event_log.size() > MAX_EVENTS:
        event_log.pop_front()
    event_logged.emit(name, payload)

func export_state() -> Dictionary:
    return {"module": MODULE_ID, "records": records.duplicate(true), "settings": settings.duplicate(true), "elapsed": elapsed_seconds}

func import_state(data: Dictionary) -> bool:
    if str(data.get("module", "")) != MODULE_ID:
        return false
    var new_records: Variant = data.get("records", {})
    if not (new_records is Dictionary):
        return false
    records = new_records.duplicate(true)
    var new_settings: Variant = data.get("settings", {})
    if new_settings is Dictionary:
        settings.merge(new_settings, true)
    elapsed_seconds = maxf(0.0, float(data.get("elapsed", 0.0)))
    active = bool(settings.get("enabled", true))
    return true

func get_module_info() -> Dictionary:
    return {"number": MODULE_NUMBER, "id": MODULE_ID, "title": "Medeniyet bonusları", "record_count": records.size(), "enabled": active}

func start_job(job_id: String, duration_seconds: float, payload: Dictionary) -> bool:
    if duration_seconds <= 0.0:
        return false
    var job := payload.duplicate(true)
    job["started_at"] = elapsed_seconds
    job["finishes_at"] = elapsed_seconds + duration_seconds
    job["completed"] = false
    return create_record(job_id, job)

func finish_ready_jobs() -> Array[String]:
    var finished: Array[String] = []
    for key in records.keys():
        var job: Dictionary = records[key]
        if job.has("finishes_at") and not bool(job.get("completed", false)) and elapsed_seconds >= float(job["finishes_at"]):
            job["completed"] = true
            records[key] = job
            finished.append(str(key))
            record_changed.emit(str(key))
    return finished
