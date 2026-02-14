extends Control

signal option_chosen(value)
signal tape_switched(tape, index)

const MoveButton = preload("res://battle/ui/MoveButton.tscn")
const PartyStickerActionButtons = preload("res://menus/party_tape/PartyStickerActionButtons.tscn")

export (Color) var regular_heading_color: Color
export (Color) var bootleg_heading_color: Color

onready var tape_name_label = find_node("TapeNameLabel")
onready var grade_stars = find_node("GradeStars")
onready var type_labels = find_node("TypeLabels")
onready var ap_bar = find_node("APBar")
onready var hp_bar = find_node("HPBar")
onready var sprite_container = find_node("MonsterSpriteContainer")
onready var stat_hex = find_node("StatHex")
onready var stickers = find_node("Stickers")
onready var move_info_panel = find_node("MoveInfoPanel")
onready var favorite_icon = find_node("FavoriteIcon")
onready var buttons = find_node("Buttons")
onready var stickers_btn = find_node("StickersBtn")
onready var favorite_btn = find_node("FavoriteBtn")
onready var bestiary_btn = find_node("BestiaryBtn")
onready var use_item_btn = find_node("UseItemBtn")
onready var rename_btn = find_node("RenameBtn")
onready var sticker_actions_parent = find_node("StickerActionsParent")
onready var sticker_focus_indicator = find_node("StickerFocusIndicator")
onready var exp_bar = find_node("ExpBar")
onready var heading_panels = [
	find_node("HeadingPanel1"), 
	find_node("HeadingPanel2"), 
	find_node("HeadingPanel3"), 
]

var is_trade: bool = false
var battle = null
var applying_sticker: StickerItem = null
var swapping_sticker_button = null
var tape: MonsterTape setget set_tape
var tape_collection: Array
var current_sticker_button = null
var current_sprite_tape = null

func _ready():
	for child in stickers.get_children():
		stickers.remove_child(child)
		child.queue_free()
	move_info_panel.move = null
	
	if applying_sticker:
		buttons.hide()
	
	update_ui()
	
	if battle or is_trade:
		stickers_btn.text = "UI_PARTY_VIEW_MOVES"
		
		buttons.remove_child(use_item_btn)
		use_item_btn.queue_free()
		use_item_btn = null
	
	if is_trade:
		buttons.remove_child(rename_btn)
		rename_btn.queue_free()
		rename_btn = null
		buttons.remove_child(favorite_btn)
		favorite_btn.queue_free()
		favorite_btn = null
	
	buttons.setup_focus()
	buttons.visible = false

func choose_option(value):
	buttons.visible = false
	move_info_panel.move = null
	emit_signal("option_chosen", value)

func cancel():
	choose_option(null)

func grab_focus():
	if applying_sticker:
		stickers.grab_focus()
	else:
		buttons.visible = true
		buttons.grab_focus()

func shown():
	var co = MenuHelper.prompt_tutorial("stickers", false)
	if co is GDScriptFunctionState:
		var focus_owner = get_focus_owner()
		if focus_owner:
			focus_owner.release_focus()
		Controls.set_disabled(self, true)
		yield(co, "completed")
		Controls.set_disabled(self, false)
		assert (focus_owner)
		if focus_owner:
			focus_owner.grab_focus()

func set_tape(value: MonsterTape):
	tape = value
	if sticker_focus_indicator:
		sticker_focus_indicator.visible = false
	if buttons and not buttons.has_focus():
		buttons.visible = false
	update_ui()
	# Accessibility: Announce tape info when changed
	call_deferred("_announce_tape_info")

func switch_tape(direction: int):
	if applying_sticker:
		return
	var index = tape_collection.find(tape)
	if index == - 1:
		return
	index = posmod(index + direction, tape_collection.size())
	set_tape(tape_collection[index])
	emit_signal("tape_switched", tape, index)

