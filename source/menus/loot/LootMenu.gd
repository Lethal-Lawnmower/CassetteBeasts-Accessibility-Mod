extends "res://menus/BaseMenu.gd"

const ItemButton = preload("../inventory/ItemButton.tscn")
const LootHeading = preload("LootHeading.tscn")

onready var item_buttons = find_node("ItemButtons")
onready var item_info_panel = find_node("ItemInfoPanel")
onready var audio_stream_player = $AudioStreamPlayer
onready var equip_button = find_node("EquipButton")

var items: Array
var current_button: Button
var current_item_data = null

func _ready():
	if SceneManager.current_scene == self:
		items = [
			{item = ItemFactory.create_sticker(preload("res://data/battle_moves/smack.tres"), null, BaseItem.Rarity.RARITY_UNCOMMON), amount = 1, tape = preload("res://data/test_tapes/player_traffikrab_0.tres"), sticker_index = - 1}, 
			{item = ItemFactory.create_sticker(preload("res://data/battle_moves/spit.tres"), null, BaseItem.Rarity.RARITY_RARE), amount = 1, tape = preload("res://data/test_tapes/player_traffikrab_5_plant.tres")}, 
			{item = preload("res://data/items/fused_material.tres"), amount = 1}, 
			{item = preload("res://data/items/metal.tres"), amount = 10}, 
			{item = preload("res://data/items/plastic.tres"), amount = 53}, 
			{item = preload("res://data/items/wood.tres"), amount = 245}, 
			{item = preload("res://data/items/wheat.tres"), amount = 123}, 
			{item = preload("res://data/items/pulp.tres"), amount = 3}
		]
	setup_buttons()

func add_item(item: LootRecord):
	items.push_back(item)

func setup_buttons():
	for child in item_buttons.get_children():
		item_buttons.remove_child(child)
		child.queue_free()
	
	var tapes = []
	var tape_items = {}
	var inventory_items = []
	var dropped_items = []
	var category_items = {}
	
	for item in items:
		if item.get("tape"):
			if not tapes.has(item.tape):
				tapes.push_back(item.tape)
				tape_items[item.tape] = []
			tape_items[item.tape].push_back(item)
		elif item.get("dropped"):
			dropped_items.push_back(item)
		elif item.get("category"):
			if not category_items.has(item.category):
				category_items[item.category] = []
			category_items[item.category].push_back(item)
		else:
			inventory_items.push_back(item)
	
	for tape in tapes:
		add_tape_heading(tape)
		for item in tape_items[tape]:
			add_button(item)
	
	for key in category_items.keys():
		add_heading(key)
		for item in category_items[key]:
			add_button(item)
	
	if tapes.size() > 0 and inventory_items.size() > 0 or category_items.size() > 0:
		add_heading("LOOT_HEADING_OTHER_ITEMS")
	
	for item in inventory_items:
		add_button(item)
	
	if dropped_items.size() > 0:
		add_heading("LOOT_HEADING_DROPPED")
	
	for item in dropped_items:
		add_button(item)
	
	item_buttons.setup_focus()

func add_heading(title: String):
	var heading = LootHeading.instance()
	heading.text = title
	item_buttons.add_child(heading)

func add_tape_heading(tape: MonsterTape):
	var heading = LootHeading.instance()
	heading.text = tape.get_name()
	heading.stars = tape.grade
	item_buttons.add_child(heading)

func add_button(item):
	var button = ItemButton.instance()
	button.item = item.item
	button.amount = item.amount
	var sticker_index = item.get("sticker_index")
	if sticker_index == null:
		sticker_index = - 1
	button.equipped_to = item.get("tape") if sticker_index >= 0 else null
	button.is_dropped = item.get("dropped") == true
	item_buttons.add_child(button)
	button.connect("focus_entered", self, "_on_button_focused", [button, item])
	button.connect("pressed", self, "_on_EquipButton_pressed")
	
	if not current_button:
		_on_button_focused(button, item)

func display():
	yield(.display(), "completed")
	play_item_get_jingle()
	# Accessibility: Announce items obtained
	call_deferred("_announce_loot")

func play_item_get_jingle():
	MusicSystem.mute = true
	audio_stream_player.play()
	yield(Co.safe_wait_for_audio(self, audio_stream_player), "completed")
	MusicSystem.mute = false

func _exit_tree():
	MusicSystem.mute = false

var _current_tape = null

func _on_EquipButton_pressed():
	var button = current_button
	var item_data = current_item_data
	if not button or not item_data:
		return
	
	var tape = item_data.get("tape")
	if tape:
		assert (item_data.amount == 1)
		if item_data.amount != 1:
			return
		
		var sticker_index = item_data.get("sticker_index")
		if sticker_index == null or sticker_index == - 1:
			
			if not tape.try_add_sticker(item_data.item):
				Controls.set_disabled(self, true)
				
				yield(Co.wait_frames(2), "completed")
				yield(MenuHelper.party_apply_sticker_to_tape(tape, item_data.item), "completed")
				Controls.set_disabled(self, false)
			button.grab_focus()
			sticker_index = tape.stickers.find(item_data.item)
			if sticker_index == - 1:
				return
			button.equipped_to = item_data.tape
			item_data.sticker_index = sticker_index
			SaveState.inventory.consume_item(item_data.item)
			
		else:
			
			assert (tape.get_sticker(item_data.sticker_index) == item_data.item)
			if tape.get_sticker(item_data.sticker_index) != item_data.item:
				return
			var peeled = tape.peel_sticker(item_data.sticker_index)
			if peeled == null:
				return
			var left_over = SaveState.inventory.add_item(item_data.item, item_data.amount)
			if left_over > 0:
				GlobalMessageDialog.passive_message.show_message("ITEM_DROP_INVENTORY_FULL")
				tape.insert_sticker(item_data.sticker_index, item_data.item)
			else:
				item_data.sticker_index = - 1
				button.equipped_to = null
			
	_on_button_focused(button, item_data)

func _on_button_focused(button, item_data):
	current_button = button
	current_item_data = item_data
	item_info_panel.item = button.item
	item_info_panel.amount = button.amount
	if item_data.get("tape"):
		equip_button.set_visible_override(null)
		var sticker_index = item_data.get("sticker_index")
		if sticker_index == null or sticker_index == - 1:
			equip_button.set_text("LOOT_ITEM_EQUIP_BUTTON")
		else:
			equip_button.set_text("LOOT_ITEM_UNEQUIP_BUTTON")
	else:
		equip_button.set_visible_override(false)
	if _current_tape != item_data.get("tape"):
		_current_tape = item_data.get("tape")
		item_info_panel.set_monster_form(_current_tape.create_form() if _current_tape else null)

func grab_focus():
	item_buttons.grab_focus()

func _unhandled_input(event):
	if not visible or GlobalUI.is_input_blocked() or not MenuHelper.is_in_top_menu(self):
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		cancel()
		get_tree().set_input_as_handled()

func _announce_loot():
	if not Accessibility or items.size() == 0:
		return

	var announcement = "Items obtained: "
	var item_count = 0
	for item in items:
		if item_count > 0:
			announcement += ", "
		if item_count >= 5:
			announcement += "and " + str(items.size() - item_count) + " more"
			break
		var item_name = Loc.tr(item.item.name) if item.item else "Unknown"
		if item.amount > 1:
			announcement += str(item.amount) + " " + item_name
		else:
			announcement += item_name
		if item.get("dropped"):
			announcement += " (dropped)"
		item_count += 1

	Accessibility.speak(announcement, true)
