# Cassette Beasts Accessibility Mod - Development Status

**Last Updated:** 2026-02-14
**Game Version:** Cassette Beasts 1.6.x (Godot 3.5.1)

---

## PROJECT OVERVIEW

This mod adds text-to-speech (TTS) support to Cassette Beasts for visually impaired players using direct PCK modification (not Steam Workshop, which doesn't support autoload singletons).

### TTS Engine
- **Primary:** godot-tts GDNative addon (v0.8.1) for native screen reader integration
- **Supports:** NVDA, JAWS, SAPI, System Access, Window-Eyes
- **Fallback:** PowerShell SAPI if godot-tts fails to load

### Required DLLs (in game directory alongside exe)
- `godot_tts.dll` - Main GDNative library
- `nvdaControllerClient64.dll` - NVDA integration
- `SAAPI64.dll` - Screen reader abstraction

---

## FILES MODIFIED

### Core Accessibility System
| File | Purpose |
|------|---------|
| `global/Accessibility.gd` | **NEW** - Main TTS singleton with all accessibility functions |
| `project.godot` | Added Accessibility autoload |
| `addons/godot-tts/` | **NEW** - TTS addon folder with DLLs and GDScript |

### UI/Menu TTS Hooks
| File | Status | What it announces |
|------|--------|-------------------|
| `menus/BaseMenu.gd` | ✅ DONE | Menu name when opened |
| `nodes/menus/AutoFocusButton.gd` | ✅ DONE | Button focus |
| `nodes/menus/ArrowOptionList.gd` | ✅ DONE | Option selection with color support |
| `nodes/message_dialog/MessageDialog.gd` | ✅ DONE | Dialogue text with speaker name |
| `nodes/message_dialog/PassiveMessage.gd` | ✅ DONE | Passive/NPC dialogue |
| `nodes/message_dialog/MenuDialog.gd` | ✅ DONE | Dialogue options (queued after dialogue finishes) |
| `menus/give_tape/GiveTapeMenu.gd` | ✅ DONE | "Cassette obtained: [species name]" |
| `menus/text_input/TextInputMenu.gd` | ✅ DONE | Naming screen announcement |
| `menus/inventory/ItemButton.gd` | ✅ DONE | Item name, quantity, rarity on focus |
| `menus/party/TapeButton.gd` | ✅ DONE | Tape info (name, species, types, HP, grade) |
| `global/scene_manager/SceneManager.gd` | ✅ DONE | Area transition announcements |

### Battle UI TTS Hooks
| File | Status | What it announces |
|------|--------|-------------------|
| `battle/ui/cassette_player/CassettePlayer3D.gd` | ✅ DONE | Main battle menu buttons (Fight, Forms, Items, Flee, Fuse) |
| `battle/ui/MoveButton.gd` | ✅ DONE | Move name, AP cost, type, status |
| `battle/ui/TargetButton.gd` | ✅ DONE | Target name, ally/enemy |
| `battle/ui/FightOrderSubmenu.gd` | ✅ DONE | Move list with explicit focus handler |
| `battle/ui/BattleToast_Default.gd` | ✅ DONE | Damage/status announcements |
| `battle/BattleController.gd` | ✅ DONE | Battle action announcements |

---

## FEATURES IMPLEMENTED

### Hotkeys (F-keys)
- **F1** - Help (lists available hotkeys)
- **F2** - Repeat last spoken text
- **F3** - Announce current focus
- **F4** - Toggle accessibility on/off
- **F5** - Announce battle state (placeholder - needs real implementation)

### Speech Queue System
- Queues speech to play after dialogue finishes
- Prevents dialogue options from cutting off character speech
- Uses `set_dialogue_playing(true/false)` to track state
- Timer-based queue processing

### Color Name System
- `COLOR_NAMES` dictionary for predefined color names
- `get_color_name_from_palette()` - Runtime color detection from palette.png
- `_describe_color()` - HSV-based color description
- **STATUS:** Colors may still be incorrect - needs palette verification

---

## KNOWN ISSUES / TODO

### Critical - Not Working
- [ ] **Battle moves not being read** - FightOrderSubmenu has TTS code but it's not firing
  - Possible cause: Accessibility singleton not available when buttons created
  - Needs debugging/alternative approach

- [ ] **Color names incorrect** - User reports colors described wrongly
  - Palette index mapping may be wrong
  - Consider removing color name feature or doing thorough palette analysis

### Needs Implementation
- [ ] **Experience/Level Up Menu** (`menus/gain_exp/GainExpMenu.gd`)
  - Announce EXP gained
  - Announce level ups
  - Announce grade ups for tapes

- [ ] **Loot/Pickup Notifications** (`menus/loot/LootMenu.gd`)
  - Announce items obtained when menu opens
  - Already has ItemButton TTS, may need menu-level announcement

- [ ] **Beast Naming/Info Screen** (`menus/party_tape/PartyTapeUI.gd`)
  - Announce tape info when viewing
  - Announce options (Rename, Stickers, etc.)

- [ ] **Notification Popups** (`global/notifications/GenericPopUp.gd`)
  - Announce popup content when shown

- [ ] **Battle State (F5)** - Currently just says "Battle check"
  - Should announce current HP, AP, status effects, etc.

### Polish/Enhancement
- [ ] Test with actual screen readers (NVDA, JAWS)
- [ ] Add volume/rate controls
- [ ] Consider adding navigation sounds
- [ ] Document all TTS announcements for users

---

## ACCESSIBILITY.GD API REFERENCE

### Core Functions
```gdscript
speak(text: String, interrupt: bool = true)  # Speak text immediately
stop()  # Stop current speech
speak_queued(text: String)  # Add to queue (plays after dialogue)
set_dialogue_playing(playing: bool)  # Track dialogue state
clear_speech_queue()  # Clear pending queued speech
```

### Specialized Announcers
```gdscript
announce_focus(control: Control)  # Announce focused control
announce_dialogue(speaker: String, text: String)  # Dialogue with speaker
announce_menu(menu_name: String)  # Menu opening
announce_list_item(item: String, index: int, total: int, color_index: int = -1)
announce_option_change(field_name: String, value: String)
announce_battle(event: String, args: Dictionary)  # Battle events
announce_cassette_obtained(tape_name: String, species_name: String)
announce_naming_screen(title: String, current_name: String)
announce_item(item_name: String, amount: int, equipped: bool, rarity: String)
announce_tape_info(tape_name, species_name, types, hp_percent, is_broken, grade)
```

### Color Functions
```gdscript
get_color_name_from_palette(ramp_index: int) -> String  # Runtime color lookup
_describe_color(color: Color) -> String  # HSV-based description
```

### State
```gdscript
var enabled: bool  # Toggle all TTS
var speech_rate: float  # 0.1 to 2.0
var debug_logging: bool  # Print TTS to console
```

---

## BUILD/REPACK COMMANDS

### Repack PCK (after code changes)
```powershell
"C:/BR-Accessibility-Mod/tools/pckexplorer/GodotPCKExplorer.Console.exe" -p "C:/CassetteBeasts-Decompiled" "C:/Program Files (x86)/Steam/steamapps/common/Cassette Beasts/CassetteBeasts.pck" "1.3.5.1"
```

### Copy DLLs to game folder (if not already done)
```powershell
Copy-Item "C:\CassetteBeasts-Decompiled\addons\godot-tts\target\release\*.dll" "C:\Program Files (x86)\Steam\steamapps\common\Cassette Beasts\"
```

---

## TROUBLESHOOTING

### TTS Not Working
1. Check if DLLs are in game folder (not just in PCK)
2. Check console for "[Accessibility]" messages
3. Press F4 to toggle, F1 for help

### Screen Reader Not Detected
- godot-tts may fall back to SAPI
- Check if screen reader is running before launching game

### Moves/Buttons Not Announcing
- Likely signal connection issue
- Add debug prints to `_on_focus_entered_accessibility` functions
- Check if `Accessibility` singleton is available (`if Accessibility:`)

---

## VERSION HISTORY

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-02-13 | Initial implementation - basic TTS framework |
| 0.2.0 | 2026-02-14 | Fixed TTS overlap, color names, dialogue timing, battle menu TTS |
| 0.3.0 | 2026-02-14 | Replaced PowerShell with godot-tts native addon |
| 0.4.0 | 2026-02-14 | Added speech queue system, dialogue options, cassette obtained, naming screen, item/tape buttons |
| 0.5.0 | 2026-02-14 | Added FightOrderSubmenu TTS (not working), runtime color detection |

---

## NEXT STEPS FOR DEVELOPMENT

1. **Debug battle moves TTS** - Add logging to find why focus signals aren't working
2. **Add GainExpMenu TTS** - Level up/EXP announcements
3. **Add LootMenu announcement** - Summarize items on open
4. **Add PartyTapeUI TTS** - Beast info screen
5. **Add GenericPopUp TTS** - Notification announcements
6. **Fix colors** - Either remove feature or properly map palette
7. **Test with screen readers** - NVDA, JAWS verification
