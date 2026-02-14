extends Button

var battle = null
var team: int
var slots: Array setget set_slots

func _ready():
	# Accessibility: Connect focus signal for TTS
	connect("focus_entered", self, "_on_focus_entered_accessibility")

func set_slots(value: Array):
	slots = value
	if slots.size() > 0:
		team = slots[0].team
	update_position()

func _process(_delta):
	update_position()

func _calc_position() -> Vector2:
	assert (slots.size() > 0)
	var slot = slots[0]
	var pos = slot.global_transform.xform(slot.get_target_button_position())
	if slot.target_button_at_top:
		grow_vertical = Control.GROW_DIRECTION_BEGIN
	else:
		grow_vertical = Control.GROW_DIRECTION_END
	var camera = battle.background.battle_camera.steady_camera
	return camera.unproject_position(pos)

func update_position():
	if slots.size() > 0:
		var pos = _calc_position()
		var parent = get_parent()
		if parent:
			pos.x = clamp(pos.x, 0, parent.rect_size.x - 0.5 * rect_size.x)
			pos.y = clamp(pos.y, 0.0 if grow_vertical == Control.GROW_DIRECTION_END else rect_size.y, parent.rect_size.y - (rect_size.y if grow_vertical == Control.GROW_DIRECTION_END else 0.0))
		margin_left = pos.x
		margin_right = pos.x
		margin_top = pos.y
		margin_bottom = pos.y

func _on_focus_entered_accessibility():
	if not Accessibility or slots.size() == 0:
		return

	var announcement = ""
	for slot in slots:
		var fighter = slot.get_fighter() if slot.has_method("get_fighter") else null
		if fighter and fighter.has_method("get_name_with_team"):
			if announcement != "":
				announcement += " and "
			announcement += fighter.get_name_with_team()

	if announcement == "":
		announcement = "Target"

	# Indicate if ally or enemy
	if team == 0:
		announcement += ", ally"
	else:
		announcement += ", enemy"

	Accessibility.speak(announcement, true)
