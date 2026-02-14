# Cassette Beasts Accessibility Mod

## ⚠️ IMPORTANT: EARLY DEVELOPMENT - NOT A RELEASE ⚠️

**This mod is in very early development and should NOT be considered a playable accessibility solution.**

### Before You Buy Cassette Beasts:

- **DO NOT** purchase this game expecting it to be accessible right now
- A **large portion of the game is completely inaccessible** with this mod
- There are **many bugs** and features that don't work
- **Only buy this game if you want to actively help** develop this accessibility mod
- This repository exists for **feedback, contributions, and collaborative development**

If you're a blind/visually impaired player looking for a fully accessible gaming experience, this is **not ready yet**. Check back later or consider contributing to help make it happen.

---

## What is This Project?

This is an attempt to add text-to-speech (TTS) accessibility support to [Cassette Beasts](https://store.steampowered.com/app/1321440/Cassette_Beasts/), an indie monster-collecting RPG built in Godot Engine 3.5.1.

### Why This Approach?

We investigated multiple approaches before settling on direct PCK modification:

#### Option 1: Steam Workshop Mods - REJECTED

The [official Cassette Beasts modding guide](https://wiki.cassettebeasts.com/wiki/Modding:Mod_Developer_Guide) revealed critical limitations:

| Requirement | Workshop Support | Impact |
|-------------|------------------|--------|
| Create autoload singletons | **Explicitly prohibited** | Cannot create centralized Accessibility.gd |
| Override existing scripts | **Unreliable** - scripts loaded before mod won't be replaced | Cannot hook into UI/dialogue systems |
| Modify project.godot | **Not supported** | Cannot register new autoloads |
| Use class_name | **Breaks mods** | Cannot use typed references |

**Conclusion:** The Workshop system is designed for content mods (new monsters, items, maps), NOT engine-level accessibility features.

#### Option 2: Direct PCK Modification - CHOSEN

This is the same approach used successfully in the [Buckshot Roulette Accessibility Mod](https://github.com/Lethal-Lawnmower/BuckshotRoulette-Accessibility-Mod).

**Process:**
1. Extract game PCK using GodotPCKExplorer
2. Decompile GDScript bytecode (.gdc) to source (.gd) using gdre_tools
3. Add Accessibility singleton to project
4. Modify minimal set of core scripts to hook TTS calls
5. Repack PCK
6. Distribute as delta patch or replacement PCK

---

## Technical Background

### The TTS Problem

- **Buckshot Roulette:** Godot 4.1.1 - has native `DisplayServer.tts_speak()`
- **Cassette Beasts:** Godot 3.5.1 - **NO native TTS support**

Godot 3.5 does not include text-to-speech functionality. The `DisplayServer.tts_speak()` method only exists in Godot 4.0+.

### The Solution: godot-tts GDNative Addon

We use the [godot-tts](https://github.com/lightsoutgames/godot-tts) GDNative addon which provides:

- **Direct screen reader integration** via Tolk (NVDA Controller Client, SAPI)
- **No process spawning** - native DLL calls, no PowerShell overhead
- **Proper interrupt support** - `stop()` immediately silences speech
- **Cross-platform** - Windows, Linux, macOS support
- **Screen reader detection** - knows if NVDA/JAWS is running

**Supported Screen Readers:**
- NVDA (via nvdaControllerClient64.dll)
- JAWS
- System Access
- Window-Eyes
- SAPI fallback (via SAAPI64.dll)

---

## Architecture Decisions

### Centralized vs Scattered TTS Calls

**Buckshot Roulette Approach (Scattered):**
- 22 scripts modified
- TTS calls placed directly in each script
- Works for small games (20-minute playtime)

**Cassette Beasts Approach (Centralized):**
- 1,371 total scripts in game
- Only ~15 scripts modified (1%)
- All TTS calls go through `Accessibility.gd` singleton
- Hooks placed in base classes where possible

**Why Centralized:**
1. **Maintainability:** Changes to TTS logic only require editing one file
2. **Scalability:** Cassette Beasts is 30+ hours, not 20 minutes
3. **Consistency:** All speech goes through same wrapper
4. **Future-proofing:** Easy to swap TTS backend

---

## How the Game Works (Technical)

### Game Structure

Cassette Beasts uses Godot's scene/node architecture:

- **Menus** extend `BaseMenu.gd` - we hook `shown()` for menu announcements
- **Dialogue** uses `MessageDialog.gd` and `MenuDialog.gd`
- **Battle UI** has separate controllers for moves, targets, items
- **Notifications** use `GenericPopUp.gd` through a singleton

### Key Systems We Hook Into

1. **Focus System**: Godot's `focus_entered` signal on Controls
2. **Dialogue System**: `MessageDialog` for NPC speech, `MenuDialog` for choices
3. **Battle System**: `CassettePlayer3D` for main menu, submenus for moves/targets
4. **Notification System**: `GenericPopUp` for toast-style notifications

### Speech Queue System

We implemented a queue system because dialogue options were interrupting character speech:

```gdscript
var _speech_queue: Array = []
var _is_dialogue_playing: bool = false

func speak_queued(text: String) -> void:
    _speech_queue.push_back(text)

func set_dialogue_playing(playing: bool) -> void:
    _is_dialogue_playing = playing
```

The queue processes automatically when `_is_dialogue_playing` becomes `false`.

---

## Current Status

### What Works (Partially)

- [x] Menu opening announcements
- [x] Dialogue text with speaker names
- [x] Dialogue options (queued after speech finishes)
- [x] Some battle menu buttons (Fight, Forms, Items, Flee, Fuse)
- [x] Cassette obtained announcements
- [x] Naming screen announcements
- [x] Item button focus (inventory)
- [x] Tape/cassette button focus (party menu)
- [x] Loot screen item list
- [x] Experience/level up announcements
- [x] Notification popups
- [x] Beast info screen (PartyTapeUI)

### What's Broken or Not Working

- [ ] **Battle moves not being read** - Code exists but signals not firing
- [ ] **Color names incorrect** - Palette mapping is wrong
- [ ] **F5 battle state** - Just says "Battle check", needs real implementation
- [ ] **Many menus not covered** - Bestiary, settings, map, etc.
- [ ] **Overworld navigation** - No audio cues for movement
- [ ] **Combat flow** - Turn order, damage numbers, status effects
- [ ] **Quest system** - No announcements for quest updates
- [ ] **Recording/capture** - Partial, needs completion
- [ ] **Fusion system** - Not announced
- [ ] **And much more...**

---

## Installation (For Testers/Developers)

### Prerequisites

- Cassette Beasts (Steam version)
- [GodotPCKExplorer](https://github.com/DmitriySalnikov/GodotPCKExplorer) (for packing)
- [GDRE Tools](https://github.com/bruvzg/gdsdecomp) (for decompiling, if needed)

### Setup Steps

1. **Backup your original game files**
   ```
   Copy CassetteBeasts.pck to CassetteBeasts.pck.backup
   ```

2. **Decompile the game** (if you need fresh source):
   ```powershell
   gdre_tools.exe --recover="CassetteBeasts.pck" --output-dir="C:\CassetteBeasts-Decompiled"
   ```

3. **Copy modified source files** from this repo's `source/` folder to your decompiled game, maintaining folder structure

4. **Copy the godot-tts addon** to `addons/godot-tts/`

5. **Add Accessibility autoload** to `project.godot`:
   ```ini
   [autoload]
   Accessibility="*res://global/Accessibility.gd"
   ```

6. **Copy DLLs to game folder** (alongside CassetteBeasts.exe):
   - `godot_tts.dll`
   - `nvdaControllerClient64.dll`
   - `SAAPI64.dll`

7. **Repack the PCK**:
   ```powershell
   GodotPCKExplorer.Console.exe -p "C:\CassetteBeasts-Decompiled" "C:\...\Cassette Beasts\CassetteBeasts.pck" "1.3.5.1"
   ```

### Hotkeys

- **F1** - Help (lists hotkeys)
- **F2** - Repeat last spoken text
- **F3** - Announce current focus
- **F4** - Toggle accessibility on/off
- **F5** - Announce battle state (placeholder)

---

## Contributing

### How You Can Help

1. **Testing**: Play the game and report what doesn't work
2. **Code**: Fix bugs or add TTS to uncovered areas
3. **Documentation**: Improve this README or write guides
4. **Palette Analysis**: Help figure out correct color mappings

### Reporting Issues

When reporting bugs, please include:
- What you were trying to do
- What was announced (or not announced)
- The menu/screen you were on
- Any console output (run with `--verbose` flag)

### Code Style

When adding TTS to a new area:

1. Check if `Accessibility` singleton exists: `if Accessibility:`
2. Use appropriate announce function or `speak()` directly
3. Use `call_deferred()` if the UI isn't ready yet
4. Don't interrupt important speech - use `speak(text, false)` for non-interrupting

---

## File Structure

```
CassetteBeasts-AccessibilityMod/
├── README.md                    # This file
├── source/                      # Modified GDScript files
│   ├── global/
│   │   ├── Accessibility.gd     # Main TTS singleton (NEW)
│   │   └── notifications/
│   │       └── GenericPopUp.gd  # Notification TTS
│   ├── menus/
│   │   ├── BaseMenu.gd          # Menu opening announcements
│   │   ├── give_tape/
│   │   ├── text_input/
│   │   ├── inventory/
│   │   ├── party/
│   │   ├── party_tape/
│   │   ├── loot/
│   │   └── gain_exp/
│   ├── nodes/
│   │   └── message_dialog/
│   │       ├── MessageDialog.gd # Dialogue TTS
│   │       └── MenuDialog.gd    # Dialogue options TTS
│   └── battle/
│       └── ui/
│           ├── MoveButton.gd
│           ├── TargetButton.gd
│           ├── FightOrderSubmenu.gd
│           └── cassette_player/
│               └── CassettePlayer3D.gd
├── addons/
│   └── godot-tts/               # TTS GDNative addon
│       ├── TTS.gd
│       ├── godot_tts.dll
│       ├── nvdaControllerClient64.dll
│       └── SAAPI64.dll
└── docs/
    └── ACCESSIBILITY_MOD_STATUS.md  # Detailed status/API reference
```

---

## Credits

- **Mod Development**: Lethal-Lawnmower
- **TTS Addon**: [godot-tts by lightsoutgames](https://github.com/lightsoutgames/godot-tts)
- **Inspiration**: [Buckshot Roulette Accessibility Mod](https://github.com/Lethal-Lawnmower/BuckshotRoulette-Accessibility-Mod)
- **Game**: [Cassette Beasts by Bytten Studio](https://www.cassettebeasts.com/)

---

## License

This accessibility mod is provided for accessibility purposes. The modified scripts are derivatives of Bytten Studio's original code.

The godot-tts addon is licensed under MIT - see `addons/godot-tts/LICENSE`.

---

## Contact

- GitHub Issues: [Open an issue](../../issues)
- For Cassette Beasts game support, contact [Bytten Studio](https://www.cassettebeasts.com/)

---

**Remember: This is NOT ready for general use. Only engage with this project if you want to help develop it.**
