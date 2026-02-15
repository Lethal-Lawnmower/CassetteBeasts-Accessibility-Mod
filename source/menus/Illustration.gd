extends Control

signal finished

export (Resource) var illustration: Resource setget set_illustration
export (int, "Item Zoom", "Fade") var animation: int = 0
export (AudioStream) var audio: AudioStream
export (bool) var mute_music: bool = true
export (float) var duration: float = 5.0

onready var background = $Background
onready var foreground = $Foreground
onready var foreground_texture = $Foreground / Texture
onready var foreground_tape = $Foreground / Tape
onready var animation_player = $AnimationPlayer
onready var audio_stream_player = $AudioStreamPlayer

var t: float = 0.0
var is_finished: bool = false
var other_node: Node = null

func _ready():
	set_illustration(illustration)
	
	audio_stream_player.stream = audio
	
	if SceneManager.current_scene == self:
		run_menu()

func set_illustration(value: Resource):
	if value is MonsterForm:
		var form = value
		value = MonsterTape.new()
		value.form = form
	
	illustration = value
	
	if not foreground_tape:
		return
	
	if other_node:
		other_node.queue_free()
		other_node = null
	
	if illustration is PackedScene:
		other_node = illustration.instance()
		foreground_texture.add_child(other_node)
		foreground_texture.rect_size = Vector2()
		foreground_texture.rect_position = Vector2()
		foreground_tape.visible = false
		foreground_texture.visible = true
		foreground_texture.texture = null
	elif illustration is MonsterTape:
		foreground_tape.tape = illustration
		foreground_tape.visible = true
		foreground_texture.visible = false
	else:
		assert (illustration is Texture)
		foreground_texture.texture = illustration
		foreground_texture.rect_position = - illustration.get_size() / 2.0
		foreground_texture.visible = true
		foreground_tape.visible = false

func run_menu():
	yield(display(), "completed")
	if not is_finished:
		yield(self, "finished")
	yield(hide(), "completed")

func display():
	if mute_music:
		MusicSystem.mute = true
	yield(play_show_animation(), "completed")
	grab_focus()

func hide():
	var result = play_hide_animation()
	if mute_music:
		MusicSystem.mute = false
	return result

func get_show_hide_anim() -> String:
	return "show_item" if animation == 0 else "show_fade"

func play_show_animation():
	if audio_stream_player.stream:
		audio_stream_player.play()
	animation_player.play(get_show_hide_anim())
	animation_player.seek(0.0, true)

	# Accessibility: Announce what is being shown
	if Accessibility:
		var announcement = "Illustration"
		if illustration is MonsterTape:
			var tape_name = illustration.get_name() if illustration.has_method("get_name") else ""
			if tape_name != "":
				announcement = tape_name
		Accessibility.speak(announcement, true)

	yield(animation_player, "animation_finished")

func play_hide_animation():
	animation_player.play_backwards(get_show_hide_anim())
	animation_player.seek(animation_player.current_animation_length - 0.01, true)
	yield(animation_player, "animation_finished")
	if audio_stream_player.is_playing():
		audio_stream_player.stop()

func finish():
	is_finished = true
	emit_signal("finished")

func _process(delta):
	t += delta
	
	if not is_finished and t >= duration - 1.0 and ( not audio or t >= audio.get_length()):
		finish()

func _unhandled_input(event):
	if GlobalMessageDialog.message_dialog.visible or is_finished:
		return
	if not MenuHelper.is_in_top_menu(self):
		return
	if event.is_action_pressed("ui_cancel"):
		finish()