func update_ui():
	if tape_name_label and tape:
		var bootleg = tape.type_override.size() > 0
		for heading_panel in heading_panels:
			heading_panel.get_stylebox("panel").bg_color = bootleg_heading_color if bootleg else regular_heading_color
		
		tape_name_label.text = tape.get_name()
		grade_stars.set_grade(tape.grade)
		type_labels.tape = tape
		var form = tape.create_form()
		ap_bar.value = form.max_ap
		ap_bar.max_value = form.max_ap
		if current_sprite_tape != tape:
			sprite_container.set_form(form)
			current_sprite_tape = tape
		stat_hex.set_stats_for(null, tape)
		
		if favorite_btn:
			favorite_btn.text = "UI_TAPE_COLLECTION_UNFAVORITE" if tape.favorite else "UI_TAPE_COLLECTION_FAVORITE"
		favorite_icon.visible = tape.favorite
		
		hp_bar.set_tape(tape)
		
		exp_bar.set_max_exp_points(tape.get_exp_to_next_grade())
		exp_bar.set_exp_points(tape.exp_points)
		
		var sticker_slots = tape.get_max_stickers()
		while stickers.get_child_count() > sticker_slots:
			var button = stickers.get_child(stickers.get_child_count() - 1)
			var focus = button.has_focus()
			stickers.remove_child(button)
			button.queue_free()
			if focus:
				if stickers.get_child_count() > 0:
					stickers.get_child(0).grab_focus()
				else:
					stickers.grab_focus()
			if current_sticker_button == button:
				if stickers.get_child_count() > 0:
					current_sticker_button = stickers.get_child(0)
				else:
					current_sticker_button = null
		
		while stickers.get_child_count() < sticker_slots:
			var button = MoveButton.instance()
			button.show_type_icon = true
			button.connect("focus_entered", self, "_on_MoveButton_focus_entered", [button])
			button.connect("pressed", self, "_on_MoveButton_pressed", [button])
			stickers.add_child(button)
		
		for i in range(sticker_slots):
			var sticker = tape.stickers[i] if i < tape.stickers.size() else null
			var button = stickers.get_child(i)
			button.battle = battle
			button.tape = tape
			assert (sticker is StickerItem or sticker is BattleMove or sticker == null)
			button.move = sticker.get_modified_move() if sticker is StickerItem else sticker
		
		stickers.setup_focus()
		
		if stickers.has_focus():
			
			
			
			stickers.grab_focus()

func _on_MoveButton_focus_entered(button):
	current_sticker_button = button
	move_info_panel.fighter_types = tape.get_types()
	move_info_panel.move = button.move
	move_info_panel.rect_min_size.y = max(move_info_panel.rect_min_size.y, move_info_panel.rect_size.y)

func _on_MoveButton_pressed(button):
	current_sticker_button = button
	if battle or is_trade:
		return
	
	if swapping_sticker_button != null:
		tape.swap_stickers(swapping_sticker_button.get_index(), current_sticker_button.get_index())
		swapping_sticker_button.modulate.a = 1.0
		swapping_sticker_button = null
		update_ui()
		return
	
	var buttons = PartyStickerActionButtons.instance()
	buttons.applying_sticker = applying_sticker
	buttons.tape = tape
	buttons.sticker_index = button.get_index()
	sticker_actions_parent.add_child(buttons)
	buttons.connect("option_chosen", self, "_on_ActionButtons_option_chosen")
	buttons.grab_focus()
	stickers.focus_on_hover = false

func _on_ActionButtons_option_chosen(option):
	current_sticker_button.release_focus()
	
	if option == "move_sticker" and current_sticker_button:
		swapping_sticker_button = current_sticker_button
		swapping_sticker_button.modulate.a = 0.5
		current_sticker_button.grab_focus()
		return
	
	if option == "peel_sticker" and current_sticker_button:
		yield(peel_sticker(current_sticker_button.get_index()), "completed")
		if current_sticker_button:
			current_sticker_button.grab_focus()
		return
	
	if option == "apply_sticker" and current_sticker_button:
		var co = apply_sticker(current_sticker_button.get_index())
		if co is GDScriptFunctionState:
			yield(co, "completed")
		current_sticker_button.grab_focus()
		return
	
	stickers.focus_on_hover = true
	if current_sticker_button:
		current_sticker_button.grab_focus()
	else:
		stickers.grab_focus()

func peel_sticker(index: int, replacement: StickerItem = null):
	assert (replacement == null or replacement is StickerItem)
	var sticker = tape.peel_sticker(index, replacement == null)
	if sticker == null:
		return Co.pass()
	if replacement:
		assert (tape.stickers[index] == null)
		tape.insert_sticker(index, replacement)
	
	var msg_key = "UI_PARTY_STICKER_PEELED"
	
	var left_over = SaveState.inventory.add_item(sticker, 1)
	if left_over > 0:
		msg_key = "UI_PARTY_STICKER_PEELED_DROPPED"
		WorldSystem.drop_item(sticker, left_over)
	
	GlobalMessageDialog.clear_state()
	var co = GlobalMessageDialog.show_message(Loc.trf(msg_key, {
		"move_name": sticker.name
	}))
	
	update_ui()
	return co

