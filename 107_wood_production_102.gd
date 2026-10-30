extends RefCounted

# Rise of Conquest | Build 102 | Rule 107/200
# Domain: economy | Feature: wood_production
# Local simulation rule. Does not provide network synchronization or 3D assets.
const RULE_ID := "wood_production"
const DOMAIN := "economy"
const SALT := 10824

func execute(state: Dictionary, payload: Dictionary) -> Dictionary:
    var base := maxf(0.0, float(payload.get("base", 0.0)))
    var level := maxi(1, int(payload.get("level", 1)))
    var rate := clampf(float(payload.get("rate", 0.05)), 0.0, 5.0)
    return {"ok": true, "value": base * (1.0 + float(level - 1) * rate), "rule": RULE_ID}
