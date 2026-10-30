extends RefCounted

# Rise of Conquest | Build 102 | Rule 016/200
# Domain: world | Feature: discovery
# Local simulation rule. Does not provide network synchronization or 3D assets.
const RULE_ID := "discovery"
const DOMAIN := "world"
const SALT := 1633

func execute(state: Dictionary, payload: Dictionary) -> Dictionary:
    var key := str(payload.get("key", ""))
    if key.is_empty():
        return {"ok": false, "error": "missing_key"}
    var group: Dictionary = state.get(RULE_ID, {})
    group[key] = payload.get("value", true)
    state[RULE_ID] = group
    return {"ok": true, "key": key, "count": group.size()}
