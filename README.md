# EOTS Camera
Network-compliant third-person camera and aim assist.

## Third-Person Aim Assist

The package includes a modular `EotsAimAssist` component that can be reused independently from the camera actor.

### What it does

- Off by default.
- Uses configurable shoulder offset to trace from weapon/shoulder space toward camera forward.
- Applies obstacle-safe aim resolution with a trace from shoulder start to avoid shooting into camera-clipped walls.
- Draws laser from shoulder/weapon position to adjusted aim point.
- Smoothly blends pawn/view rotation toward adjusted aim target.
- Keeps behavior network-safe by applying authoritative rotation updates on the server when enabled.
- Does not modify default aiming/input when disabled.

### Settings (saved to config)

Configured in `EotsCameraMut` (`config(EOTSCamera)`):

- `bAimAssistEnabled` (default `False`)
- `AimShoulderOffset` (X/Y/Z)
- `AimLaserHue`, `AimLaserSaturation`, `AimLaserBrightness` (default red-like tint)
- `AimRotationBlendSpeed`
- `AimMaxDistance`
- `AimTracePadding`

### Runtime tools/commands example

Toggle aim assist:

```
mutate eotsaim on
mutate eotsaim off
mutate eotsaim toggle
```

Adjust settings at runtime (owner inventory exec commands):

```
EOTSaimSetOffset 20 18 8
EOTSaimSetLaserColor 0 255 180
EOTSaimEnable true
EOTSaimEnable false
EOTSaimToggle
```

After changing `EotsCameraMut` values through `set` commands, reapply to active players:

```
mutate eotsaim apply
```
