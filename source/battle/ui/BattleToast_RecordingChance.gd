extends Control

const PERCEPTION_RATIO: float = 0.125

export (float) var start_chance: float = 0.3
export (float) var target_chance: float = 0.6
export (float) var tween_duration: float = 1.0
export (float) var hold_duration: float = 1.0
export (Color) var shadow: Color = Color.black setget set_shadow

onready var texture_progress = $TextureProgress
onready var message_label = $MessageLabel
onready var tween = $Tween

var current_chance: float = 0.3 setget set_current_chance

func _ready():
	rect_size = Vector2()
	set_current_chance(start_chance)

	tween.interpolate_method(self, "set_current_chance", start_chance, target_chance, tween_duration)
	tween.connect("tween_all_completed", self, "_on_tween_completed")
	tween.start()

func _on_tween_completed():
	# Accessibility: Announce final recording chance
	if Accessibility:
		var perceptual_chance = BattleFormulas.get_perceptual_chance(current_chance)
		var percent = int(round(perceptual_chance * 100.0))
		Accessibility.speak("Recording chance: " + str(percent) + " percent", true)

func set_current_chance(value: float):
	current_chance = value
	
	var perceptual_chance = BattleFormulas.get_perceptual_chance(current_chance)
	if texture_progress:
		texture_progress.value = perceptual_chance * texture_progress.max_value
		message_label.text = Loc.trf("BATTLE_TOAST_RECORD_CHANCE", [int(round(perceptual_chance * 100.0))])

func set_shadow(value: Color):
	shadow = value
	if message_label:
		message_label.add_color_override("font_color_shadow", value)
