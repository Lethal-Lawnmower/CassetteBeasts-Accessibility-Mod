extends Control

signal canceled
signal tab_switch_request(direction)
signal item_focused(item)
signal item_selected(item)

const CATEGORY_ICONS: Dictionary = {
	misc_bg = preload("res://ui/inventory/category_icons/misc_bg.png"), 
	misc_fg = preload("res://ui/inventory/category_icons/misc_fg.png"), 
	resources_bg = preload("res://ui/inventory/category_icons/resources_bg.png"), 
	resources_fg = preload("res://ui/inventory/category_icons/resources_fg.png"), 
	consumables_bg = preload("res://ui/inventory/category_icons/consumables_bg.png"), 
	consumables_fg = preload("res://ui/inventory/category_icons/consumables_fg.png"), 
	stickers_bg = preload("res://ui/inventory/category_icons/stickers_bg.png"), 
	stickers_fg = preload("res://ui/inventory/category_icons/stickers_fg.png"), 
	tapes_bg = preload("res://ui/inventory/category_icons/tapes_bg.png"), 
	tapes_fg = preload("res://ui/inventory/category_icons/tapes_fg.png"), 
}

const PAGINATE_THRESHOLD: int = 200
const PAGE_SIZE: int = 50

export (NodePath) var items_path: NodePath setget set_items_path

onready var scroll_container = find_node("ScrollContainer")
onready var buttons = find_node("Buttons")
onready var title_label = find_node("TitleLabel")
onready var empty_label = find_node("EmptyLabel")
onready var prev_page_btn = find_node("PrevPageBtn")
onready var next_page_btn = find_node("NextPageBtn")
onready var category_size_limit_label = $"%CategorySizeLimitLabel"

var context = null
var items = null setget set_items
var filtered_items: Array
var filtered_item_indices: Dictionary
var filtered_count: int = 0
var filtered_stacks: int = 0
var items_in_use = null
var inventory_index = - 1 setget set_inventory_index
var focus_index = - 1
var invert_sort = false

var user_filterable: bool = false
var user_filter: = {} setget set_user_filter

var paginated: bool = false
var page_index: int = 0
var page_count: int = 0
var page_start_index: int = 0
var page_end_index: int = 0
var compat_count: int = 0

func _ready():
	if SaveState.inventory.focus_indices.has(name):
		inventory_index = SaveState.inventory.focus_indices[name]
		if inventory_index == 0:
			inventory_index = - 1
	if SaveState.inventory.filters.has(name):
		user_filter = SaveState.inventory.filters[name]
	set_items_path(items_path)
	SaveState.inventory.connect("item_added", self, "_on_inventory_item_added")

func set_inventory_index(value: int):
	if items:
		inventory_index = int(clamp(value, 0, items.get_child_count() - 1))
		SaveState.inventory.focus_indices[name] = inventory_index

func _on_inventory_item_added(_item_node):
	refresh()

func get_tab_icon(foreground: bool) -> Texture:
	if not items:
		return null
	var key = items.name + "_" + ("fg" if foreground else "bg")
	return CATEGORY_ICONS.get(key)

func set_user_filter(value: Dictionary):
	user_filter = value
	SaveState.inventory.filters[name] = user_filter
	if is_inside_tree():
		refresh()

func set_items_path(value: NodePath):
	items_path = value
	if is_inside_tree() and not items_path.is_empty():
		set_items(get_node(items_path))

func set_items(value):
	items = value
	user_filterable = items and items.name == "stickers"
	
	if is_inside_tree():
		refresh()

func _reset_page():
	if not items:
		return
	
	if filtered_items.size() > PAGINATE_THRESHOLD:
		paginated = true
		page_count = (filtered_items.size() + PAGE_SIZE - 1) / PAGE_SIZE
	else:
		paginated = false
		page_count = 1

	if paginated:
		var filtered_inventory_index = filtered_item_indices.get(inventory_index, 0)
		page_index = filtered_inventory_index / PAGE_SIZE
		page_start_index = page_index * PAGE_SIZE
		page_end_index = int(min(page_start_index + PAGE_SIZE, filtered_items.size()))
	else:
		page_index = 0
		page_start_index = 0
		page_end_index = filtered_items.size()

func _is_compatible(item_node: Node) -> bool:
	if context is MonsterTape and item_node.item is StickerItem:
		return BattleMoves.is_compatible(context as MonsterTape, item_node.item.get_modified_move())
	if context is StickerFusionSlot and item_node.item is StickerItem:
		return context.is_compatible(item_node.item)
	return true

