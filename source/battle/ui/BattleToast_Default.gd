extends Control

const COLOR_HEAL: Color = Color(1069260799)
const COLOR_BUFF: Color = Color(1069260799)
const COLOR_DEBUFF: Color = Color(3070247679)
const COLOR_OTHER_STATUS: Color = Color(4056045055)
const COLOR_AP_UP: Color = Color(4068623871)
const COLOR_AP_DOWN: Color = Color(2031882495)

export (Color) var text_color: Color = Color.white
export (String) var number_text: String = ""
export (String) var message: String = ""
export (Texture) var icon: Texture
export (Color) var shadow: Color = Color.black setget set_shadow

onready var damage_label = find_node("DamageLabel")
onready var texture_rect = find_node("TextureRect")
onready var message_label = find_node("MessageLabel")

func _ready():
	if number_text != "":
		damage_label.visible = true
		damage_label.text = number_text
		damage_label.add_color_override("font_color", text_color)
	else:
		damage_label.visible = false
	
	message_label.text = message
	message_label.add_color_override("font_color", text_color)
	message_label.visible = message != ""
	
	texture_rect.texture = icon
	texture_rect.visible = icon != null
	
	rect_size = Vector2()
	
	set_shadow(shadow)

func _format_number(x: int) -> String:
	return ("+" if x > 0 else "") + str(x)

func setup_damage(damage: Damage):
	number_text = _format_number( - damage.damage)

	var scale_amt = clamp(abs(damage.damage) / 100.0, 0.0, 1.0)
	var scale = lerp(0.75, 1.5, scale_amt * scale_amt)
	rect_scale = Vector2(scale, scale)

	if damage.toast_message != "":
		message = damage.toast_message
	elif damage.is_critical:
		message = "BATTLE_TOAST_CRIT"

	if damage.types.size() > 0 and damage.types[0].palette.size() > 0:
		text_color = damage.types[0].palette[damage.types[0].palette.size() - 1]

	icon = null
	# Accessibility: Announce damage
	if Accessibility:
		var announcement = str(damage.damage) + " damage"
		if damage.is_critical:
			announcement = "Critical hit! " + announcement
		Accessibility.speak(announcement, false)

func setup_text(text: String, color: Color = Color.white, icon: Texture = null):
	number_text = ""
	message = text
	text_color = color
	self.icon = icon
	# Accessibility: Announce text message (e.g. recording failed, missed, etc.)
	if Accessibility:
		Accessibility.speak(Loc.tr(text), false)

func setup_heal(amount: int):
	number_text = _format_number(amount)
	message = ""
	text_color = COLOR_HEAL
	icon = null
	# Accessibility: Announce healing
	if Accessibility:
		Accessibility.speak("Healed " + str(amount), false)

func setup_ap_delta(ap: int):
	number_text = Loc.trf("BATTLE_TOAST_AP", [_format_number(ap)])
	message = ""
	text_color = COLOR_AP_UP if ap > 0 else COLOR_AP_DOWN
	icon = null
	# Accessibility: Announce AP change
	if Accessibility:
		var change = "gained" if ap > 0 else "lost"
		Accessibility.speak(change + " " + str(abs(ap)) + " A P", false)

func setup_status_effect_added(status_effect_node: Node, toast_message: String = ""):
	var status_effect = status_effect_node.effect
	number_text = toast_message
	message = status_effect_node.get_toast_name()
	if status_effect.is_buff:
		text_color = COLOR_BUFF
	elif status_effect.is_debuff:
		text_color = COLOR_DEBUFF
	else:
		text_color = COLOR_OTHER_STATUS
	icon = status_effect.icon
	# Accessibility: Announce status effect
	if Accessibility:
		var status_type = "buff" if status_effect.is_buff else ("debuff" if status_effect.is_debuff else "status")
		Accessibility.speak(message + ", " + status_type, false)

func set_shadow(value: Color):
	shadow = value
	if damage_label:
		damage_label.add_color_override("font_color_shadow", value)
		message_label.add_color_override("font_color_shadow", value)
