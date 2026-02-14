extends "res://menus/BaseMenu.gd"

export (Resource) var tape: Resource

onready var tape_2d = find_node("Tape2D")
onready var tape_2d_container = find_node("Tape2DContainer")
onready var audio_stream_player = $AudioStreamPlayer

var tape_3d: Spatial

func _ready():
	tape_2d.tape = tape
	tape_2d_container.visible = false

	var camera = get_viewport().get_camera()
	if camera:
		tape_3d = preload("Tape3D.tscn").instance()
		camera.add_child(tape_3d)
		tape_3d.transform.origin.z = - 2.5 / tan(deg2rad(camera.fov / 4.0))
		tape_3d.connect("animation_finished", self, "_on_Tape3D_animation_finished")
	else:
		call_deferred("_on_Tape3D_animation_finished")

	GlobalUI.suppress_dof_blur_near = true

	# Accessibility: Announce the tape obtained
	call_deferred("_announce_tape_obtained")

func _announce_tape_obtained():
	if not Accessibility or tape == null:
		return

	var tape_name = tape.get_name() if tape.has_method("get_name") else ""
	var species_name = ""

	# Get the species/form name
	if tape.has_method("create_form"):
		var form = tape.create_form()
		if form:
			species_name = Loc.tr(form.name) if "name" in form else ""

	if species_name == "":
		species_name = tape_name

	Accessibility.announce_cassette_obtained(tape_name, species_name)

func _exit_tree():
	GlobalUI.suppress_dof_blur_near = false

func grab_focus():
	var owner = get_focus_owner()
	if owner:
		owner.release_focus()

func display():
	MusicSystem.mute = true
	return .display()

func hide():
	MusicSystem.mute = false
	if tape_3d:
		tape_3d.queue_free()
		tape_3d = null
	GlobalUI.suppress_dof_blur_near = false
	return .hide()

func play_hide_animation():
	animation_player.play("hide")
	yield(animation_player, "animation_finished")

func _on_Tape3D_animation_finished():
	animation_player.play("transition_2d")
	yield(animation_player, "animation_finished")
	cancelable = true
	cancel()
