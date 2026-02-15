extends PanelContainer

const CELL_SIZE = Vector2(48, 48)
const COLOR_BUFF: Color = Color(1069260799)
const COLOR_DEBUFF: Color = Color(3070247679)
const COLOR_TRANSMUT: Color = Color(4056045055)
const COLOR_OTHER: Color = Color(4056045055)
const COLOR_NONE: Color = Color.white

const ReactionButton = preload("ReactionButton.gd")

onready var grid = $HBoxContainer / GridContainer
onready var attack_type_label = find_node("AttackTypeLabel")
onready var defend_type_label = find_node("DefendTypeLabel")
onready var result_hint_label = find_node("ResultHintLabel")
onready var status_list_container = find_node("StatusListContainer")

func _ready():
	var types = Datatables.load("res://data/elemental_types/").table.values()
	types.sort_custom(self, "_cmp_type")
	
	
	for type in types:
		var tr = create_type_icon(type)
		tr.size_flags_horizontal = SIZE_EXPAND_FILL
		grid.add_child(tr)
	
	
	for atype in types:
		
		var name_panel = PanelContainer.new()
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = atype.palette[2]
		name_panel.add_stylebox_override("panel", stylebox)
		
		var hbox = HBoxContainer.new()
		name_panel.add_child(hbox)
		
		var label = Label.new()
		label.text = atype.name
		label.size_flags_horizontal = SIZE_EXPAND_FILL
		label.add_font_override("font", preload("res://ui/fonts/regular/regular_30.tres"))
		hbox.add_child(label)
		
		var tr = create_type_icon(atype)
		tr.size_flags_vertical = SIZE_EXPAND_FILL
		hbox.add_child(tr)
		grid.add_child(name_panel)
		
		for dtype in types:
			var btn = ReactionButton.new()
			btn.attack_type = atype
			btn.defense_type = dtype
			btn.rect_min_size = CELL_SIZE
			btn.size_flags_horizontal = SIZE_SHRINK_CENTER
			btn.size_flags_vertical = SIZE_SHRINK_CENTER
			
			btn.connect("focus_entered", self, "_on_reaction_focused", [atype, dtype, btn])
			
			grid.add_child(btn)
	
	grid.initial_focus = grid.get_child(grid.get_child_count() / 2).get_path()
	grid.setup_focus()

func create_type_icon(type: ElementalType) -> TextureRect:
	var result = TextureRect.new()
	result.texture = type.icon
	result.expand = true
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.hint_tooltip = type.name
	result.rect_min_size = CELL_SIZE
	return result

func _cmp_type(a: ElementalType, b: ElementalType):
	return a.sort_order < b.sort_order

func grab_focus():
	grid.grab_focus()

func _on_reaction_focused(atype: ElementalType, dtype: ElementalType, btn: ReactionButton):
	attack_type_label.text = atype.name
	attack_type_label.add_color_override("font_color", atype.palette[4])

	defend_type_label.text = dtype.name
	defend_type_label.add_color_override("font_color", dtype.palette[4])

	for child in status_list_container.get_children():
		status_list_container.remove_child(child)
		child.queue_free()

	# Accessibility: Build announcement
	var accessibility_announcement = Loc.tr(atype.name) + " attacking " + Loc.tr(dtype.name) + ". "

	if btn.reaction == null:
		result_hint_label.text = "TYPE_CHART_NO_REACTION"
		result_hint_label.add_color_override("font_color", Color.white)
		accessibility_announcement += "No reaction."
	else:

		if btn.reaction.result_hint == ElementalReaction.ResultHint.NEGATIVE:
			result_hint_label.text = "TYPE_CHART_DEBUFFS"
			result_hint_label.add_color_override("font_color", COLOR_DEBUFF)
			accessibility_announcement += "Debuffs: "
		elif btn.reaction.result_hint == ElementalReaction.ResultHint.POSITIVE:
			result_hint_label.text = "TYPE_CHART_BUFFS"
			result_hint_label.add_color_override("font_color", COLOR_BUFF)
			accessibility_announcement += "Buffs: "
		elif btn.reaction.result_hint == ElementalReaction.ResultHint.TRANSMUTATION:
			result_hint_label.text = "TYPE_CHART_TRANSMUTATION"
			result_hint_label.add_color_override("font_color", COLOR_TRANSMUT)
			accessibility_announcement += "Transmutation: "
		else:
			result_hint_label.text = "TYPE_CHART_OTHER"
			result_hint_label.add_color_override("font_color", COLOR_OTHER)
			accessibility_announcement += "Other: "

		for i in range(btn.reaction.result.size()):
			var effect = btn.reaction.result[i] as StatusEffect
			var amount = btn.reaction.varied_result_amount[i] if i < btn.reaction.varied_result_amount.size() else btn.reaction.default_result_amount

			var tr = TextureRect.new()
			tr.texture = effect.icon
			tr.expand = true
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.rect_min_size = CELL_SIZE
			status_list_container.add_child(tr)

			var name_label = Label.new()
			name_label.text = effect.name
			name_label.size_flags_horizontal = SIZE_EXPAND_FILL
			status_list_container.add_child(name_label)

			var amount_label = Label.new()
			amount_label.text = Loc.trf("TYPE_CHART_STATUS_AMOUNT", {
				amount = amount
			})
			status_list_container.add_child(amount_label)

			# Add to accessibility announcement
			accessibility_announcement += Loc.tr(effect.name) + " for " + str(amount) + " turns. "

	# Accessibility: Speak the reaction info
	if Accessibility:
		Accessibility.speak(accessibility_announcement, true)
