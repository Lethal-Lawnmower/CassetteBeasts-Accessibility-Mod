# Accessibility.gd - Centralized TTS singleton for Cassette Beasts
# Uses godot-tts GDNative addon for proper screen reader integration
# Supports NVDA, JAWS, SAPI, and other screen readers via Tolk
extends Node

signal speech_started(text)
signal speech_finished

# TTS Engine (from godot-tts addon)
var _tts = null

# Settings
var enabled: bool = true
var speech_rate: float = 1.0  # Normalized rate (0.0 to 2.0, 1.0 = normal)
var debug_logging: bool = true

# State
var _last_spoken: String = ""
var _last_focus_text: String = ""
var _last_dialogue_text: String = ""

# Speech queue system - for queuing speech after dialogue finishes
var _speech_queue: Array = []
var _is_dialogue_playing: bool = false
var _queue_timer: Timer = null

# Color name mappings for character creation palette ramp indices
# Based on actual palette.png color ramps in Cassette Beasts
# Each ramp is a gradient of one base color (5 shades each)
const COLOR_NAMES = {
	# Artificial colors (0-17) - clothing, hair, accessories
	0: "Cream",
	1: "Silver",
	2: "Gray",
	3: "Charcoal",
	4: "Black",
	5: "Maroon",
	6: "Red",
	7: "Orange",
	8: "Gold",
	9: "Yellow",
	10: "Lime",
	11: "Green",
	12: "Teal",
	13: "Cyan",
	14: "Blue",
	15: "Purple",
	16: "Magenta",
	17: "Brown",
	# Skin tones (19-23)
	19: "Fair",
	20: "Light",
	21: "Medium",
	22: "Tan",
	23: "Dark"
}

# Runtime color name lookup - reads actual palette colors
func get_color_name_from_palette(ramp_index: int) -> String:
	# First check if we have a predefined name
	if COLOR_NAMES.has(ramp_index):
		return COLOR_NAMES[ramp_index]

	# Fallback: try to describe based on actual palette color
	var palette = load("res://palette.png")
	if palette == null:
		return "Color " + str(ramp_index + 1)

	var pdata = palette.get_data()
	if pdata == null:
		return "Color " + str(ramp_index + 1)

	pdata.lock()
	# Get the middle shade of the ramp (index 2 of 5)
	var pixel_index = ramp_index * 5 + 2
	var x = pixel_index % pdata.get_width()
	var y = pixel_index / pdata.get_width()
	var color = pdata.get_pixel(x, y)
	pdata.unlock()

	# Describe the color based on HSV values
	return _describe_color(color)

func _describe_color(color: Color) -> String:
	var h = color.h * 360  # Hue in degrees
	var s = color.s  # Saturation 0-1
	var v = color.v  # Value/brightness 0-1

	# Check for grayscale first
	if s < 0.15:
		if v > 0.85:
			return "White"
		elif v > 0.65:
			return "Light Gray"
		elif v > 0.4:
			return "Gray"
		elif v > 0.2:
			return "Dark Gray"
		else:
			return "Black"

	# Determine hue name
	var hue_name = ""
	if h < 15 or h >= 345:
		hue_name = "Red"
	elif h < 45:
		hue_name = "Orange"
	elif h < 70:
		hue_name = "Yellow"
	elif h < 150:
		hue_name = "Green"
	elif h < 195:
		hue_name = "Cyan"
	elif h < 260:
		hue_name = "Blue"
	elif h < 290:
		hue_name = "Purple"
	elif h < 345:
		hue_name = "Pink"

	# Add brightness modifier
	if v < 0.35:
		return "Dark " + hue_name
	elif v > 0.8 and s < 0.5:
		return "Light " + hue_name

	return hue_name

func _ready() -> void:
	# Load the TTS addon
	_init_tts()
	# Setup queue timer for processing queued speech
	_setup_queue_timer()
	print("[Accessibility] TTS System initialized")
	call_deferred("_announce_startup")

