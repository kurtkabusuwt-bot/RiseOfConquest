extends RefCounted

# Rise of Conquest | Build 102 | Rule 084/200
# Domain: alliance | Feature: alliance_territory
# Local simulation rule. Does not provide network synchronization or 3D assets.
const RULE_ID := "alliance_territory"
const DOMAIN := "alliance"
const SALT := 8501

func execute(state: Dictionary, payload: Dictionary) -> Dictionary:
    var alliance_id := str(payload.get("alliance_id", ""))
    if alliance_id.is_empty():
        return {"ok": false, "error": "missing_alliance_id"}
    var group: Dictionary = state.get(RULE_ID, {})
    var record: Dictionary = group.get(alliance_id, {})
    record.merge(payload.duplicate(true), true)
    group[alliance_id] = record
    state[RULE_ID] = group
    return {"ok": true, "alliance_id": alliance_id, "count": group.size()}
