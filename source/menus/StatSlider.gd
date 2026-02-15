extends HBoxContainer

const TWEEN_DURATION = 0.5
const INPUT_REPEAT = 0.1

signal value_change_requested(stat, delta, new_value)

export (String, "max_hp", "melee_attack", "melee_defense", "ranged_attack", "ranged_defense", "speed") var stat: String = "max_hp" setget set_stat
export (int) var value: int = 100 setget set_value
export (int) var min_value: int = 50 setget set_min_value
export (int) var max_value: int = 200 setget set_max_value
export (int) var default_value: int = Character.STAT_BASE setget set_default_value

onready var label = $Label
onready var bar = $Bar
onready var progress_bar1 = find_node("ProgressBar1")
onready var progress_bar2 = find_node("ProgressBar2")
onready var background1 = find_node("Background1")
onready var background2 = find_node("Background2")
onready var value_label = find_node("ValueLabel")
onready var min_position1 = find_node("MinPosition1")
onready var min_position2 = find_node("MinPosition2")

var t: float = 0.0

func _ready():
	set_stat(stat)
	set_default_value(default_value)
	set_max_value(max_value)
	set_value(value)
	# Accessibility: Connect focus signal
	connect("focus_entered", self, "_on_focus_entered_accessibility")

func _on_focus_entered_accessibility():
	if not Accessibility:
		return

	var stat_name = Loc.tr("STAT_" + stat) if stat != "" else "Stat"
	var announcement = stat_name + ": " + str(value)

	# Indicate if above or below default
	if value > default_value:
		announcement += ", plus " + str(value - default_value) + " from default"
	elif value < default_value:
		announcement += ", minus " + str(default_value - value) + " from default"

	announcement += ". Use left and right to adjust."

	Accessibility.speak(announcement, true)

func set_stat(value: String):
	stat = value
	if label:
		label.text = "STAT_" + stat

func set_value(x: int):
	value = x
	if value_label:
		value_label.text = str(value)
		progress_bar1.value = min(value, default_value)
		progress_bar2.value = max(0, value - default_value)

func set_max_value(value: int):
	max_value = value
	if progress_bar2:
		progress_bar2.max_value = max_value - default_value
	_update_stretch_ratios()

func set_default_value(value: int):
	default_value = value
	if progress_bar1:
		progress_bar1.max_value = default_value
		progress_bar2.max_value = max_value - default_value
	_update_stretch_ratios()

func set_min_value(value: int):
	min_value = value
	if min_position1:
		min_position1.size_flags_stretch_ratio = float(min_value) / float(max_value)
		min_position2.size_flags_stretch_ratio = float(max_value - min_value) / float(max_value)

func _update_stretch_ratios():
	if not progress_bar1:
		return
	progress_bar1.size_flags_stretch_ratio = float(default_value) / float(max_value)
	progress_bar2.size_flags_stretch_ratio = float(max_value - default_value) / float(max_value)
	background1.size_flags_stretch_ratio = float(default_value) / float(max_value)
	background2.size_flags_stretch_ratio = float(max_value - default_value) / float(max_value)

func change_value(delta: int):
	if value + delta >= min_value and value + delta <= max_value:
		emit_signal("value_change_requested", stat, delta, value + delta)

func _process(delta: float):
	if has_focus():
		t += delta
		
		var left_pressed = Input.is_action_pressed("ui_left")
		var right_pressed = Input.is_action_pressed("ui_right")
		if not left_pressed and not right_pressed:
			t = 0.0
		if t > INPUT_REPEAT:
			if left_pressed:
				change_value( - 1)
			if right_pressed:
				change_value(1)
			t = 0.0

func _on_StatSlider_gui_input(event):
	if event.is_action_pressed("ui_left"):
		change_value( - 1)
		accept_event()
	elif event.is_action_pressed("ui_right"):
		change_value(1)
		accept_event()

func _on_Bar_gui_input(event):
	var mouse = event as InputEventMouse
	if mouse and (mouse.button_mask & 1) != 0:
		var target_value = int(clamp(mouse.position.x * max_value / bar.rect_size.x, min_value, max_value))
		var delta = target_value - value
		emit_signal("value_change_requested", stat, delta, target_value)
		accept_event()
