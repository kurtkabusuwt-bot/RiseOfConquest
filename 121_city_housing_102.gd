extends RefCounted

# Rise of Conquest | Build 102 | Rule 121/200
# Domain: economy | Feature: city_housing
# Local simulation rule. Does not provide network synchronization or 3D assets.
const RULE_ID := "city_housing"
const DOMAIN := "economy"
const SALT := 12238

func execute(state: Dictionary, payload: Dictionary) -> Dictionary:
    var key := str(payload.get("id", ""))
    if key.is_empty():
        return {"ok": false, "error": "missing_id"}
    var group: Dictionary = state.get(RULE_ID, {})
    var current: Dictionary = group.get(key, {})
    current.merge(payload.duplicate(true), true)
    group[key] = current
    state[RULE_ID] = group
    return {"ok": true, "id": key, "record": current.duplicate(true)}
