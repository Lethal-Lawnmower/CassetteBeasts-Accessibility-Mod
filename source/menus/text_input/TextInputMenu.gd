extends "res://menus/BaseMenu.gd"

export (String) var title: String
export (String) var default_text: String
export (String) var placeholder: String
export (int) var max_length: int = 20
export (bool) var max_width: int = 0
export (bool) var convert_to_upper: bool

onready var title_label = find_node("TitleLabel")
onready var line_edit = find_node("LineEdit")

func _ready():
	title_label.text = title
	line_edit.max_length = max_length
	line_edit.max_width = max_width
	line_edit.text = default_text
	line_edit.placeholder_text = placeholder
	line_edit.convert_to_upper = convert_to_upper

	# Accessibility: Announce the naming screen when ready
	call_deferred("_announce_naming_screen")

func _announce_naming_screen():
	if not Accessibility:
		return

	var title_text = tr(title) if title != "" else "Enter name"
	var current_text = default_text if default_text != "" else ""

	Accessibility.announce_naming_screen(title_text, current_text)

func grab_focus():
	line_edit.grab_focus()

func _on_SubmitButton_pressed():
	choose_option(line_edit.text)
