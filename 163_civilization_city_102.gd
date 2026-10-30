extends RefCounted

# Rise of Conquest | Build 102 | Rule 163/200
# Domain: heroes | Feature: civilization_city
# Local simulation rule. Does not provide network synchronization or 3D assets.
const RULE_ID := "civilization_city"
const DOMAIN := "heroes"
const SALT := 16480

func execute(state: Dictionary, payload: Dictionary) -> Dictionary:
    var hero_id := str(payload.get("hero_id", ""))
    if hero_id.is_empty():
        return {"ok": false, "error": "missing_hero_id"}
    var group: Dictionary = state.get(RULE_ID, {})
    group[hero_id] = payload.duplicate(true)
    state[RULE_ID] = group
    return {"ok": true, "hero_id": hero_id}
