extends "res://menus/BaseMenu.gd"

const DEFAULT_TYPE_SOUNDS = preload("res://sfx/typing/default/default.tres")
const FORMAT = "[center][shake level=30]{0}[/shake][/center]"

export (String) var text: String = ""
export (AudioStream) var audio: AudioStream setget set_audio
export (Resource) var type_sounds: Resource setget set_type_sounds

onready var label = find_node("RichTypeOutLabel")
onready var audio_stream_player = $AudioStreamPlayer

func _ready():
	set_audio(audio)
	set_type_sounds(type_sounds)
	
	if SceneManager.current_scene == self:
		text = "lorem ipsum dolor sit amet"
		run_menu()

func set_audio(value: AudioStream):
	audio = value
	if audio_stream_player:
		audio_stream_player.stream = audio

func set_type_sounds(value: Resource):
	type_sounds = value
	if label:
		label.type_sounds = type_sounds if type_sounds else DEFAULT_TYPE_SOUNDS

func display():
	if audio_stream_player.stream:
		audio_stream_player.play()
	
	label.parse_bbcode(FORMAT.format([text]))
	label.reset()
	return .display()

func shown():
	label.start()
	# Accessibility: Announce the spooky text
	if Accessibility:
		Accessibility.speak(text, true)

func grab_focus():
	label.grab_focus()

func _unhandled_input(event):
	if not MenuHelper.is_in_top_menu(self):
		return
	if (event is InputEventMouseButton and event.pressed and event.button_index == 1) or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("fast_mode"):
		if label.finished:
			choose_option(null)
		else:
			label.finish()

func _on_SpookyDialog_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if label.finished:
			choose_option(null)
		else:
			label.finish()

func _on_RichTypeOutLabel_typed_out():
	if UserSettings.show_timer and Input.is_action_pressed("fast_mode"):
		choose_option(null)
