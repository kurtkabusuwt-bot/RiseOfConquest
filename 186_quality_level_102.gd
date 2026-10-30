extends RefCounted

# Rise of Conquest | Build 102 | Rule 186/200
# Domain: mobile | Feature: quality_level
# Local simulation rule. Does not provide network synchronization or 3D assets.
const RULE_ID := "quality_level"
const DOMAIN := "mobile"
const SALT := 18803

func execute(state: Dictionary, payload: Dictionary) -> Dictionary:
    var setting := str(payload.get("setting", RULE_ID))
    var value: Variant = payload.get("value", true)
    var group: Dictionary = state.get("mobile_settings", {})
    group[setting] = value
    state["mobile_settings"] = group
    return {"ok": true, "setting": setting, "value": value}
