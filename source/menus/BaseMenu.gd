extends Control

signal option_chosen(value)

export (bool) var cancelable: bool = true
export (String) var show_hide_anim: String = "show" setget , get_show_hide_anim

onready var blur = $Blur
onready var animation_player = $AnimationPlayer
onready var container = $Scroller
onready var overscan_container = $Scroller / OverscanMarginContainer

func _ready():
	if SceneManager.current_scene == self:
		call_deferred("run_menu")

func run_menu():
	yield(display(), "completed")
	var result = yield(self, "option_chosen")
	yield(hide(), "completed")
	return result

func display():
	Controls.set_disabled(self, true)
	yield(play_show_animation(), "completed")
	Controls.set_disabled(self, false)
	shown()

func shown():
	grab_focus()
	# Accessibility: Announce menu opening
	if Accessibility:
		var menu_name = name.replace("Menu", "").replace("UI", "")
		Accessibility.announce_menu(menu_name)

func grab_focus():
	
	focus_mode = Control.FOCUS_CLICK
	.grab_focus()

func hide():
	Controls.set_disabled(self, true)
	return play_hide_animation()

func get_show_hide_anim() -> String:
	return show_hide_anim

func play_show_animation():
	container.rect_size.y = rect_size.y
	animation_player.play(get_show_hide_anim())
	animation_player.seek(0.0, true)
	yield(animation_player, "animation_finished")
	container.rect_size.y = rect_size.y

func play_hide_animation():
	animation_player.play_backwards(get_show_hide_anim())
	yield(animation_player, "animation_finished")

func cancel():
	choose_option(null)

func choose_option(value):
	if value != null or cancelable:
		emit_signal("option_chosen", value)