func _setup_queue_timer() -> void:
	_queue_timer = Timer.new()
	_queue_timer.one_shot = false
	_queue_timer.wait_time = 0.1
	_queue_timer.connect("timeout", self, "_process_speech_queue")
	add_child(_queue_timer)
	_queue_timer.start()

func _init_tts() -> void:
	# Load godot-tts addon
	var TTS = load("res://addons/godot-tts/TTS.gd")
	if TTS:
		_tts = TTS.new()
		add_child(_tts)
		# Connect to utterance signals if supported
		if _tts.are_utterance_callbacks_supported:
			_tts.connect("utterance_end", self, "_on_utterance_end")
		# Set initial rate
		if _tts.is_rate_supported:
			_tts.rate = _tts.normal_rate
		print("[Accessibility] godot-tts loaded successfully")
		if _tts.can_detect_screen_reader and _tts.has_screen_reader:
			print("[Accessibility] Screen reader detected")
	else:
		push_error("[Accessibility] Failed to load godot-tts addon!")

func _on_utterance_end(_utterance) -> void:
	emit_signal("speech_finished")

func _announce_startup() -> void:
	speak("Accessibility mod loaded. H health, shift H enemy, T time, G gold, J A P, B bestiary.", true)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	match event.scancode:
		KEY_H:
			if event.shift:
				_announce_enemy_health()
			else:
				_announce_player_health()
			get_tree().set_input_as_handled()
		KEY_T:
			_announce_time_of_day()
			get_tree().set_input_as_handled()
		KEY_G:
			_announce_money()
			get_tree().set_input_as_handled()
		KEY_J:
			_announce_player_ap()
			get_tree().set_input_as_handled()
		KEY_B:
			_announce_bestiary()
			get_tree().set_input_as_handled()
		KEY_F4:
			toggle_enabled()
			get_tree().set_input_as_handled()
		KEY_F5:
			_repeat_last()
			get_tree().set_input_as_handled()

# === CORE TTS ===

func speak(text: String, interrupt: bool = true) -> void:
	if not enabled or text.strip_edges().empty():
		return

	text = _clean_text(text)

	if debug_logging:
		print("[TTS] ", text)

	_last_spoken = text

	if _tts:
		_tts.speak(text, interrupt)
		emit_signal("speech_started", text)
	else:
		# Fallback: use OS.execute if godot-tts failed to load
		_speak_fallback(text, interrupt)

func stop() -> void:
	if _tts:
		_tts.stop()

func _speak_fallback(text: String, interrupt: bool) -> void:
	# Fallback to PowerShell SAPI if godot-tts is unavailable
	if interrupt:
		# Kill any running speech
		OS.execute("wmic.exe", [
			"process", "where",
			"name='powershell.exe' and commandline like '%System.Speech%'",
			"call", "terminate"
		], false)

	# Sanitize text for PowerShell
	text = text.replace("'", "")
	text = text.replace('"', "")
	text = text.replace("\n", " ")
	text = text.replace("`", "")
	text = text.replace("$", "")
	text = text.replace("&", " and ")

	if text.length() > 500:
		text = text.substr(0, 500)

	var cmd = "Add-Type -AssemblyName System.Speech; "
	cmd += "$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; "
	cmd += "$s.Speak('" + text + "')"
	OS.execute("powershell.exe", ["-NoProfile", "-WindowStyle", "Hidden", "-Command", cmd], false)

func _clean_text(text: String) -> String:
	# Remove BBCode tags like [color=red] or [b]
	var regex = RegEx.new()
	regex.compile("\\[.*?\\]")
	text = regex.sub(text, "", true)

	# Remove placeholders like {control.accept} or {font_height}
	regex.compile("\\{[^}]+\\}")
	text = regex.sub(text, "", true)

	# Collapse multiple spaces
	while "  " in text:
		text = text.replace("  ", " ")

	return text.strip_edges()

# === SPECIALIZED ANNOUNCERS ===

func announce_focus(control: Control) -> void:
	if not enabled or control == null:
		return

	var text = _get_control_text(control)

	# Skip if same as last focus (prevents repeated announcements)
	if text == _last_focus_text:
		return
	_last_focus_text = text

	if not text.empty():
		speak(text, true)

