# Cassette Beasts Accessibility Mod - Installation Guide

## Overview

This mod adds text-to-speech (TTS) accessibility support for blind and visually
impaired players. It requires modifying game files, which means you need to:

1. Decompile your legally-owned copy of the game
2. Apply our accessibility code additions
3. Recompile and install

**Estimated time: 30-60 minutes for first-time setup**

---

## Prerequisites

### Required Software
- **Cassette Beasts** (Steam version)
- **GDRE Tools** - [Download](https://github.com/bruvzg/gdsdecomp/releases)
- **GodotPCKExplorer** - [Download](https://github.com/DmitriySalnikov/GodotPCKExplorer/releases)

### Required Files (from this mod)
- `Accessibility.gd` - Main TTS singleton
- `addons/godot-tts/` - TTS addon folder
- DLL files: `godot_tts.dll`, `nvdaControllerClient64.dll`, `SAAPI64.dll`

---

## Step 1: Backup Original Game

```
C:\Program Files (x86)\Steam\steamapps\common\Cassette Beasts\
```

Copy `CassetteBeasts.pck` to `CassetteBeasts.pck.backup`

---

## Step 2: Decompile the Game

```powershell
gdre_tools.exe --recover="CassetteBeasts.pck" --output-dir="C:\CassetteBeasts-Decompiled"
```

This extracts all game files to a folder you can edit.

---

## Step 3: Add New Files

### 3a. Copy Accessibility.gd
Copy `Accessibility.gd` to:
```
C:\CassetteBeasts-Decompiled\global\Accessibility.gd
```

### 3b. Copy godot-tts Addon
Copy the entire `addons/godot-tts/` folder to:
```
C:\CassetteBeasts-Decompiled\addons\godot-tts\
```

---

## Step 4: Modify project.godot

Open `C:\CassetteBeasts-Decompiled\project.godot` and find the `[autoload]` section.

Add this line:
```ini
Accessibility="*res://global/Accessibility.gd"
```

---

## Step 5: Apply Code Patches

For each file listed below, add the specified code blocks.
See `CODE_ADDITIONS.md` for the exact code to add to each file.

### Files to Modify (High Priority - Core Features)
- `battle/ui/BattleToast_Default.gd` - Damage/heal/AP announcements
- `battle/ui/BattleToast_RecordingChance.gd` - Recording chance
- `battle/ui/cassette_player/FusionMeter.gd` - Fusion ready
- `battle/ui/FightOrderSubmenu.gd` - Move details
- `battle/ui/TurnTitleBanner.gd` - Turn actions
- `menus/BaseMenu.gd` - Menu names
- `menus/party/TapeButton.gd` - Tape info
- `menus/party/PartyMemberButton.gd` - Character + relationship
- `nodes/message_dialog/MessageDialog.gd` - Dialogue text
- `nodes/message_dialog/MenuDialog.gd` - Dialogue options

### Files to Modify (Additional Features)
See `CODE_ADDITIONS.md` for the complete list.

---

## Step 6: Recompile

```powershell
GodotPCKExplorer.Console.exe -p "C:\CassetteBeasts-Decompiled" "C:\Program Files (x86)\Steam\steamapps\common\Cassette Beasts\CassetteBeasts.pck" "1.3.5.1"
```

---

## Step 7: Install DLLs

Copy these files to the game folder (next to CassetteBeasts.exe):
- `godot_tts.dll`
- `nvdaControllerClient64.dll`
- `SAAPI64.dll`

---

## Step 8: Test

Launch Cassette Beasts through Steam. You should hear:
> "Accessibility mod loaded. H health, shift H enemy, T time, G gold, J A P, F fusion, R relationship, B bestiary."

---

## Troubleshooting

### No speech on startup
- Check DLLs are in game folder
- Check NVDA is running or Windows SAPI is configured

### Game crashes
- Verify project.godot has correct autoload line
- Check for syntax errors in modified files
- Restore from backup: copy .pck.backup to .pck

### Patch doesn't apply
- Make sure you're editing the correct file paths
- Game version might differ - adjust line numbers as needed

---

## Restoring Original Game

Option 1: Copy backup
```
copy CassetteBeasts.pck.backup CassetteBeasts.pck
```

Option 2: Steam verify
- Right-click game → Properties → Local Files → Verify integrity

---

## Support

GitHub Issues: https://github.com/Lethal-Lawnmower/CassetteBeasts-Accessibility-Mod/issues
