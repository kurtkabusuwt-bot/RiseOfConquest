extends RefCounted

# Rise of Conquest | Build 102 | Rule 001/200
# Domain: world | Feature: terrain_height
# Local simulation rule. Does not provide network synchronization or 3D assets.
const RULE_ID := "terrain_height"
const DOMAIN := "world"
const SALT := 118

func execute(state: Dictionary, payload: Dictionary) -> Dictionary:
    var base := float(payload.get("base", 1.0))
    var modifier := float(payload.get("modifier", 0.0))
    var multiplier := clampf(float(payload.get("multiplier", 1.0)), 0.0, 100.0)
    return {"ok": true, "value": maxf(0.0, (base + modifier) * multiplier), "rule": RULE_ID}
