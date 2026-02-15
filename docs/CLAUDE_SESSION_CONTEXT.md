# Cassette Beasts Accessibility Mod - Claude Session Context

**Created:** 2026-02-14
**Purpose:** Provides context for continuing development in new Claude sessions

---

## PROJECT OVERVIEW

This is an accessibility mod for **Cassette Beasts** (a monster-catching RPG) that adds TTS (text-to-speech) support for blind/visually impaired players. The mod works by modifying the game's PCK file directly (not Steam Workshop, which doesn't support autoload singletons).

### Game Info
- **Game:** Cassette Beasts
- **Engine:** Godot 3.5.1
- **Platform:** Windows (Steam)

---

## DIRECTORY STRUCTURE

| Path | Purpose |
|------|---------|
| `C:\Program Files (x86)\Steam\steamapps\common\Cassette Beasts\` | Game installation directory |
| `C:\CassetteBeasts-Decompiled\` | Decompiled game source (full game files, editable) |
| `C:\CassetteBeasts-AccessibilityMod\` | Git repo for the mod |
| `C:\CassetteBeasts-AccessibilityMod\source\` | Modified source files for the mod |
| `C:\CassetteBeasts-AccessibilityMod\addons\godot-tts\` | TTS addon (godot-tts GDNative) |
| `C:\CassetteBeasts-AccessibilityMod\docs\` | Documentation |
| `C:\BR-Accessibility-Mod\tools\pckexplorer\` | GodotPCKExplorer tool for repacking |

### GitHub Repository
- **URL:** https://github.com/[user]/CassetteBeasts-AccessibilityMod (user's repo)
- The repo contains the mod source files, not the full decompiled game

---

## TTS SYSTEM

### Engine
- **Primary:** godot-tts GDNative addon for native screen reader integration
- **Supports:** NVDA, JAWS, SAPI, System Access, Window-Eyes
- **Fallback:** PowerShell SAPI if godot-tts fails

### Required DLLs (must be in game directory, NOT in PCK)
- `godot_tts.dll`
- `nvdaControllerClient64.dll`
- `SAAPI64.dll`

### Core File
- `C:\CassetteBeasts-Decompiled\global\Accessibility.gd` - Main TTS singleton
- Registered as autoload in `project.godot`

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

## FILES WITH TTS (as of 2026-02-14)

### Core System
- `global/Accessibility.gd` - Main TTS singleton with all helper functions
- `project.godot` - Has Accessibility autoload

### Battle UI
- `battle/ui/StatusEffectIconNode.gd` - Status effects
- `battle/ui/cassette_player/CassetteButton.gd` - 3D cassette buttons
- `battle/ui/cassette_player/CassettePlayer3D.gd` - Main battle menu
- `battle/ui/MoveButton.gd` - Move buttons
- `battle/ui/TargetButton.gd` - Target buttons
- `battle/ui/FightOrderSubmenu.gd` - Fight menu with move details
- `battle/ui/TargetOrderSubmenu.gd` - Target selection
- `battle/ui/FusionLabelBanner.gd` - Fusion announcements
- `battle/ui/TurnTitleBanner.gd` - Turn action announcements
- `battle/ui/VictorySplash.gd` - Victory announcement

### Menus
- `menus/BaseMenu.gd` - Menu name announcements
- `menus/party/TapeButton.gd` - Tape info
- `menus/party/PartyMemberButton.gd` - Character/tape info
- `menus/party/PartyActionButtons.gd` - Party actions
- `menus/inventory/ItemButton.gd` - Item info
- `menus/inventory/InventoryTab.gd` - Tab switching
- `menus/bestiary/BestiaryListButton.gd` - Species info
- `menus/bestiary/BestiaryListButtonFusion.gd` - Fusion info
- `menus/loot/LootMenu.gd` - Items obtained
- `menus/gain_exp/GainExpMenu.gd` - EXP/level up
- `menus/type_chart/TypeChart.gd` - Type reactions
- `menus/noticeboard/NoticeboardQuestButton.gd` - Quest info
- `menus/ranger_stamp_card/StampSlot.gd` - Ranger captain info
- `menus/sticker_fusion/StickerFusionAttributeButton.gd` - Attribute info
- `menus/camping/CampingMenu.gd` - Camping options
- `menus/stat_adjust/StatSlider.gd` - Stat adjustment
- `menus/net_multiplayer/NetPlayerButton.gd` - Online player info
- `menus/gauntlet/GauntletDifficultyMenu.gd` - Difficulty options
- `menus/raid/RaidInfoPanel.gd` - Raid boss info
- `menus/spooky_dialog/SpookyDialog.gd` - Spooky text
- `menus/illustration/Illustration.gd` - Illustrations
- `menus/give_tape/GiveTapeMenu.gd` - Cassette obtained
- `menus/text_input/TextInputMenu.gd` - Naming screens

### Dialogs
- `nodes/message_dialog/MessageDialog.gd` - Dialogue with speaker
- `nodes/message_dialog/MenuDialog.gd` - Dialogue options

### Banners/Notifications
- `menus/boss_title/TitleBanner.gd` - Boss titles
- `menus/new_quest/NewQuestBanner.gd` - New quest
- `menus/quest_complete/QuestCompleteBanner.gd` - Quest complete
- `menus/new_ability/NewAbilityBanner.gd` - New ability
- `menus/new_partner/NewPartnerBanner.gd` - New partner
- `menus/relationship_up/RelationshipUpBanner.gd` - Relationship up

---

## HOW TO ADD TTS TO A FILE

### Pattern 1: Focus-based (buttons, list items)
```gdscript
func _ready():
    # ... existing code ...
    connect("focus_entered", self, "_on_focus_entered_accessibility")

