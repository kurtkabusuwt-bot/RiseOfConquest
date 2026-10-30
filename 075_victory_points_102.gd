extends RefCounted

# Rise of Conquest | Build 102 | Rule 075/200
# Domain: war | Feature: victory_points
# Local simulation rule. Does not provide network synchronization or 3D assets.
const RULE_ID := "victory_points"
const DOMAIN := "war"
const SALT := 7592

func execute(state: Dictionary, payload: Dictionary) -> Dictionary:
    var strength := maxf(0.0, float(payload.get("strength", 100.0)))
    var level := maxi(1, int(payload.get("level", 1)))
    var defense := maxf(0.0, float(payload.get("defense", 0.0)))
    var bonus := clampf(float(payload.get("bonus", 0.0)), -0.8, 3.0)
    var result := maxf(0.0, strength * (1.0 + 0.04 * float(level - 1)) * (1.0 + bonus) - defense)
    return {"ok": true, "value": result, "rule": RULE_ID}
