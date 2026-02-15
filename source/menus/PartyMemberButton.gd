extends TextureButton

onready var tape_panel = $TapePanel
onready var sprite_container = find_node("SpriteContainer")
onready var name_label = find_node("NameLabel")
onready var level_label = find_node("LevelLabel")
onready var hp_bar = find_node("HPBar")
onready var exp_bar = find_node("ExpBar")
onready var relationship_meter = find_node("RelationshipMeter")

var character: Character setget set_character
var tape: MonsterTape setget set_tape
var hide_char_name: bool setget set_hide_char_name

func _ready():
	set_character(character)
	set_tape(tape)
	# Accessibility: Connect focus signal for TTS announcements
	connect("focus_entered", self, "_on_focus_entered_accessibility")

func _on_focus_entered_accessibility():
	if not Accessibility:
		return

	var announcement = ""

	if character:
		var char_name = character.name if not hide_char_name else "Unknown"
		announcement = char_name + ", level " + str(character.level)

		# Add HP info
		if hp_bar and hp_bar.character:
			var max_hp = hp_bar.max_value
			var current_hp = hp_bar.value
			var hp_percent = int((float(current_hp) / float(max_hp)) * 100) if max_hp > 0 else 0
			announcement += ", " + str(hp_percent) + " percent health"

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

func set_hide_char_name(value: bool):
	hide_char_name = value
	update_ui()

func get_focus_indicator_anchor() -> Vector2:
	return Vector2(0.05, 0.5)

func set_character(value: Character):
	var changed = value != character
	if changed and character != null:
		character.disconnect("appearance_changed", self, "update_sprite")
	character = value
	if changed and character != null:
		character.connect("appearance_changed", self, "update_sprite")
	update_ui()
	if changed:
		update_sprite()

func set_tape(value: MonsterTape):
	tape = value
	if tape_panel:
		tape_panel.set_tape(tape)

func update_ui():
	if not name_label:
		return
	
	if hide_char_name:
		name_label.text = "UNKNOWN_NAME"
	else:
		name_label.text = character.name if character else ""
	level_label.text = Loc.trf("UI_CHARACTER_LEVEL", ["%02d" % character.level]) if character else ""
	hp_bar.character = character
	relationship_meter.character = character
	
	exp_bar.set_max_exp_points(character.get_exp_to_next_level() if character else 1)
	exp_bar.set_exp_points(character.exp_points if character else 0)
	exp_bar.visible = character != null
	
	tape_panel.set_tape(tape)

func update_sprite():
	sprite_container.set_sprite(character.battle_sprite_instance() if character else null)

func animate_exp_points(speed: float = 1.0):
	var co_list = []
	var co = animate_character_exp_points(speed)
	if co:
		co_list.push_back(co)
	co = tape_panel.animate_exp_points(speed)
	if co:
		co_list.push_back(co)
	if co_list.size() > 0:
		return Co.join(co_list)
	return null

func animate_tape_exp_points(overflow_speed: float = 1.0):
	return tape_panel.animate_exp_points(overflow_speed)

func animate_character_exp_points(overflow_speed: float = 1.0):
	if not character:
		return null
	
	var speed = overflow_speed if character.exp_points >= character.get_exp_to_next_level() else 1.0
	return exp_bar.animate_exp_points(character.exp_points, speed)

func rewind_tape_to(value: Rational):
	tape_panel.rewind_tape_to(value)
