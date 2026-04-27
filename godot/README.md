# Linecraft 2 — Godot 4 port

L2-style 3D top-down RPG. Procedural models for 6 races + 8 classes, click-to-move,
auto-attack with GCD, mobs with simple AI, HP/MP/XP progression. Targets Web (PWA),
Android (APK) and iOS (Xcode project) via Godot's native exporters.

## Run / edit locally

1. Install Godot 4.4 (https://godotengine.org/download).
2. Open `project.godot` in the Godot editor.
3. Press F5 (it will ask to set a main scene — pick `scenes/Boot.tscn`).

## Headless export (CLI)

```bash
# Web (PWA): produces godot/exports/web/index.html + service worker
~/godot/godot4 --headless --path godot --export-release "Web" exports/web/index.html

# Android (debug APK, requires Android SDK + debug keystore configured in editor settings)
~/godot/godot4 --headless --path godot --export-debug "Android" exports/android/linecraft2.apk

# iOS (Xcode project — open in Xcode, set team, build .ipa)
~/godot/godot4 --headless --path godot --export-release "iOS" exports/ios/linecraft2.xcodeproj
```

## Controls

| Action | Keyboard / Mouse | Touch |
| --- | --- | --- |
| Move to point | Left-click on ground | Tap on ground |
| Target monster | Left-click on monster | Tap on monster |
| Power Strike | `2` | Action bar button |
| Heal | `3` | Action bar button |
| Sit / regen | `R` | Action bar button |
| Deselect | `Esc` | — |
| Camera rotate | RMB drag | One-finger drag |
| Camera zoom | Mouse wheel | Pinch |

## Project layout

```
godot/
├── project.godot      # Godot config, autoloads, input map, rendering
├── export_presets.cfg # Web / Android / iOS presets
├── scripts/           # All GDScript
│   ├── Data.gd        # Races, classes, monster kinds (autoload-friendly statics)
│   ├── Selection.gd   # Autoload — chosen race/class persists across scenes
│   ├── Boot.gd        # Race + class selection screen
│   ├── Character.gd   # Procedural humanoid (BoxMesh / CylinderMesh / SphereMesh)
│   ├── FollowCamera.gd# Top-down RPG camera (RMB rotate, wheel zoom, pinch on touch)
│   ├── World.gd       # Outdoor scene generator (ground, trees, rocks, sky)
│   ├── Monster.gd     # Mob with simple AI (idle / aggro / chase / attack / die)
│   ├── Player.gd      # Player controller (HP/MP/XP, click-to-move, auto-attack, skills)
│   ├── HUD.gd         # CanvasLayer UI (bars, target frame, action bar, toast)
│   └── GameWorld.gd   # Top-level scene: spawns world/player/camera/monsters, raycast click
├── scenes/
│   ├── Boot.tscn      # Selection screen
│   ├── GameWorld.tscn # Main game
│   └── HUD.tscn       # UI layout
└── assets/
    └── icon.png       # App icon (PWA + APK + iOS)
```

## CI / CD

GitHub Actions (in `/.github/workflows/`):
- `godot-web.yml` — builds the Web export and deploys to GitHub Pages.
- `godot-android.yml` — builds a debug APK and uploads it to the `latest` release.
- `godot-ios.yml` — builds the Xcode project on a macOS runner and attaches the zipped `.xcodeproj` to the `latest` release. **Building a real `.ipa` requires an Apple Developer account** and signing certs; this workflow only generates the Xcode project so you can open it locally.
