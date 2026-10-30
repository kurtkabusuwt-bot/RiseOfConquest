extends Node
# Bridge to existing scene without changing original scripts.
var registry: Node

func _ready() -> void:
    registry = Node.new()
    registry.name = "RuleRegistry102"
    registry.set_script(load("res://build102/build102_rule_registry.gd"))
    add_child(registry)
    print("Build 102 registry loaded: ", registry.get_rule_count(), " rules")

func run_rule(rule_id: String, payload: Dictionary = {}) -> Dictionary:
    if registry == null:
        return {"ok": false, "error": "registry_not_ready"}
    return registry.execute(rule_id, payload)
