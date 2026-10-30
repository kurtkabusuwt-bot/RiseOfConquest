
# Rise of Conquest - Build 89.1

## Tactical Battle AI

Build 89.1 introduces a battle-local tactical AI system
for the existing real-time combat engine.

## Files

- `war_ai_89.gd` - Tactical AI module
- `war_combat_40.gd` - Combat integration
- `war_conquest_31.gd` - Battle loop integration
- `tests/test_build_89.gd` - Tactical AI tests
- `.github/workflows/godot-tests.yml` - CI tests

## Tactical Features

### Target Selection
- Tactical target evaluation
- Target locking to reduce frequent target switching
- Target selection based on battlefield conditions

### Infantry
- Defensive positioning
- Protection of allied units

### Archers
- Ranged positioning
- Retreat behavior when enemies approach

### Cavalry
- Flanking movement
- Charge approach behavior

### Assassins
- Flanking and target approach tactics

### Movement
- Unit separation
- Battlefield boundary handling
- Recovery from blocked or stuck movement

### Performance
- Spatial grid for nearby-unit evaluation
- Decision interval to limit repeated calculations
- Battle-local tactical state

## Compatibility

The tactical AI is designed to preserve the existing
combat system's damage, HP, cooldown and hero abilities.

Damage and combat resolution remain the responsibility
of the combat engine.

## Integration

The battle controller calls `combat.prepare_frame()`
before updating units.

The combat engine uses `TacticalAI` for target selection
and movement.

Each unit's starting position is registered through
`combat.ai.set_home()`.

## Testing

The project includes Build 88 and Build 89 test scripts.

Run Build 89 tests:

```bash
godot --headless --path . --script tests/test_build_89.gd
```

GitHub Actions is configured to run gameplay tests.

## Verification Status

- Source files integrated into the feature branch
- Godot execution results pending verification
- Android APK testing pending
- Merge into main pending successful validation
