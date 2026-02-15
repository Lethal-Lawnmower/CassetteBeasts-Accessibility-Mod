extends Control

signal option_chosen(option)

onready var buttons = $OverscanMarginContainer / Buttons
onready var check_character_btn = $OverscanMarginContainer / Buttons / CheckCharacterBtn
onready var check_tape_btn = $OverscanMarginContainer / Buttons / CheckTapeBtn
onready var transform_btn = $OverscanMarginContainer / Buttons / TransformBtn
onready var swap_tape_btn = $OverscanMarginContainer / Buttons / SwapTapeBtn
onready var put_away_btn = $OverscanMarginContainer / Buttons / PutAwayBtn
onready var cancel_btn = $OverscanMarginContainer / Buttons / CancelBtn

var battle
var character: Character
var tape: MonsterTape
var disable_transformation: bool = false
var hide_char_name: bool = false

func _ready():
	if character == null or hide_char_name:
		buttons.remove_child(check_character_btn)
		check_character_btn.queue_free()
	else:
		check_character_btn.text = Loc.trf("UI_PARTY_CHECK_CHARACTER", {
			"name": character.name
		})
		check_character_btn.connect("focus_entered", self, "_on_button_focus_accessibility", [check_character_btn])

	if tape == null:
		buttons.remove_child(check_tape_btn)
		check_tape_btn.queue_free()
	else:
		check_tape_btn.connect("focus_entered", self, "_on_button_focus_accessibility", [check_tape_btn])

	if not battle or not tape or (disable_transformation and character):
		buttons.remove_child(transform_btn)
		transform_btn.queue_free()
	else:
		assert (tape != null)
		if tape.is_broken() or disable_transformation:
			transform_btn.set_disabled(true)
		transform_btn.connect("focus_entered", self, "_on_button_focus_accessibility", [transform_btn])

	if battle or tape == null:
		buttons.remove_child(swap_tape_btn)
		swap_tape_btn.queue_free()
	else:
		swap_tape_btn.connect("focus_entered", self, "_on_button_focus_accessibility", [swap_tape_btn])

	if battle or tape == null or character != null:
		buttons.remove_child(put_away_btn)
		put_away_btn.queue_free()
	else:
		put_away_btn.connect("focus_entered", self, "_on_button_focus_accessibility", [put_away_btn])

	cancel_btn.connect("focus_entered", self, "_on_button_focus_accessibility", [cancel_btn])
	buttons.setup_focus()

func _on_button_focus_accessibility(button: Button):
	if Accessibility:
		var btn_text = Loc.tr(button.text) if button.text else "Button"
		if button.disabled:
			btn_text += ", disabled"
		Accessibility.speak(btn_text, true)

func grab_focus():
	buttons.grab_focus()

func _process(_delta):
	if not get_focus_owner() or not is_a_parent_of(get_focus_owner()):
		get_parent().remove_child(self)
		queue_free()

func choose_option(option):
	emit_signal("option_chosen", option)
	get_parent().remove_child(self)
	queue_free()

func _on_CancelBtn_pressed():
	choose_option(null)

func _unhandled_input(event):
	if not MenuHelper.is_in_top_menu(self):
		return
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		_on_CancelBtn_pressed()

func _on_TransformBtn_pressed():
	choose_option("transform")

func _on_PutAwayBtn_pressed():
	choose_option("put_away")

func _on_CheckCharacterBtn_pressed():
	choose_option("check_character")

func _on_CheckTapeBtn_pressed():
	choose_option("check_tape")

func _on_SwapTapeBtn_pressed():
	choose_option("swap_tape")

func _on_PartyActionButtons_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		choose_option(null)
