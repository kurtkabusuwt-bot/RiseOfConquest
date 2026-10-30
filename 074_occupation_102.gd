extends RefCounted

# Rise of Conquest | Build 102 | Rule 074/200
# Domain: war | Feature: occupation
# Local simulation rule. Does not provide network synchronization or 3D assets.
const RULE_ID := "occupation"
const DOMAIN := "war"
const SALT := 7491

func execute(state: Dictionary, payload: Dictionary) -> Dictionary:
    var army_id := str(payload.get("army_id", ""))
    if army_id.is_empty():
        return {"ok": false, "error": "missing_army_id"}
    var group: Dictionary = state.get(RULE_ID, {})
    group[army_id] = payload.duplicate(true)
    state[RULE_ID] = group
    return {"ok": true, "army_id": army_id, "count": group.size()}
