extends RefCounted

# Rise of Conquest | Build 102 | Rule 178/200
# Domain: life | Feature: citizen_job
# Local simulation rule. Does not provide network synchronization or 3D assets.
const RULE_ID := "citizen_job"
const DOMAIN := "life"
const SALT := 17995

func execute(state: Dictionary, payload: Dictionary) -> Dictionary:
    var npc_id := str(payload.get("id", ""))
    if npc_id.is_empty():
        return {"ok": false, "error": "missing_id"}
    var group: Dictionary = state.get(RULE_ID, {})
    var current: Dictionary = group.get(npc_id, {})
    current.merge(payload.duplicate(true), true)
    group[npc_id] = current
    state[RULE_ID] = group
    return {"ok": true, "id": npc_id, "total": group.size()}
