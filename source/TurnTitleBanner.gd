extends Control

onready var background_sprite = $Background / Background / Sprite
onready var background_animation = $Background / Background / AnimationPlayer
onready var labels = $MarginContainer / Labels
onready var fighter_label = $MarginContainer / Labels / FighterLabel
onready var title_label = $MarginContainer / Labels / TitleLabel
onready var failed = $Failed
onready var failed_label = $Failed / FailedLabel
onready var animation_player = $AnimationPlayer

export (float) var shake: float = 0.0

func _ready():
	rect_min_size = background_sprite.get_rect().size
	hide_banner()

func show_banner(fighter: String, title: String):
	failed.visible = false
	fighter_label.text = fighter
	title_label.bbcode_text = "[center]" + Loc.tr(title)
	labels.visible = true
	animation_player.stop()
	shake = 0.0
	if not visible:
		background_animation.play("show")
	visible = true

	# Accessibility: Announce turn action
	if Accessibility:
		Accessibility.speak(fighter + " uses " + Loc.tr(title), true)

func hide_banner():
	if background_animation.is_playing():
		yield(background_animation, "animation_finished")
	failed.visible = false
	labels.visible = false
	animation_player.stop()
	shake = 0.0
	if visible:
		background_animation.play("hide")
	visible = false

func fail_banner(message: String = "BATTLE_FAILED"):
	if not visible:
		return
	failed_label.text = message
	failed_label.rect_size = Vector2.ZERO
	failed_label.rect_position = - failed_label.rect_size * 0.5
	animation_player.play("fail")

	# Accessibility: Announce failure
	if Accessibility:
		Accessibility.speak(Loc.tr(message), true)

	yield(animation_player, "animation_finished")

func _process(_delta: float):
	background_sprite.position = Vector2(rand_range( - 1, 1), rand_range( - 1, 1)) * shake
