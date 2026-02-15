# Cassette Beasts Accessibility Mod

## IMPORTANT: EXTREMELY EARLY TESTING

**This mod is in EXTREMELY EARLY TESTING and should NOT be considered a playable accessibility solution.**

### Before You Buy Cassette Beasts:

- **DO NOT** purchase this game expecting it to be accessible right now
- A **large portion of the game is completely inaccessible** with this mod
- There are **many bugs** and features that don't work
- **Only buy this game if you want to actively help** develop this accessibility mod
- This repository exists for **feedback, contributions, and collaborative development**

The mod may be **slightly more friendly to low vision users** now, but **many menus and features are still missing accessibility support**.

If you're a blind/visually impaired player looking for a fully accessible gaming experience, this is **not ready yet**. Check back later or consider contributing to help make it happen.

---

## What is This Project?

This is an attempt to add text-to-speech (TTS) accessibility support to [Cassette Beasts](https://store.steampowered.com/app/1321440/Cassette_Beasts/), an indie monster-collecting RPG built in Godot Engine 3.5.1.

### Why This Approach?

We use direct PCK modification (same approach as the [Buckshot Roulette Accessibility Mod](https://github.com/Lethal-Lawnmower/BuckshotRoulette-Accessibility-Mod)) because the Steam Workshop system is designed for content mods, not engine-level accessibility features.

---

## Hotkeys

| Key | Function |
|-----|----------|
| **H** | Player health (monster name + HP percentage) |
| **Shift+H** | Enemy health (monster name + HP percentage) |
| **T** | Time of day (Day #, hour, minute, day/night) |
| **G** | Gold/money amount |
| **J** | Player AP in battle (monster name + current/max AP) |
| **B** | Bestiary details (when in bestiary menu - reads species, types, bio, stats) |
| **F4** | Toggle accessibility on/off |
| **F5** | Repeat last spoken text |

---

## Current Status

### What Works (Tested)

- [x] Menu opening announcements
- [x] Dialogue text with speaker names
- [x] Dialogue options (queued after speech finishes)
- [x] Battle menu buttons (Fight, Forms, Items, Flee, Fuse)
- [x] **Move selection in battle** (name, AP cost, type, category, power, accuracy, hits, description)
- [x] Naming screen announcements
- [x] Item button focus (inventory)
- [x] Loot screen item list
- [x] Experience/level up announcements
- [x] Notification popups
- [x] H - Player health hotkey
- [x] Shift+H - Enemy health hotkey
- [x] T - Time of day hotkey
- [x] G - Gold/money hotkey
- [x] J - Player AP hotkey (in battle)

### Added But UNTESTED (Should Work)

The following features have been implemented but **have not been fully tested yet**:

- [ ] **Bestiary menu list navigation** - announces species code, name, and status (seen/recorded) when navigating
- [ ] **B hotkey** - reads full bestiary entry details (types, bio text, encounter/record/defeat stats)
- [ ] **Tape/Forms menu navigation** - announces tape name, species, types, HP%, broken status, grade when focused
- [ ] **Beast info screen** (PartyTapeUI)

### What's Still Broken or Incomplete

- [ ] Target selection after choosing move
- [ ] Item selection in battle inventory
- [ ] Color names in character creation
- [ ] Settings menu
- [ ] Map/overworld navigation
- [ ] Combat flow (turn order, damage numbers, status effects)
- [ ] Quest system updates
- [ ] Recording/capture flow announcements
- [ ] Fusion system announcements
- [ ] **And many other menus/screens...**

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

---

## Technical Background

### The TTS Problem

- **Buckshot Roulette:** Godot 4.1.1 - has native `DisplayServer.tts_speak()`
- **Cassette Beasts:** Godot 3.5.1 - **NO native TTS support**

### The Solution: godot-tts GDNative Addon

We use the [godot-tts](https://github.com/lightsoutgames/godot-tts) GDNative addon which provides:

- **Direct screen reader integration** via Tolk (NVDA Controller Client, SAPI)
- **No process spawning** - native DLL calls
- **Proper interrupt support** - `stop()` immediately silences speech

**Supported Screen Readers:**
- NVDA (via nvdaControllerClient64.dll)
- JAWS
- System Access
- SAPI fallback (via SAAPI64.dll)

---

## File Structure

```
CassetteBeasts-AccessibilityMod/
├── README.md                    # This file
├── source/                      # Modified GDScript files
│   ├── global/
│   │   ├── Accessibility.gd     # Main TTS singleton
│   │   └── notifications/
│   │       └── GenericPopUp.gd  # Notification TTS
│   ├── menus/
│   │   ├── BaseMenu.gd          # Menu opening announcements
│   │   ├── bestiary/            # NEW - Bestiary TTS
│   │   │   ├── BestiaryListButton.gd
│   │   │   └── BestiaryListButtonFusion.gd
│   │   ├── give_tape/
│   │   ├── text_input/
│   │   ├── inventory/
│   │   ├── party/
│   │   │   └── TapeButton.gd    # Tape/forms menu TTS
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
    └── ACCESSIBILITY_MOD_STATUS.md
```

---

## Contributing

### How You Can Help

1. **Testing**: Play the game and report what doesn't work
2. **Code**: Fix bugs or add TTS to uncovered areas
3. **Documentation**: Improve this README or write guides

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