func announce_dialogue(speaker: String, text: String) -> void:
	if not enabled:
		return

	# Skip duplicate dialogue
	if text == _last_dialogue_text:
		return
	_last_dialogue_text = text

	var announcement = ""
	if speaker.empty():
		announcement = text
	else:
		announcement = speaker + " says, " + text

	speak(announcement, true)

func announce_menu(menu_name: String) -> void:
	if not enabled:
		return
	speak(menu_name + " menu", true)

func announce_list_item(item: String, index: int, total: int, color_index: int = -1) -> void:
	if not enabled:
		return
	# Clean the item text
	item = _clean_text(item)
	if item.empty():
		item = "Option"

	# If a color index was provided, get the color name (runtime lookup)
	if color_index >= 0:
		item = get_color_name_from_palette(color_index)
	# Fallback: if item looks like a number ("01", "02"), it's likely a color
	elif item.is_valid_integer():
		# The display index is 1-based, convert to 0-based palette index
		var palette_index = int(item) - 1
		if palette_index >= 0:
			item = get_color_name_from_palette(palette_index)

	speak(item + ", " + str(index + 1) + " of " + str(total), true)

func announce_option_change(field_name: String, value: String) -> void:
	if not enabled:
		return
	field_name = field_name.replace("_", " ").capitalize()
	value = _clean_text(value)
	if value.empty():
		value = "unknown"
	speak(field_name + ", " + value, true)

func announce_battle(event: String, args: Dictionary) -> void:
	if not enabled:
		return
	var announcement = ""
	match event:
		"round_start":
			var round_num = args.get("round", 1)
			announcement = "Round " + str(round_num)
		"victory":
			announcement = "Victory"
		"defeat":
			announcement = "Defeat"
		"switch":
			var trainer = args.get("trainer", "")
			var monster = args.get("monster", "")
			announcement = trainer + " switches to " + monster
		"item_used":
			var user = args.get("user", "")
			var item = args.get("item", "")
			announcement = user + " uses " + item
		"fusion":
			var f1 = args.get("fighter1", "")
			var f2 = args.get("fighter2", "")
			announcement = f1 + " fuses with " + f2
		"move_used":
			var user = args.get("user", "")
			var move = args.get("move", "")
			var target = args.get("target", "")
			if target != "":
				announcement = user + " uses " + move + " on " + target
			else:
				announcement = user + " uses " + move
		_:
			announcement = event.replace("_", " ")
	if announcement != "":
		speak(announcement, false)  # Don't interrupt for battle events

# === CONTROL TEXT EXTRACTION ===

func _get_control_text(control: Control) -> String:
	if control == null:
		return ""

	# Check for custom accessibility method first
	if control.has_method("get_accessibility_text"):
		return control.get_accessibility_text()

	# Special handling for ArrowOptionList (character creation, settings)
	if control.has_method("get_value_label") and "selected_index" in control:
		var field_name = _get_field_label(control)
		var value_text = control.get_value_label(control.selected_index)
		value_text = _clean_text(value_text)

		# Check if this is a color field - convert palette index to color name
		if "color" in field_name.to_lower() and "selected_value" in control:
			var color_index = control.selected_value
			if color_index is int:
				value_text = get_color_name_from_palette(color_index)
			elif value_text.is_valid_integer():
				var num = int(value_text) - 1
				if num >= 0:
					value_text = get_color_name_from_palette(num)

		if field_name.empty():
			return value_text
		return field_name + ", " + value_text

	# Try "text" property (Button, Label, etc)
	if "text" in control and control.text is String and not control.text.empty():
		var text = _clean_text(control.text)
		if control.get("disabled"):
			text += ", disabled"
		return text

	# Try tooltip
	if "hint_tooltip" in control and control.hint_tooltip is String and not control.hint_tooltip.empty():
		return _clean_text(control.hint_tooltip)

	# Try to find Label child
	for child in control.get_children():
		if child is Label and not child.text.empty():
			return _clean_text(child.text)

	# Fallback: convert node name to readable text
	return _node_name_to_text(control.name)

