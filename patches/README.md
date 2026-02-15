# Cassette Beasts Accessibility Mod - Patch Files

## Legal Notice

This folder contains **only the code additions** made for accessibility support.
These are patches to be applied to your own legally-owned, decompiled copy of
Cassette Beasts.

**You must own Cassette Beasts to use these patches.**

## File Categories

### New Files (Distribute Fully)
- `Accessibility.gd` - Our main TTS singleton (100% our code)
- `addons/godot-tts/` - MIT-licensed TTS addon

### Patch Files (Code Additions Only)
All `.patch` files contain unified diffs showing only the lines we added.
Apply these to your decompiled game files.

## How to Apply Patches

### Prerequisites
1. Own Cassette Beasts on Steam
2. Decompile the game using [GDRE Tools](https://github.com/bruvzg/gdsdecomp)
3. Have `patch` command available (Git Bash on Windows)

### Steps
```bash
# 1. Decompile your game
gdre_tools.exe --recover="CassetteBeasts.pck" --output-dir="./CassetteBeasts-Decompiled"

# 2. Copy Accessibility.gd (new file)
cp Accessibility.gd ./CassetteBeasts-Decompiled/global/

# 3. Copy godot-tts addon
cp -r addons/godot-tts ./CassetteBeasts-Decompiled/addons/

# 4. Apply patches
cd CassetteBeasts-Decompiled
patch -p1 < ../patches/all_changes.patch

# 5. Add autoload to project.godot (see PROJECT_GODOT_CHANGES.md)

# 6. Repack
GodotPCKExplorer.Console.exe -p "." "../CassetteBeasts.pck" "1.3.5.1"

# 7. Copy DLLs to game folder
cp addons/godot-tts/target/release/*.dll "C:/Program Files (x86)/Steam/steamapps/common/Cassette Beasts/"
```

## What the Patches Add

Each patch adds TTS announcements following this pattern:
```gdscript
# Accessibility: Announce [description]
if Accessibility:
    Accessibility.speak("Text to announce", true)
```

The patches do not modify game logic - they only add accessibility hooks.
