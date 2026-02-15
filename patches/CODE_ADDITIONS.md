# Code Additions for Accessibility

This document shows the exact code to ADD to each game file.
Do not replace files - only add these code blocks.

---

## battle/ui/BattleToast_Default.gd

### In `setup_damage()` function, at the end add:
```gdscript
	# Accessibility: Announce damage
	if Accessibility:
		var announcement = str(damage.damage) + " damage"
		if damage.is_critical:
			announcement = "Critical hit! " + announcement
		Accessibility.speak(announcement, false)
```

### In `setup_text()` function, at the end add:
```gdscript
	# Accessibility: Announce text message (e.g. recording failed, missed, etc.)
	if Accessibility:
		Accessibility.speak(Loc.tr(text), false)
```

### In `setup_heal()` function, at the end add:
```gdscript
	# Accessibility: Announce healing
	if Accessibility:
		Accessibility.speak("Healed " + str(amount), false)
```

### In `setup_ap_delta()` function, at the end add:
```gdscript
	# Accessibility: Announce AP change
	if Accessibility:
		var change = "gained" if ap > 0 else "lost"
		Accessibility.speak(change + " " + str(abs(ap)) + " A P", false)
```

### In `setup_status_effect_added()` function, at the end add:
```gdscript
	# Accessibility: Announce status effect
	if Accessibility:
		var status_type = "buff" if status_effect.is_buff else ("debuff" if status_effect.is_debuff else "status")
		Accessibility.speak(message + ", " + status_type, false)
```

---

## battle/ui/BattleToast_RecordingChance.gd

### Add variable at top of file:
```gdscript
var _announced: bool = false
```

### In `_ready()` function, after `tween.start()` add:
```gdscript
	tween.connect("tween_all_completed", self, "_on_tween_completed")
```

### Add new function:
```gdscript
func _on_tween_completed():
	# Accessibility: Announce final recording chance
	if Accessibility:
		var perceptual_chance = BattleFormulas.get_perceptual_chance(current_chance)
		var percent = int(round(perceptual_chance * 100.0))
		Accessibility.speak("Recording chance: " + str(percent) + " percent", true)
```

---

## battle/ui/cassette_player/FusionMeter.gd

### Add variable at top after existing vars:
```gdscript
var _was_full: bool = false  # Track if fusion meter was already full
```

### In `update()` function, replace the `_set_glow()` call with:
```gdscript
	var is_full = fusion_meter.is_full()
	_set_glow(is_full)

	# Accessibility: Announce when fusion meter becomes full
	if is_full and not _was_full:
		if Accessibility:
			Accessibility.speak("Fusion ready!", true)
	_was_full = is_full
```

---

## battle/ui/TurnTitleBanner.gd

### In `show_banner()` function, at the end add:
```gdscript
	# Accessibility: Announce turn action
	if Accessibility:
		Accessibility.speak(fighter + " uses " + Loc.tr(title), true)
```

### In `fail_banner()` function, after setting up the label add:
```gdscript
	# Accessibility: Announce failure
	if Accessibility:
		Accessibility.speak(Loc.tr(message), true)
```

---

## menus/BaseMenu.gd

### In `_ready()` or `show()` function, add:
```gdscript
	# Accessibility: Announce menu name
	if Accessibility:
		Accessibility.announce_menu(menu_name)
```

---

## menus/party/TapeButton.gd

### In `_ready()` function, add:
```gdscript
	# Accessibility: Connect focus signal for TTS announcements
	connect("focus_entered", self, "_on_focus_entered_accessibility")
```

