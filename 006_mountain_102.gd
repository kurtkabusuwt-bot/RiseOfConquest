extends RefCounted

# Rise of Conquest | Build 102 | Rule 006/200
# Domain: world | Feature: mountain
# Local simulation rule. Does not provide network synchronization or 3D assets.
const RULE_ID := "mountain"
const DOMAIN := "world"
const SALT := 623

func execute(state: Dictionary, payload: Dictionary) -> Dictionary:
    var x := clampi(int(payload.get("x", 600)), 0, 1199)
    var y := clampi(int(payload.get("y", 600)), 0, 1199)
    var seed := int(payload.get("seed", 100100))
    var hash_value := absi((x * 73856093) ^ (y * 19349663) ^ (seed * 83492791) ^ SALT)
    var density := clampf(float(payload.get("density", 0.35)), 0.0, 1.0)
    return {"ok": true, "x": x, "y": y, "present": float(hash_value % 10000) / 10000.0 < density, "variant": hash_value % 5}