func _on_focus_entered_accessibility():
    if not Accessibility:
        return
    var announcement = "Button text or item info"
    Accessibility.speak(announcement, true)
```

### Pattern 2: Event-based (banners, popups)
```gdscript
func show_banner(text: String):
    # ... existing show code ...

    # Accessibility: Announce banner
    if Accessibility:
        Accessibility.speak(text, true)
```

### Pattern 3: Deferred (needs to wait for visibility)
```gdscript
func _ready():
    call_deferred("_announce_content")

func _announce_content():
    if Accessibility:
        Accessibility.speak("Content here", true)
```

---

## REPACK COMMAND

After making changes to files in `C:\CassetteBeasts-Decompiled\`, run:

```powershell
& "C:/BR-Accessibility-Mod/tools/pckexplorer/GodotPCKExplorer.Console.exe" -p "C:/CassetteBeasts-Decompiled" "C:/Program Files (x86)/Steam/steamapps/common/Cassette Beasts/CassetteBeasts.pck" "1.3.5.1"
```

---

## ACCESSIBILITY.GD KEY FUNCTIONS

```gdscript
# Core speech
speak(text: String, interrupt: bool = true)
speak_queued(text: String)  # Waits for dialogue to finish
stop()

# State tracking
set_dialogue_playing(playing: bool)
clear_speech_queue()

# Specialized announcers
announce_dialogue(speaker: String, text: String)
announce_menu(menu_name: String)
announce_item(item_name, amount, equipped, rarity)
announce_tape_info(tape_name, species_name, types, hp_percent, is_broken, grade)
announce_cassette_obtained(tape_name, species_name)
announce_naming_screen(title, current_name)
announce_list_item(item, index, total, color_index)
```

---

## KNOWN ISSUES / TODO

### Needs Testing
- All new TTS additions need in-game testing
- Screen reader integration (NVDA, JAWS) needs verification

### Not Yet Implemented
- Character creation part/color better announcements
- Map/pause menu map markers
- Some multiplayer menus (trade, battle request)

---

## WORKFLOW FOR NEW SESSION

1. **Read this document** to understand the project
2. **Read `ACCESSIBILITY_MOD_STATUS.md`** for detailed status
3. **Make changes** to files in `C:\CassetteBeasts-Decompiled\`
4. **Copy changed files** to `C:\CassetteBeasts-AccessibilityMod\source\`
5. **Repack** using the command above
6. **Test** by launching the game
7. **Commit** changes to the git repo if needed

---

## USEFUL GLOB PATTERNS

```
C:/CassetteBeasts-Decompiled/menus/**/*.gd     # All menu scripts
C:/CassetteBeasts-Decompiled/battle/ui/*.gd    # Battle UI scripts
C:/CassetteBeasts-Decompiled/global/*.gd       # Global scripts
C:/CassetteBeasts-Decompiled/nodes/**/*.gd     # Node scripts
```

---

## VERSION INFO

- **Current Mod Version:** 0.6.0
- **Last Session:** 2026-02-14
- **Changes Made:** Major TTS expansion - added TTS to 15+ new files including battle UI, menus, notifications