### Add new function:
```gdscript
func _on_focus_entered_accessibility():
	if not Accessibility:
		return

	if tape == null:
		Accessibility.speak("Empty slot", true)
		return

	var tape_name = tape.get_name() if tape.has_method("get_name") else "Unknown"
	var species_name = ""
	var type_names = []
	var hp_percent = 100.0
	var is_broken = false
	var is_bootleg = false
	var grade_value = 0

	# Get form info
	if form:
		species_name = Loc.tr(form.name) if "name" in form else ""
		if "elemental_types" in form:
			for etype in form.elemental_types:
				if etype and "name" in etype:
					type_names.append(Loc.tr(etype.name))

	if species_name == "":
		species_name = tape_name

	if tape.has_method("hp") or "hp" in tape:
		hp_percent = tape.hp.to_float() * 100.0 if tape.hp else 100.0

	if tape.has_method("is_broken"):
		is_broken = tape.is_broken()

	if tape.has_method("is_bootleg"):
		is_bootleg = tape.is_bootleg()

	if "grade" in tape:
		grade_value = tape.grade

	# Build announcement
	var announcement = tape_name
	if tape_name != species_name:
		announcement += ", " + species_name

	if is_bootleg:
		announcement += ", bootleg"

	if type_names.size() > 0:
		announcement += ", "
		for i in range(type_names.size()):
			if i > 0:
				announcement += " and "
			announcement += type_names[i]
		announcement += " type"

	if is_broken:
		announcement += ", broken"
	elif hp_percent < 100:
		announcement += ", " + str(int(hp_percent)) + " percent HP"

	if grade_value > 0:
		announcement += ", grade " + str(grade_value)

	Accessibility.speak(announcement, true)
```

---

## menus/party/PartyMemberButton.gd

### In `_ready()` function, add:
```gdscript
	# Accessibility: Connect focus signal for TTS announcements
	connect("focus_entered", self, "_on_focus_entered_accessibility")
```

### Add new function:
```gdscript
func _on_focus_entered_accessibility():
	if not Accessibility:
		return

	var announcement = ""

	if character:
		var char_name = character.name if not hide_char_name else "Unknown"
		announcement = char_name + ", level " + str(character.level)

		if hp_bar and hp_bar.character:
			var max_hp = hp_bar.max_value
			var current_hp = hp_bar.value
			var hp_percent = int((float(current_hp) / float(max_hp)) * 100) if max_hp > 0 else 0
			announcement += ", " + str(hp_percent) + " percent health"

		# Add relationship info for partner characters
		if character.relationship_level > 0:
			announcement += ", relationship level " + str(character.relationship_level)
			if SaveState.party.is_ready_for_relationship_level_up(character):
				announcement += ", ready to level up"

	if tape:
		var tape_name = tape.get_name() if tape.has_method("get_name") else "Unknown tape"
		if announcement != "":
			announcement += ", with tape "
		announcement += tape_name
		if tape.is_broken():
			announcement += ", broken"

	if announcement == "":
		announcement = "Empty slot"

	Accessibility.speak(announcement, true)
```

---

## nodes/message_dialog/MessageDialog.gd

### In the function that displays dialogue text, add:
```gdscript
	# Accessibility: Announce dialogue
	if Accessibility:
		Accessibility.set_dialogue_playing(true)
		Accessibility.announce_dialogue(speaker_name, dialogue_text)
```

### When dialogue finishes/closes, add:
```gdscript
	# Accessibility: Mark dialogue as finished
	if Accessibility:
		Accessibility.set_dialogue_playing(false)
```

---

## nodes/message_dialog/MenuDialog.gd

### When options become visible, add:
```gdscript
	# Accessibility: Queue options announcement
	if Accessibility:
		var option_texts = []
		for option in options:
			option_texts.append(option.text)
		Accessibility.announce_dialogue_options(option_texts)
```

---

## Additional Files

The same pattern applies to all other files. Add:

1. Focus signal connection in `_ready()`:
```gdscript
connect("focus_entered", self, "_on_focus_entered_accessibility")
```

2. Accessibility function:
```gdscript
func _on_focus_entered_accessibility():
	if Accessibility:
		Accessibility.speak("Relevant info here", true)
```

See the full source files in `source/` for complete implementations.