func apply_sticker(index: int):
	if applying_sticker != null:
		if index < tape.stickers.size() and tape.stickers[index] != null:
			assert (tape.sticker_can_be_replaced(index))
			var message = Loc.trf("UI_PARTY_REPLACE_STICKER_CONFIRM", {
				"old_move": tape.stickers[index].name, 
				"new_move": applying_sticker.name
			})
			if not yield(MenuHelper.confirm(message), "completed"):
				current_sticker_button.grab_focus()
				return
			yield(peel_sticker(index, applying_sticker), "completed")
		else:
			tape.insert_sticker(index, applying_sticker)
		update_ui()
		choose_option(true)
		return
	
	var result = yield(MenuHelper.show_inventory(tape, ["stickers"], false), "completed")
	if result != null:
		assert (result.item.item is StickerItem)
		if index < tape.stickers.size() and tape.stickers[index] != null:
			yield(peel_sticker(index, result.item.item), "completed")
		else:
			tape.insert_sticker(index, result.item.item)
		result.item.consume(1)
	update_ui()

func _unhandled_input(event):
	if not MenuHelper.is_in_top_menu(self):
		return
	var focus_owner = get_focus_owner()
	var stickers_owns_focus = focus_owner and (focus_owner == stickers or stickers.is_a_parent_of(focus_owner))
	if event.is_action_pressed("ui_cancel"):
		if swapping_sticker_button != null:
			swapping_sticker_button.modulate.a = 1.0
			swapping_sticker_button = null
			accept_event()
		elif stickers_owns_focus:
			if buttons.visible:
				buttons.grab_focus()
			else:
				cancel()
			accept_event()
		else:
			cancel()
			accept_event()

	if not stickers_owns_focus:
		if event.is_action_pressed("ui_page_up"):
			switch_tape( - 1)
			accept_event()
		elif event.is_action_pressed("ui_page_down"):
			switch_tape(1)
			accept_event()

func _on_StickersButton_pressed():
	stickers.grab_focus()

func _on_FavoriteBtn_pressed():
	tape.favorite = not tape.favorite
	SaveState.tape_collection.update_favorite(tape)
	update_ui()

func _on_BestiaryBtn_pressed():
	Controls.set_disabled(self, true)
	yield(MenuHelper.show_bestiary(false, tape.form), "completed")
	Controls.set_disabled(self, false)
	bestiary_btn.grab_focus()

func _on_UseItemBtn_pressed():
	Controls.set_disabled(self, true)
	yield(MenuHelper.party_tape_use_item(tape), "completed")
	Controls.set_disabled(self, false)
	update_ui()
	use_item_btn.grab_focus()

func _on_RenameButton_pressed():
	Controls.set_disabled(self, true)
	var title = Loc.trf("UI_PARTY_RENAME_TAPE_TITLE", tape.get_name())
	var default_text = tr(tape.get_name())
	var new_name = yield(MenuHelper.show_text_input(title, default_text, 0, MonsterTape.MAX_NAME_WIDTH), "completed")
	Controls.set_disabled(self, false)
	if new_name != null:
		assert (new_name is String)
		tape.set_name_override(new_name)
		update_ui()
	rename_btn.grab_focus()

func _announce_tape_info():
	if not Accessibility or tape == null:
		return

	var tape_name = tape.get_name() if tape.has_method("get_name") else "Unknown"
	var form = tape.create_form() if tape.has_method("create_form") else null

	var announcement = tape_name

	# Species name if different
	if form and "name" in form:
		var species_name = Loc.tr(form.name)
		if species_name != tape_name:
			announcement += ", " + species_name

	# Types
	var types = tape.get_types() if tape.has_method("get_types") else []
	if types.size() > 0:
		announcement += ", "
		for i in range(types.size()):
			if i > 0:
				announcement += " and "
			if types[i] and "name" in types[i]:
				announcement += Loc.tr(types[i].name)
		announcement += " type"

	# Grade
	if tape.grade > 0:
		announcement += ", grade " + str(tape.grade)

	# HP status
	if tape.has_method("is_broken") and tape.is_broken():
		announcement += ", broken"
	elif "hp" in tape and tape.hp:
		var hp_percent = tape.hp.to_float() * 100
		if hp_percent < 100:
			announcement += ", " + str(int(hp_percent)) + " percent HP"

	# Bootleg status
	if tape.type_override.size() > 0:
		announcement += ", bootleg"

	# Sticker count
	var sticker_count = 0
	for sticker in tape.stickers:
		if sticker != null:
			sticker_count += 1
	var max_stickers = tape.get_max_stickers() if tape.has_method("get_max_stickers") else 0
	announcement += ", " + str(sticker_count) + " of " + str(max_stickers) + " stickers"

	Accessibility.speak(announcement, true)
