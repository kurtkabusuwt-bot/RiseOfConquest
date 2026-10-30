extends RefCounted

# Rise of Conquest | Build 102 | Rule 156/200
# Domain: heroes | Feature: hero_synergy
# Local simulation rule. Does not provide network synchronization or 3D assets.
const RULE_ID := "hero_synergy"
const DOMAIN := "heroes"
const SALT := 15773

func execute(state: Dictionary, payload: Dictionary) -> Dictionary:
    var current := maxf(0.0, float(payload.get("current", 0.0)))
    var earned := maxf(0.0, float(payload.get("earned", 0.0)))
    var cap := maxf(1.0, float(payload.get("cap", 100.0)))
    return {"ok": true, "value": minf(current + earned, cap), "reached_cap": current + earned >= cap}
