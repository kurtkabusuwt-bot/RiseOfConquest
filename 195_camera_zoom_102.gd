extends RefCounted

# Rise of Conquest | Build 102 | Rule 195/200
# Domain: mobile | Feature: camera_zoom
# Local simulation rule. Does not provide network synchronization or 3D assets.
const RULE_ID := "camera_zoom"
const DOMAIN := "mobile"
const SALT := 19712

func execute(state: Dictionary, payload: Dictionary) -> Dictionary:
    var setting := str(payload.get("setting", RULE_ID))
    var value: Variant = payload.get("value", true)
    var group: Dictionary = state.get("mobile_settings", {})
    group[setting] = value
    state["mobile_settings"] = group
    return {"ok": true, "setting": setting, "value": value}