func _get_field_label(control: Control) -> String:
	var parent = control.get_parent()
	if parent == null:
		return ""

	var my_index = control.get_index()
	if my_index > 0:
		var prev_sibling = parent.get_child(my_index - 1)
		if prev_sibling is Label:
			return _clean_text(prev_sibling.text)

	var ctrl_name = control.name
	if ctrl_name.begins_with("Field_"):
		ctrl_name = ctrl_name.substr(6)
	return ctrl_name.replace("_", " ").capitalize()

func _node_name_to_text(node_name: String) -> String:
	node_name = node_name.replace("_", " ")
	var result = ""
	for i in range(node_name.length()):
		var c = node_name[i]
		if c == c.to_upper() and i > 0 and node_name[i-1] != " " and node_name[i-1] != node_name[i-1].to_upper():
			result += " "
		result += c
	return result.strip_edges()

# === HOTKEY HANDLERS ===

func _announce_help() -> void:
	speak("H health, shift H enemy, T time, G gold, J A P, B bestiary, F4 toggle, F5 repeat", true)

func _repeat_last() -> void:
	if _last_spoken.empty():
		speak("Nothing to repeat", true)
	else:
		speak(_last_spoken, true)

func _announce_current_focus() -> void:
	var viewport = get_viewport()
	if viewport == null:
		speak("No viewport", true)
		return

	var focused = viewport.gui_get_focus_owner()
	if focused == null:
		speak("No focus", true)
	else:
		var text = _get_control_text(focused)
		if text.empty():
			speak(focused.name, true)
		else:
			speak(text, true)

func _announce_battle_state() -> void:
	# Find the Battle node if we're in a battle
	var battle = _find_battle_node()
	if battle == null:
		speak("Not in battle", true)
		return

	var announcement = ""

	# Get player team fighters
	var teams = battle.get_teams(false, false) if battle.has_method("get_teams") else {}

	# Announce player team status
	if teams.has(0):
		var player_fighters = teams[0]
		for fighter in player_fighters:
			var name = _get_fighter_name(fighter)
			var hp_info = _get_fighter_hp_string(fighter)
			announcement += name + ": " + hp_info + ". "

	# Announce enemy team status
	if teams.has(1):
		announcement += "Enemies: "
		var enemy_fighters = teams[1]
		for i in range(enemy_fighters.size()):
			var fighter = enemy_fighters[i]
			var name = _get_fighter_name(fighter)
			var hp_info = _get_fighter_hp_string(fighter)
			if i > 0:
				announcement += ", "
			announcement += name + " " + hp_info
		announcement += ". "

	if announcement.empty():
		speak("No battle info available", true)
	else:
		speak(announcement, true)

func _announce_player_health() -> void:
	var battle = _get_current_battle()
	if battle == null:
		speak("Not in battle", true)
		return

	var fighters = battle.get_fighters(false)
	var announcement = ""
	for fighter in fighters:
		if fighter.team == 0:
			var fname = fighter.get_general_name() if fighter.has_method("get_general_name") else "Fighter"
			var hp = fighter.status.hp
			var max_hp = fighter.status.max_hp
			var pct = int((float(hp) / float(max_hp)) * 100) if max_hp > 0 else 0
			announcement += fname + ", " + str(pct) + " percent. "

	if announcement.empty():
		speak("No player fighters", true)
	else:
		speak(announcement, true)

func _announce_enemy_health() -> void:
	var battle = _get_current_battle()
	if battle == null:
		speak("Not in battle", true)
		return

	var fighters = battle.get_fighters(false)
	var announcement = ""
	for fighter in fighters:
		if fighter.team != 0:
			var fname = fighter.get_general_name() if fighter.has_method("get_general_name") else "Enemy"
			var hp = fighter.status.hp
			var max_hp = fighter.status.max_hp
			var pct = int((float(hp) / float(max_hp)) * 100) if max_hp > 0 else 0
			announcement += fname + ", " + str(pct) + " percent. "

	if announcement.empty():
		speak("No enemies", true)
	else:
		speak(announcement, true)

