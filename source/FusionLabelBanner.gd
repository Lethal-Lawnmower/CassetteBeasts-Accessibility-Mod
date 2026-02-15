extends PanelContainer

onready var animation_player = $Sprite / AnimationPlayer
onready var title_label = $MarginContainer / TitleLabel

func _ready():
	visible = false

func show_banner(fusion_name: String):
	title_label.text = fusion_name
	if not visible:
		animation_player.play("Animation")
		animation_player.advance(0.0)
		visible = true
		title_label.visible = true
	$AudioStreamPlayer.play()

	# Accessibility: Announce fusion
	if Accessibility:
		Accessibility.speak("Fusion: " + fusion_name, true)

func hide_banner():
	animation_player.play_backwards("Animation")
	animation_player.advance(0.0)
	Co.delayed(0.1, Bind.new(title_label, "set_visible", [false]))
	yield(animation_player, "animation_finished")
	visible = false
