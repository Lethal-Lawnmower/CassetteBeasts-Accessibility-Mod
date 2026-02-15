extends "res://menus/BaseMenu.gd"

onready var buttons = $"%Buttons"

func _ready():
	for child in buttons.get_children():
		child.connect("pressed", self, "_on_button_pressed", [child.get_index()])
		# Accessibility: Connect focus signal for each button
		child.connect("focus_entered", self, "_on_button_focus_accessibility", [child])

	update_ui()

func _on_button_focus_accessibility(button):
	if not Accessibility:
		return

	var difficulty_index = button.get_index()
	var current_difficulty = SaveState.gauntlet.state.difficulty

	var announcement = Loc.tr(button.text) if button.text else "Difficulty " + str(difficulty_index + 1)

	if difficulty_index == current_difficulty:
		announcement += ", currently selected"

	Accessibility.speak(announcement, true)

func shown():
	.shown()
	update_ui()

func update_ui() -> void :
	var difficulty: int = SaveState.gauntlet.state.difficulty
	if difficulty < 0:
		difficulty = 0
	if difficulty >= buttons.get_child_count():
		difficulty = buttons.get_child_count() - 1
	buttons.initial_focus = buttons.get_path_to(buttons.get_child(difficulty))

func grab_focus():
	buttons.grab_focus()

func _on_button_pressed(index: int) -> void :
	if index == SaveState.gauntlet.state.difficulty:
		choose_option(null)
		return
	
	if yield(MenuHelper.custom_confirm("GAUNTLET_DIFFICULTY_CONFIRM", "UI_BUTTON_OK", "UI_BUTTON_CANCEL"), "completed"):
		choose_option(index)
	buttons.get_child(index).grab_focus()