func _get_current_battle():
	if SceneManager == null:
		return null
	var scene = SceneManager.current_scene
	if scene == null:
		return null
	if scene.name == "Battle":
		return scene
	return null

func _announce_time_of_day() -> void:
	if SaveState == null:
		speak("Time not available", true)
		return

	var world_time = SaveState.world_time
	if world_time == null:
		speak("Time not available", true)
		return

	var hour = world_time.get_hour()
	var is_night = world_time.is_night()
	var day = world_time.date

	var hours = int(hour)
	var minutes = int((hour - hours) * 60)
	var period = "night" if is_night else "day"

	speak("Day " + str(day + 1) + ", " + str(hours) + " " + str(minutes) + ", " + period, true)

func _announce_money() -> void:
	if SaveState == null:
		speak("Money not available", true)
		return

	var money = SaveState.money
	speak(str(money) + " gold", true)

func _announce_player_ap() -> void:
	var battle = _get_current_battle()
	if battle == null:
		speak("Not in battle", true)
		return

	var fighters = battle.get_fighters(false)
	var announcement = ""
	for fighter in fighters:
		if fighter.team == 0:
			var fname = fighter.get_general_name() if fighter.has_method("get_general_name") else "Fighter"
			var ap = fighter.status.ap if "ap" in fighter.status else 0
			var max_ap = fighter.status.max_ap if "max_ap" in fighter.status else 0
			announcement += fname + ", " + str(ap) + " of " + str(max_ap) + " A P. "

	if announcement.empty():
		speak("No player fighters", true)
	else:
		speak(announcement, true)

func _announce_bestiary() -> void:
	# Try to find the bestiary menu and get current species
	var bestiary_menu = _find_bestiary_menu()
	if bestiary_menu == null:
		speak("Not in bestiary", true)
		return

	var species = bestiary_menu.species
	if species == null:
		speak("No species selected", true)
		return

	var announcement = ""

	# Species name and number
	var species_name = Loc.tr(species.name) if "name" in species else "Unknown"
	var code = MonsterForms.get_bestiary_code(species)
	announcement += code + ", " + species_name + ". "

	# Types
	var types = []
	if species is MonsterForm:
		types = MonsterForms.get_type_mapping(species)
		if types.size() == 0 and "elemental_types" in species:
			types = species.elemental_types
	elif "elemental_types" in species:
		types = species.elemental_types

	if types.size() > 0:
		var type_names = []
		for etype in types:
			if etype and "name" in etype:
				type_names.append(Loc.tr(etype.name))
		if type_names.size() > 0:
			announcement += " and ".join(type_names) + " type. "

	# Check if we have bio data
	if species is MonsterForm:
		if SaveState.species_collection.has_bestiary_data_requirement(species, 0):
			# Bio is unlocked - read first bio
			if species.bestiary_bios.size() > 0:
				var bio_text = Loc.tr(species.bestiary_bios[0])
				bio_text = _clean_text(bio_text)
				announcement += bio_text + " "
		else:
			announcement += "Bio locked. Record to unlock. "

		# Stats
		var encountered = SaveState.species_collection.get_num_encountered(species)
		var recorded = SaveState.species_collection.get_num_recorded(species)
		var defeated = SaveState.species_collection.get_num_defeated(species)
		announcement += "Encountered " + str(encountered) + ", recorded " + str(recorded) + ", defeated " + str(defeated) + ". "
	elif species is FusionForm:
		# Fusion
		announcement += "Fusion of " + Loc.tr(species.base_form_1.name) + " and " + Loc.tr(species.base_form_2.name) + ". "
		var formed = SaveState.species_collection.get_num_fusions_formed(species.base_form_1, species.base_form_2)
		announcement += "Formed " + str(formed) + " times. "

	speak(announcement, true)

func _find_bestiary_menu():
	# Search for BestiaryMenu in the scene tree
	var root = get_tree().root
	return _find_node_by_script(root, "BestiaryMenu")

