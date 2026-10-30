extends RefCounted

# Rise of Conquest | Build 102 | Rule 149/200
# Domain: heroes | Feature: hero_weapon
# Local simulation rule. Does not provide network synchronization or 3D assets.
const RULE_ID := "hero_weapon"
const DOMAIN := "heroes"
const SALT := 15066

func execute(state: Dictionary, payload: Dictionary) -> Dictionary:
    var hero_id := str(payload.get("hero_id", ""))
    if hero_id.is_empty():
        return {"ok": false, "error": "missing_hero_id"}
    var group: Dictionary = state.get(RULE_ID, {})
    group[hero_id] = payload.duplicate(true)
    state[RULE_ID] = group
    return {"ok": true, "hero_id": hero_id}
