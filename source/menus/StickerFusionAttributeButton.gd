extends Button

var font_color_override = null setget set_font_color_override
var base_sticker: StickerItem setget set_base_sticker

var _move: BattleMove
var _attribute: StickerAttribute

func _ready() -> void :
	connect("pressed", self, "update_ui")
	connect("focus_entered", self, "_on_focus_entered_accessibility")

func _on_focus_entered_accessibility():
	if not Accessibility or not _attribute:
		return

	var announcement = Loc.tr(_attribute.name) if _attribute.name else "Attribute"

	# Indicate if incompatible
	var incompatible = false
	if base_sticker and base_sticker.get_modified_move() != _move:
		incompatible = not StickerAttribute.is_compatible_with(_attribute, base_sticker.battle_move)

	if incompatible:
		announcement += ", incompatible with base sticker"
	elif pressed:
		announcement += ", selected"
	else:
		announcement += ", not selected"

	Accessibility.speak(announcement, true)

func set_font_color_override(value) -> void :
	font_color_override = value
	update_ui()

func set_base_sticker(value: StickerItem) -> void :
	base_sticker = value
	update_ui()

func set_attribute(move, attribute):
	_move = move
	_attribute = attribute
	update_ui()

func update_ui() -> void :
	$"%Label".font_color_override = font_color_override
	$"%Label".set_attribute(_move, _attribute)
	
	var incompatible: bool = false
	if base_sticker and base_sticker.get_modified_move() != _move:
		incompatible = not StickerAttribute.is_compatible_with(_attribute, base_sticker.battle_move)
	$"%Incompatible".visible = incompatible
	set_disabled(incompatible)

