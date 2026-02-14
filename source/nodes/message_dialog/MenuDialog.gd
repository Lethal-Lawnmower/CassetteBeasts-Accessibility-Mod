extends PanelContainer

signal option_chosen(option_index)

export (Array, String) var options: Array setget set_options
export (int) var initial_index: int = 0 setget set_initial_index
export (int) var default_index: int = - 1
export (bool) var valign_center: bool = true setget set_valign_center

onready var buttons_panel = $ScrollContainer / PanelContainer
onready var buttons = $ScrollContainer / PanelContainer / Buttons

var t: float = 0.0

func _ready():
	set_options(options)
	set_process(false)
	# Accessibility: Connect visibility change for TTS
	connect("visibility_changed", self, "_on_visibility_changed_accessibility")

func set_valign_center(value: bool):
	valign_center = value
	if buttons_panel:
		buttons_panel.size_flags_vertical = SIZE_EXPAND | (SIZE_SHRINK_CENTER if valign_center else SIZE_SHRINK_END)

func set_options(value: Array):
	options = value
	if buttons:
		for button in buttons.get_children():
			buttons.remove_child(button)
			button.queue_free()
		for i in range(options.size()):
			var option = options[i]
			var button = preload("MenuDialogButton.tscn").instance()
			button.set_bbcode("[center]{0}[/center]".format([tr(option)]))
			buttons.add_child(button)
			button.connect("pressed", self, "_button_pressed", [i])
			# Accessibility: Connect focus signal for individual option announcements
			if button.has_signal("focus_entered"):
				button.connect("focus_entered", self, "_on_button_focus_entered_accessibility", [i])
		buttons.setup_focus()
		set_initial_index(initial_index)

func set_initial_index(value: int):
	initial_index = value
	if buttons and initial_index >= 0 and initial_index < buttons.focusable_children.size():
		var initial_btn = buttons.focusable_children[initial_index]
		buttons.initial_focus = buttons.get_path_to(initial_btn)

func _process(delta: float):
	t += delta
	if Input.is_action_pressed("fast_mode") and UserSettings.show_timer:
		if t > 0.1:
			_button_pressed(initial_index)

func grab_focus():
	buttons.grab_focus()
	if visible:
		t = 0.0
		set_process(true)

func _button_pressed(option_index):
	set_process(false)
	emit_signal("option_chosen", option_index)

func _input(event):
	if not visible or GlobalUI.is_input_blocked() or not buttons.has_focus():
		return
	if event.is_action_pressed("ui_cancel") and default_index >= 0:
		if buttons.get_focus_owner() == buttons.get_child(default_index):
			set_process(false)
			emit_signal("option_chosen", default_index)
		else:
			buttons.get_child(default_index).grab_focus()
		get_tree().set_input_as_handled()

func cancel():
	set_process(false)
	if default_index >= 0:
		emit_signal("option_chosen", default_index)
	else:
		emit_signal("option_chosen", 0)

func _on_visibility_changed_accessibility():
	if not visible:
		return

	# Announce dialogue options when menu becomes visible
	call_deferred("_announce_options_deferred")

func _announce_options_deferred():
	if not Accessibility or options.size() == 0:
		return

	# Build announcement of all options
	var announcement = ""
	for i in range(options.size()):
		var option_text = tr(options[i])
		# Clean BBCode and placeholders
		var regex = RegEx.new()
		regex.compile("\\[.*?\\]")
		option_text = regex.sub(option_text, "", true)
		regex.compile("\\{[^}]+\\}")
		option_text = regex.sub(option_text, "", true)
		option_text = option_text.strip_edges()

		if option_text != "":
			if announcement != "":
				announcement += ", "
			announcement += str(i + 1) + ") " + option_text

	if announcement != "":
		# Use queued speech so it waits for dialogue to finish
		Accessibility.speak_queued("Options: " + announcement)

func _on_button_focus_entered_accessibility(index: int):
	if not Accessibility or index < 0 or index >= options.size():
		return

	var option_text = tr(options[index])
	# Clean BBCode and placeholders
	var regex = RegEx.new()
	regex.compile("\\[.*?\\]")
	option_text = regex.sub(option_text, "", true)
	regex.compile("\\{[^}]+\\}")
	option_text = regex.sub(option_text, "", true)
	option_text = option_text.strip_edges()

	if option_text != "":
		Accessibility.speak(option_text + ", " + str(index + 1) + " of " + str(options.size()), true)
