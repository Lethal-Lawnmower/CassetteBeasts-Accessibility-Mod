extends Control

const DEFAULT_FONT = preload("res://ui/fonts/regular/regular_50.tres")
const BOLD_FONT = preload("res://ui/fonts/regular/regular_50_bold.tres")
const ITALIC_FONT = preload("res://ui/fonts/regular/regular_50_italic.tres")
const DEFAULT_TYPE_SOUNDS = preload("res://sfx/typing/default/default.tres")

signal typed_out
signal finished

export (Texture) var portrait: Texture = null setget set_portrait
export (int, "Left", "Center", "Right") var portrait_position: int = 0 setget set_portrait_position
export (String) var title: String = "" setget set_title
export (String, MULTILINE) var text: String = "" setget set_text
export (AudioStream) var audio: AudioStream setget set_audio
export (Resource) var type_sounds: Resource setget set_type_sounds
export (Font) var font: Font setget set_font
export (bool) var cancelable: bool = true

onready var slider = $Slider
onready var label = find_node("Label")
onready var title_row = find_node("TitleRow")
onready var title_label = find_node("TitleLabel")
onready var portrait_positioner = find_node("PortraitPositioner")
onready var portrait_control = find_node("Portrait")
onready var audio_stream_player = $AudioStreamPlayer
onready var next_arrow = find_node("NextArrow")
onready var next_arrow_audio = next_arrow.get_node(@"AudioStreamPlayer")
onready var tween = $Tween
onready var message_box = find_node("MessageBox")

var finished: bool = false setget set_finished
var wait_for_confirm: bool = true

func _ready():
	set_text(text)
	set_title(title)
	set_portrait(portrait)
	set_portrait_position(portrait_position)
	set_type_sounds(type_sounds)
	set_font(font)
	if get_tree().get_current_scene() == self:
		show()
	else:
		visible = false

func grab_focus():
	slider.grab_focus()

func get_box_rect() -> Rect2:
	return message_box.get_global_rect()

func set_finished(value: bool):
	finished = value
	if finished:
		next_arrow.visible = false
		emit_signal("finished")

func set_audio(value: AudioStream):
	audio = value

func set_type_sounds(value: Resource):
	type_sounds = value
	if label:
		label.type_sounds = type_sounds if type_sounds else DEFAULT_TYPE_SOUNDS

func set_font(value: Font):
	font = value
	if label:
		label.add_font_override("normal_font", font if font else DEFAULT_FONT)
		label.add_font_override("bold_font", font if font else BOLD_FONT)
		label.add_font_override("italics_font", font if font else ITALIC_FONT)
		label.add_font_override("bold_italics_font", font if font else ITALIC_FONT)

func set_text(value: String):
	text = value
	if label != null:
		var font_height = label.get_font("normal_font").get_height()
		var translation = Loc.tr(value).format({font_height = font_height})
		if "{control." in translation:
			translation = translation.format(InputIcons.get_action_bbcodes(font_height))
		label.parse_bbcode(translation)
		# Accessibility: Announce dialogue text (defer to ensure visibility is set)
		# Use call_deferred to announce after the show() call completes
		if Accessibility:
			call_deferred("_announce_dialogue_deferred", translation)

func _announce_dialogue_deferred(translation: String) -> void:
	# Only announce if the dialog is now visible
	if visible and Accessibility:
		var speaker_name = Loc.tr(title) if title != "" else ""
		Accessibility.announce_dialogue(speaker_name, translation)

func set_title(value: String):
	title = value
	if title_label:
		title_label.text = Loc.tr(value)
	if title_row:
		title_row.visible = title != ""

func set_portrait(value: Texture):
	portrait = value
	if portrait_control:
		portrait_control.texture = portrait

func set_portrait_position(value: int):
	portrait_position = value
	if portrait_positioner:
		portrait_positioner.alignment = portrait_position
	if portrait_control:
		portrait_control.flip_h = value == BoxContainer.ALIGN_END

func show():
	visible = true
	slider.hidden_offset = Vector2( - 1, 0)
	if portrait and portrait_position == 2:
		slider.hidden_offset = Vector2(1, 0)
	if not slider.visible:
		slider.scaled_offset = slider.hidden_offset
	set_finished(false)
	label.stop()
	label.reset()
	label.start()

	# Accessibility: Mark dialogue as playing
	if Accessibility:
		Accessibility.set_dialogue_playing(true)

	if audio:
		audio_stream_player.stream = audio
		audio_stream_player.play()

	yield(Co.join([slider.show(), _fade_portrait(1.0)]), "completed")

func show_message(message: String, close_after: bool = true, wait_for_confirm: bool = true):
	self.text = message
	self.cancelable = close_after
	self.wait_for_confirm = wait_for_confirm
	next_arrow.visible = false
	yield(show(), "completed")
	if wait_for_confirm and not finished:
		yield(self, "finished")
	elif not label.finished:
		yield(self, "typed_out")

func hide(keep_visible: bool = false):
	if not visible:
		return Co.pass()
	
	slider.hidden_offset = Vector2(1, 0)
	if portrait and portrait_position == 0:
		slider.hidden_offset = Vector2( - 1, 0)
	label.stop()
	next_arrow.visible = false
	
	yield(Co.join([slider.hide(keep_visible), _fade_portrait(0.0)]), "completed")
	
	visible = false
	set_finished(true)

func _fade_portrait(alpha: float):
	if Input.is_action_pressed("fast_mode") and UserSettings.show_timer:
		portrait_positioner.modulate.a = alpha
		return
	tween.stop_all()
	tween.remove_all()
	tween.interpolate_property(portrait_positioner, "modulate:a", null, alpha, slider.tween_duration, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	tween.start()
	yield(Co.wait_for_tween(tween), "completed")

func _input(event: InputEvent):
	if not visible or GlobalUI.is_input_blocked() or MultiplayerInput.get_player_index(event) == - 1:
		return
	if get_focus_owner() != null and get_focus_owner() != self and not is_a_parent_of(get_focus_owner()):
		return
	if (event is InputEventMouseButton and event.pressed) or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("fast_mode"):
		if not label.next() and not slider.tween.is_active():
			if next_arrow.visible:
				next_arrow_audio.play()
			if cancelable:
				hide()
			else:
				set_finished(true)
		get_tree().set_input_as_handled()

func _on_Label_typed_out():
	next_arrow.visible = wait_for_confirm
	emit_signal("typed_out")

	# Accessibility: Mark dialogue as finished typing so queued speech can play
	if Accessibility:
		Accessibility.set_dialogue_playing(false)

	if Input.is_action_pressed("fast_mode") and UserSettings.show_timer:
		if cancelable:
			hide()
		else:
			set_finished(true)