func _is_filtered_out(item_node: Node) -> bool:
	if context is MonsterTape:
		if not item_node.is_usable(BaseItem.ContextKind.CONTEXT_TAPE, context):
			return true
	if context is Character:
		if not item_node.is_usable(BaseItem.ContextKind.CONTEXT_CHARACTER, context):
			return true
	
	if user_filter.has("name"):
		var item_name = item_node.get_item_name()
		if item_node.item is StickerItem:
			item_name = item_node.item.battle_move.name
		if Strings.strip_diacritics(tr(item_name).to_lower()).find(user_filter.name) == - 1:
			return true
	
	if user_filter.has("rarity"):
		if item_node.item.get_rarity() != user_filter.rarity:
			return true
	
	if user_filter.has("category"):
		if not (item_node.item is StickerItem):
			return true
		if item_node.item.battle_move.category_name != user_filter.category:
			return true
	
	if user_filter.has("type"):
		if not (item_node.item is StickerItem):
			return true
		var move = item_node.item.battle_move
		if move.elemental_types.size() == 0:
			if user_filter.type != "typeless":
				return true
		else:
			if move.elemental_types[0].id != user_filter.type:
				return true
	
	return false

func refresh(reapply_filter: bool = true):
	if reapply_filter:
		filtered_count = 0
		filtered_stacks = 0
		filtered_items.clear()
		filtered_item_indices.clear()
		var incompatible_items = []
		for item in items.get_children():
			if not _is_filtered_out(item):
				filtered_count += item.amount
				filtered_stacks += 1
				if not _is_compatible(item):
					incompatible_items.push_back(item)
				else:
					filtered_items.push_back(item)
					filtered_item_indices[item.get_index()] = filtered_items.size() - 1
		compat_count = filtered_items.size()
		for item in incompatible_items:
			filtered_items.push_back(item)
			filtered_item_indices[item.get_index()] = filtered_items.size() - 1
	
	_reset_page()
	
	var v_scroll = scroll_container.get_v_scroll()
	
	next_page_btn.visible = paginated and page_index < page_count - 1
	prev_page_btn.visible = paginated and page_index > 0
	
	focus_index = 0
	
	var btn_index = 0
	
	buttons.left_right_as_page_up_down = not paginated
	
	if SaveState.inventory.CATEGORY_SIZE_LIMIT.has(items.name):
		category_size_limit_label.text = Loc.trf("UI_INVENTORY_TAB_CATEGORY_SIZE_LIMIT", {
			stacks = items.get_child_count(), 
			maximum = SaveState.inventory.CATEGORY_SIZE_LIMIT[items.name]
		})
	else:
		category_size_limit_label.text = ""
	
	for i in range(page_start_index, page_end_index):
		var item = filtered_items[i]
		var compat = _is_compatible(item)
		assert ( not _is_filtered_out(item))
		
		if item.amount <= 0:
			continue
		
		var button = _get_btn(btn_index)
		assert (btn_index == button.get_index())
		button.inventory_index = item.get_index()
		button.set_item_node(item, items_in_use)
		button.focus_mode = Control.FOCUS_ALL
		if compat:
			button.modulate.a = 1.0
			button.disabled = false
			button.aux_text_override = ""
		else:
			button.modulate.a = 0.5
			button.disabled = true
			button.aux_text_override = "INVENTORY_INCOMPATIBLE"
		
		if item.get_index() == inventory_index:
			focus_index = btn_index
		btn_index += 1
	
	while buttons.get_child_count() > btn_index:
		var button = buttons.get_child(buttons.get_child_count() - 1)
		buttons.remove_child(button)
		button.queue_free()
	
	var category_name = "ITEM_CATEGORY_" + items.name
	
	if paginated:
		title_label.text = Loc.trf("UI_INVENTORY_TAB_TITLE_PAGED", {
			category = category_name, 
			page = page_index + 1, 
			page_count = page_count
		})
	else:
		title_label.text = Loc.trf("UI_INVENTORY_TAB_TITLE", {
			category = category_name
		})
	
	if context is MonsterTape and items.name == "stickers":
		empty_label.visible = compat_count == 0
		empty_label.text = "INVENTORY_NO_COMPATIBLE_STICKERS"
	else:
		empty_label.visible = btn_index == 0
		empty_label.text = "INVENTORY_EMPTY"
	
	buttons.setup_focus()
	scroll_container.set_v_scroll(v_scroll)

func _get_btn(index: int) -> Button:
	if index >= buttons.get_child_count():
		var button = preload("./InventoryItemButton.tscn").instance()
		button.connect("focus_entered", self, "_on_button_focused", [button])
		button.connect("pressed", self, "_on_button_pressed", [button])
		buttons.add_child(button)
	return buttons.get_child(index)

