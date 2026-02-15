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

## HOTKEYS

| Key | Action |
|-----|--------|
| **H** | Announce player health (in battle) |
| **Shift+H** | Announce enemy health (in battle) |
| **T** | Announce time of day |
| **G** | Announce gold/money |
| **J** | Announce player AP (in battle) |
| **B** | Announce bestiary info (when in bestiary) |
| **F4** | Toggle accessibility on/off |
| **F5** | Repeat last spoken text |

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
| `menus/BaseMenu.gd` | DONE | Menu name when opened |
| `nodes/menus/ArrowOptionList.gd` | DONE | Option selection with color support |
| `nodes/message_dialog/MessageDialog.gd` | DONE | Dialogue text with speaker name |
| `nodes/message_dialog/MenuDialog.gd` | DONE | Dialogue options (queued after dialogue finishes) |
| `menus/give_tape/GiveTapeMenu.gd` | DONE | "Cassette obtained: [species name]" |
| `menus/text_input/TextInputMenu.gd` | DONE | Naming screen announcement |
| `menus/inventory/ItemButton.gd` | DONE | Item name, quantity, rarity on focus |
| `menus/inventory/InventoryTab.gd` | DONE | Tab name when switching tabs |
| `menus/party/TapeButton.gd` | DONE | Tape info (name, species, types, HP, grade) |
| `menus/party/PartyMemberButton.gd` | DONE | Character name, level, HP, tape info |
| `menus/party/PartyActionButtons.gd` | DONE | Party menu action buttons |
| `menus/bestiary/BestiaryListButton.gd` | DONE | Species code, name, encounter status |
| `menus/bestiary/BestiaryListButtonFusion.gd` | DONE | Fusion species info |
| `menus/loot/LootMenu.gd` | DONE | Items obtained summary |
| `menus/gain_exp/GainExpMenu.gd` | DONE | EXP gained, level ups, grade ups |
| `menus/type_chart/TypeChart.gd` | DONE | Type reactions (buff/debuff/transmutation) |
| `menus/noticeboard/NoticeboardQuestButton.gd` | DONE | Quest name, description, status |
| `menus/ranger_stamp_card/StampSlot.gd` | DONE | Ranger captain name, defeated status |
| `menus/sticker_fusion/StickerFusionAttributeButton.gd` | DONE | Attribute name, compatibility |
| `menus/camping/CampingMenu.gd` | DONE | Button names, rest cost |
| `menus/stat_adjust/StatSlider.gd` | DONE | Stat name, value, adjustment info |
| `menus/net_multiplayer/NetPlayerButton.gd` | DONE | Player name for online play |
| `menus/gauntlet/GauntletDifficultyMenu.gd` | DONE | Difficulty options |
| `menus/raid/RaidInfoPanel.gd` | DONE | Raid boss name, level, type, subtitle |
| `menus/spooky_dialog/SpookyDialog.gd` | DONE | Spooky dialog text |
| `menus/illustration/Illustration.gd` | DONE | Illustration description |

### Battle UI TTS Hooks
| File | Status | What it announces |
|------|--------|-------------------|
| `battle/ui/cassette_player/CassettePlayer3D.gd` | DONE | Main battle menu buttons (Fight, Forms, Items, Flee, Fuse) |
| `battle/ui/cassette_player/CassetteButton.gd` | DONE | 3D cassette button names |
| `battle/ui/MoveButton.gd` | DONE | Move name, AP cost, type, status |
| `battle/ui/TargetButton.gd` | DONE | Target name, ally/enemy |
| `battle/ui/FightOrderSubmenu.gd` | DONE | Move list with description, AP, type, power |
| `battle/ui/TargetOrderSubmenu.gd` | DONE | Target selection with ally/enemy indicator |
| `battle/ui/StatusEffectIconNode.gd` | DONE | Status effect name, turns remaining, description |
| `battle/ui/FusionLabelBanner.gd` | DONE | Fusion name when fusion occurs |
| `battle/ui/TurnTitleBanner.gd` | DONE | Turn action (move used) and failures |
| `battle/ui/VictorySplash.gd` | DONE | "Victory!" announcement |

### Notification Banners
| File | Status | What it announces |
|------|--------|-------------------|
| `menus/boss_title/TitleBanner.gd` | DONE | Boss title and subtitle |
| `menus/new_quest/NewQuestBanner.gd` | DONE | New quest name |
| `menus/quest_complete/QuestCompleteBanner.gd` | DONE | Quest completed |
| `menus/new_ability/NewAbilityBanner.gd` | DONE | New ability unlocked |
| `menus/new_partner/NewPartnerBanner.gd` | DONE | New partner joined |
| `menus/relationship_up/RelationshipUpBanner.gd` | DONE | Relationship level up |

---

## FEATURES IMPLEMENTED

### Speech Queue System
- Queues speech to play after dialogue finishes
- Prevents dialogue options from cutting off character speech
- Uses `set_dialogue_playing(true/false)` to track state
- Timer-based queue processing

### Color Name System
- `COLOR_NAMES` dictionary for predefined color names
- `get_color_name_from_palette()` - Runtime color detection from palette.png
- `_describe_color()` - HSV-based color description

---

## KNOWN ISSUES / TODO

### Needs Testing
- [ ] Test all new TTS additions in-game
- [ ] Verify bestiary menu TTS works correctly
- [ ] Test battle target selection TTS
- [ ] Test all notification banners

### Needs Implementation
- [ ] **Character Creation** - Color/part options could use better TTS
- [ ] **Map/Pause Menu** - Map marker TTS
- [ ] **More multiplayer menus** - Trade, battle request, etc.

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

## VERSION HISTORY

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-02-13 | Initial implementation - basic TTS framework |
| 0.2.0 | 2026-02-14 | Fixed TTS overlap, color names, dialogue timing, battle menu TTS |
| 0.3.0 | 2026-02-14 | Replaced PowerShell with godot-tts native addon |
| 0.4.0 | 2026-02-14 | Added speech queue system, dialogue options, cassette obtained, naming screen |
| 0.5.0 | 2026-02-14 | Added FightOrderSubmenu TTS, runtime color detection |
| 0.6.0 | 2026-02-14 | **Major expansion:** Changed hotkeys (H/Shift+H/T/G/J/B), added TTS to: StatusEffects, CassetteButton, PartyActionButtons, PartyMemberButton, TypeChart, Noticeboard, StampSlot, StickerFusion, CampingMenu, StatSlider, NetPlayerButton, GauntletDifficulty, RaidInfo, SpookyDialog, Illustration, TargetOrderSubmenu, FusionLabelBanner, TurnTitleBanner |

---

## NEXT STEPS FOR DEVELOPMENT

1. **Repack and test** - Rebuild PCK with all new changes
2. **Character creation** - Improve part/color option announcements
3. **Map navigation** - Add TTS to map markers
4. **Multiplayer menus** - Trade/battle request screens
5. **Test with screen readers** - NVDA, JAWS verification