func _find_node_by_script(node: Node, script_name: String):
	if node.get_script() != null:
		var script_path = node.get_script().resource_path
		if script_name in script_path:
			return node
	for child in node.get_children():
		var result = _find_node_by_script(child, script_name)
		if result != null:
			return result
	return null

func toggle_enabled() -> void:
	enabled = not enabled
	var msg = "Accessibility enabled" if enabled else "Accessibility disabled"
	var was = enabled
	enabled = true
	speak(msg, true)
	enabled = was

func set_rate(rate: float) -> void:
	speech_rate = clamp(rate, 0.1, 2.0)
	if _tts and _tts.is_rate_supported:
		# Convert normalized rate to TTS rate range
		_tts.rate = lerp(_tts.min_rate, _tts.max_rate, (speech_rate - 0.1) / 1.9)

# === SCREEN READER DETECTION ===

func has_screen_reader() -> bool:
	if _tts and _tts.can_detect_screen_reader:
		return _tts.has_screen_reader
	return false

func is_speaking() -> bool:
	if _tts and _tts.can_detect_is_speaking:
		return _tts.is_speaking
	return false

# === SPEECH QUEUE SYSTEM ===
# Allows queuing speech to play after current dialogue finishes

func _process_speech_queue() -> void:
	# Only process queue when not actively speaking dialogue
	if _is_dialogue_playing:
		return

	# Check if TTS is still speaking
	if is_speaking():
		return

	# Process next item in queue
	if _speech_queue.size() > 0:
		var queued_text = _speech_queue.pop_front()
		speak(queued_text, false)

func speak_queued(text: String) -> void:
	# Add text to queue instead of speaking immediately
	if not enabled or text.strip_edges().empty():
		return

	text = _clean_text(text)
	_speech_queue.push_back(text)

	if debug_logging:
		print("[TTS Queued] ", text)

func set_dialogue_playing(playing: bool) -> void:
	_is_dialogue_playing = playing
	if debug_logging:
		print("[TTS] Dialogue playing: ", playing)

func clear_speech_queue() -> void:
	_speech_queue.clear()

func announce_dialogue_options(options: Array) -> void:
	# Wait for dialogue to finish, then announce options
	if not enabled or options.size() == 0:
		return

	var announcement = "Options: "
	for i in range(options.size()):
		var option_text = _clean_text(str(options[i]))
		if i > 0:
			announcement += ", "
		announcement += str(i + 1) + ") " + option_text

	# Queue this to play after dialogue finishes
	speak_queued(announcement)

func announce_cassette_obtained(tape_name: String, species_name: String) -> void:
	if not enabled:
		return

	var announcement = "Cassette obtained: " + species_name
	if tape_name != "" and tape_name != species_name:
		announcement += ", named " + tape_name

	speak(announcement, true)

func announce_naming_screen(title: String, current_name: String) -> void:
	if not enabled:
		return

	var announcement = title
	if current_name != "":
		announcement += ", current name: " + current_name
	announcement += ". Type a name or press confirm to accept."

	speak(announcement, true)

func announce_item(item_name: String, amount: int, equipped: bool, rarity: String) -> void:
	if not enabled:
		return

	var announcement = item_name

	if amount > 1:
		announcement += ", " + str(amount)

	if equipped:
		announcement += ", equipped"

	if rarity != "" and rarity != "common":
		announcement += ", " + rarity

	speak(announcement, true)

func announce_tape_info(tape_name: String, species_name: String, types: Array, hp_percent: float, is_broken: bool, grade: int) -> void:
	if not enabled:
		return

	var announcement = tape_name
	if tape_name != species_name:
		announcement += ", " + species_name

	# Announce types
	if types.size() > 0:
		announcement += ", "
		for i in range(types.size()):
			if i > 0:
				announcement += " and "
			announcement += types[i]
		announcement += " type"

	# Announce HP status
	if is_broken:
		announcement += ", broken"
	elif hp_percent < 100:
		announcement += ", " + str(int(hp_percent)) + " percent HP"

	# Announce grade
	if grade > 0:
		announcement += ", grade " + str(grade)

	speak(announcement, true)