func grab_focus():
	if items.name == "stickers" and buttons.get_child_count() > 0:
		var co = MenuHelper.prompt_tutorial("stickers", false)
		if co is GDScriptFunctionState:
			yield(co, "completed")
	
	buttons.focus_on_hover = true
	
	if focus_index >= 0 and focus_index < buttons.get_child_count() and buttons.get_child(focus_index).visible:
		buttons.get_child(focus_index).grab_focus()
	else:
		buttons.grab_focus()
		emit_signal("item_focused", null)

func _unhandled_input(event):
	if not MenuHelper.is_in_top_menu(self):
		return
	if buttons.has_focus():
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("inventory_menu"):
			emit_signal("canceled")
			get_tree().set_input_as_handled()

func tab_switch(direction: int):
	emit_signal("tab_switch_request", direction)

func _on_button_focused(button):
	focus_index = button.get_index()
	set_inventory_index(button.inventory_index)
	emit_signal("item_focused", button.item_node)
	# Accessibility: Announce item when focused
	_announce_item_focus(button)

func _on_button_pressed(button):
	if _is_compatible(button.item_node) and not _is_filtered_out(button.item_node) and button.amount > 0:
		emit_signal("item_selected", button.item_node)
		buttons.focus_on_hover = false

func sort():
	var selected_item = null
	if inventory_index >= 0 and inventory_index < items.get_child_count():
		selected_item = items.get_child(inventory_index)
	SaveState.inventory.sort_category(items.name, invert_sort)
	invert_sort = not invert_sort
	if selected_item:
		set_inventory_index(selected_item.get_index())
	refresh()
	grab_focus()

func _on_PrevPageBtn_pressed():
	if paginated and page_index > 0:
		page_index -= 1
		page_start_index -= PAGE_SIZE
		assert (page_start_index >= 0)
		page_end_index = int(min(page_start_index + PAGE_SIZE, items.get_child_count()))
		set_inventory_index(filtered_items[page_start_index].get_index())
		refresh(false)
		grab_focus()

func _on_NextPageBtn_pressed():
	if paginated and page_index < page_count - 1:
		page_index += 1
		page_start_index += PAGE_SIZE
		assert (page_start_index < items.get_child_count())
		page_end_index = int(min(page_start_index + PAGE_SIZE, items.get_child_count()))
		set_inventory_index(filtered_items[page_start_index].get_index())
		refresh(false)
		grab_focus()

func bulk_recycle():
	var recyclables = []
	for item in filtered_items:
		item.recycle(null, recyclables)
	refresh()
	if recyclables.size() > 0:
		yield(MenuHelper.give_items(recyclables), "completed")
	grab_focus()

func _announce_item_focus(button):
	if not Accessibility:
		return

	var item = button.item if "item" in button else null
	if item == null and button.item_node:
		item = button.item_node.item

	if item == null:
		Accessibility.speak("Empty", true)
		return

	var item_name = Loc.tr(item.name) if "name" in item else "Unknown item"
	var amount = button.amount if "amount" in button else 1

	var announcement = item_name

	# Add amount if more than 1
	if amount > 1:
		announcement += ", " + str(amount)

	# Add equipped status
	if "equipped_to" in button and button.equipped_to != null:
		announcement += ", equipped"

	# Add rarity
	if item.has_method("get_rarity"):
		var rarity = item.get_rarity()
		match rarity:
			BaseItem.Rarity.RARITY_UNCOMMON:
				announcement += ", uncommon"
			BaseItem.Rarity.RARITY_RARE:
				announcement += ", rare"
			BaseItem.Rarity.RARITY_ULTRA_RARE:
				announcement += ", ultra rare"

	# Check if this is a sticker and add move info
	if item is StickerItem:
		var move = item.get_modified_move() if item.has_method("get_modified_move") else null
		if move:
			if "cost" in move and not move.is_passive_only:
				announcement += ", " + str(move.cost) + " A P"
			if "elemental_types" in move and move.elemental_types.size() > 0:
				var type_name = move.elemental_types[0].name if move.elemental_types[0] else ""
				if type_name != "":
					announcement += ", " + Loc.tr(type_name) + " type"

	# Add incompatible warning
	if button.disabled:
		announcement += ", incompatible"

	# Add position
	var total = buttons.get_child_count()
	var index = button.get_index()
	announcement += ", " + str(index + 1) + " of " + str(total)

	Accessibility.speak(announcement, true)
