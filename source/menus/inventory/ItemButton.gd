extends Button

export (bool) var display_stack_limits: bool = false

onready var icon_texture = $MarginContainer / HBoxContainer / IconTexture
onready var label = $MarginContainer / HBoxContainer / Label
onready var count_label = $MarginContainer2 / CountLabel

var item: BaseItem = null setget set_item
var amount: int = 1 setget set_amount
var equipped_to = null setget set_equipped_to
var is_dropped: bool = false setget set_is_dropped
var color_override = null
var aux_text_override: = "" setget set_aux_text_override

func _ready():
	refresh()
	# Accessibility: Connect focus signal for TTS announcements
	connect("focus_entered", self, "_on_focus_entered_accessibility")

func set_item(value: BaseItem):
	item = value
	refresh()

func set_amount(value: int):
	amount = value
	refresh()

func set_equipped_to(value):
	equipped_to = value
	if equipped_to != null:
		is_dropped = false
	refresh()

func set_is_dropped(value: bool):
	is_dropped = value
	if is_dropped:
		equipped_to = null
	refresh()

func set_aux_text_override(value: String):
	aux_text_override = value
	refresh()

func refresh():
	if not count_label:
		return
	
	if item == null:
		label.bbcode_text = ""
		icon_texture.texture = null
		count_label.visible = false
	else:
		label.bbcode_text = Loc.tr(item.name)
		icon_texture.texture = item.icon
		
		var stack_limit = SaveState.inventory.get_stack_limit(item)
		
		if aux_text_override != "":
			count_label.visible = true
			count_label.text = aux_text_override
		elif equipped_to != null:
			count_label.visible = true
			count_label.text = "LOOT_ITEM_EQUIPPED"
		elif item.aux_name != "":
			count_label.text = item.aux_name
			count_label.visible = true
		elif display_stack_limits and stack_limit > 0:
			count_label.text = Loc.trf("ITEM_COUNT_LIMITED", [amount, stack_limit])
			count_label.visible = true
		else:
			count_label.text = Loc.trf("ITEM_COUNT", [amount])
			count_label.visible = amount != 1
		
		if item.get_rarity() != BaseItem.Rarity.RARITY_COMMON:
			color_override = BaseItem.get_rarity_color(item.get_rarity())
		else:
			color_override = null
		_set_text_color(color_override)

func _set_text_color(color):
	if color == null:
		color = Color.black
	label.add_color_override("default_color", color)
	count_label.add_color_override("font_color", color)

func on_row_focus_entered():
	_set_text_color(color_override if color_override != null else Color.white)

func on_row_focus_exited():
	_set_text_color(color_override if color_override != null else Color.black)

func _on_focus_entered_accessibility():
	if not Accessibility or item == null:
		return

	var item_name = Loc.tr(item.name)

	# Determine rarity string
	var rarity_str = ""
	var rarity = item.get_rarity() if item.has_method("get_rarity") else BaseItem.Rarity.RARITY_COMMON
	match rarity:
		BaseItem.Rarity.RARITY_UNCOMMON:
			rarity_str = "uncommon"
		BaseItem.Rarity.RARITY_RARE:
			rarity_str = "rare"
		BaseItem.Rarity.RARITY_ULTRA_RARE:
			rarity_str = "ultra rare"

	var is_equipped = equipped_to != null

	Accessibility.announce_item(item_name, amount, is_equipped, rarity_str)
