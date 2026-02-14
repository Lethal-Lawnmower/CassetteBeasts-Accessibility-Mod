extends Button

export (bool) var show_type_icon: bool = false

onready var container = $HBoxContainer
onready var ap_bar = find_node("APBar")
onready var passive_label = find_node("PassiveLabel")
onready var icon_spacer = find_node("IconSpacer")
onready var label = find_node("Label")

var fighter
var battle
var move = null setget set_move
var tape = null setget set_tape
var has_valid_targets: bool = false

func _ready():
	set_move(move)
	# Accessibility: Connect focus signal for TTS
	connect("focus_entered", self, "_on_focus_entered_accessibility")

func set_move(value):
	move = value
	update_ui()

func set_tape(value):
	tape = value
	update_ui()

func update_ui():
	if ap_bar:
		if not show_type_icon or not move:
			icon = null
		else:
			var types = move.elemental_types
			if types.size() == 0 and tape:
				types = tape.get_types()
			if types.size() > 0:
				icon = types[0].icon
			else:
				icon = preload("res://ui/icons/types/element_typeless.png")
		
		align = Button.ALIGN_LEFT if move else Button.ALIGN_CENTER
		
		
		label.bbcode_text = Loc.tr(move.name if move else "UI_PARTY_EMPTY_STICKER_SLOT")
		if icon:
			icon_spacer.rect_min_size.x = rect_size.y
		else:
			icon_spacer.rect_min_size.x = 0
		
		ap_bar.value = move.cost if move else 0
		ap_bar.visible = move and not move.is_passive_only
		passive_label.visible = move and move.is_passive_only
		
		var color = BaseItem.get_rarity_color(move.rarity if move else BaseItem.Rarity.RARITY_COMMON)
		label.add_color_override("default_color", color if not disabled else get_color("font_color_disabled"))
		
		if fighter and battle and move:
			has_valid_targets = _check_targets()

func _check_targets() -> bool:
	assert (fighter and battle and move)
	
	if not [BattleMove.TargetType.TARGET_ONE_ALLY_NOT_SELF, BattleMove.TargetType.TARGET_ONE_ENEMY, BattleMove.TargetType.TARGET_ALL_NOT_SELF].has(move.target_type):
		return true
		
	var fighters = battle.get_fighters(false)
	
	if move.target_type == BattleMove.TargetType.TARGET_ONE_ALLY_NOT_SELF:
		for f in fighters:
			if f.team == fighter.team and f != fighter:
				return true
		return false
	
	if move.target_type == BattleMove.TargetType.TARGET_ONE_ENEMY:
		for f in fighters:
			if f.team != fighter.team:
				return true
		return false
	
	if move.target_type == BattleMove.TargetType.TARGET_ALL_NOT_SELF:
		for f in fighters:
			if f != fighter:
				return true
		return false
	
	return true
	

func set_disabled(value: bool):
	.set_disabled(value)
	if label:
		var color = BaseItem.get_rarity_color(move.rarity if move else BaseItem.Rarity.RARITY_COMMON)
		label.add_color_override("default_color", color if not disabled else get_color("font_color_disabled"))

func _process(_delta):
	if fighter != null and not disabled:
		if fighter.status.ap < move.cost or move.is_passive_only or (battle and not has_valid_targets):
			set_disabled(true)

func _on_HBoxContainer_resized():
	if container:
		rect_min_size.x = max(rect_min_size.x, container.rect_size.x)

func _on_focus_entered_accessibility():
	if not Accessibility:
		return
	if move == null:
		Accessibility.speak("Empty slot", true)
		return

	var move_name = Loc.tr(move.name)
	var announcement = move_name

	# Add AP cost if not passive
	if not move.is_passive_only:
		announcement += ", " + str(move.cost) + " A P"

	# Add type if available
	if move.elemental_types.size() > 0:
		var type_name = move.elemental_types[0].name if move.elemental_types[0] else ""
		if type_name != "":
			announcement += ", " + Loc.tr(type_name) + " type"

	# Indicate if disabled/unusable
	if disabled:
		if move.is_passive_only:
			announcement += ", passive only"
		elif fighter and move.cost > fighter.status.ap:
			announcement += ", not enough A P"
		elif not has_valid_targets:
			announcement += ", no valid targets"

	Accessibility.speak(announcement, true)
