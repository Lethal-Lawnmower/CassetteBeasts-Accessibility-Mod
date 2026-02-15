extends "res://menus/BaseMenu.gd"

export (Resource) var resting_currency: Resource
export (int) var resting_cost: int = 0

onready var buttons = find_node("Buttons")
onready var rest_button = find_node("RestButton")
onready var party_button = find_node("PartyButton")
onready var tape_storage_button = find_node("TapeStorageButton")
onready var inventory_button = find_node("InventoryButton")
onready var currency_scroller = find_node("CurrencyScroller")
onready var currency_box = find_node("CurrencyBox")
onready var resting_cost_label = find_node("RestingCostLabel")

func _ready():
	update_ui()

	buttons.setup_focus()
	GlobalUI.manage_visibility(self)

	# Accessibility: Connect button focus signals
	rest_button.connect("focus_entered", self, "_on_button_focus_accessibility", ["Rest"])
	party_button.connect("focus_entered", self, "_on_button_focus_accessibility", ["Party"])
	tape_storage_button.connect("focus_entered", self, "_on_button_focus_accessibility", ["Tape Storage"])
	inventory_button.connect("focus_entered", self, "_on_button_focus_accessibility", ["Inventory"])

func _on_button_focus_accessibility(button_name: String):
	if not Accessibility:
		return

	var announcement = button_name

	# If rest button and has cost
	if button_name == "Rest" and resting_cost > 0 and resting_currency != null:
		announcement += ", costs " + str(resting_cost) + " " + Loc.tr(resting_currency.name)
		if not SaveState.inventory.has_item(resting_currency, resting_cost):
			announcement += ", cannot afford"

	Accessibility.speak(announcement, true)

func update_ui():
	rest_button.disabled = false
	
	if resting_cost == 0 or resting_currency == null:
		resting_cost_label.visible = false
		currency_scroller.visible = false
	else:
		resting_cost_label.bbcode_text = get_resting_cost_bbcode()
		if not SaveState.inventory.has_item(resting_currency, resting_cost):
			resting_cost_label.add_color_override("default_color", Color.red)
			rest_button.disabled = true
		else:
			resting_cost_label.add_color_override("default_color", Color.black)
		
		currency_scroller.visible = true
		currency_box.set_currencies([resting_currency])

func get_resting_cost_bbcode() -> String:
	var currency_str = resting_currency.name
	if resting_currency.icon:
		var height = resting_cost_label.get_font("normal_font").get_height()
		currency_str = "[font=res://addons/platform/input_icons/bbcode_img_font.tres][img=0x" + str(height) + "]" + resting_currency.icon.resource_path + "[/img][/font]"
	return "[right]" + Loc.trf("ITEM_COST_ELEMENT", {
		currency = currency_str, 
		amount = resting_cost
	}) + "[/right]"

func grab_focus():
	update_ui()
	buttons.grab_focus()

func _unhandled_input(event):
	if GlobalMessageDialog.message_dialog.visible:
		return
	if MenuHelper.is_in_top_menu(self):
		if event.is_action_pressed("ui_cancel"):
			cancel()

func _on_PartyButton_pressed():
	Controls.set_disabled(self, true)
	yield(MenuHelper.show_party(null, true), "completed")
	Controls.set_disabled(self, false)
	party_button.grab_focus()
	update_ui()

func _on_InventoryButton_pressed():
	Controls.set_disabled(self, true)
	yield(MenuHelper.show_inventory(), "completed")
	Controls.set_disabled(self, false)
	inventory_button.grab_focus()
	update_ui()

func _on_TapeStorageButton_pressed():
	Controls.set_disabled(self, true)
	yield(MenuHelper.show_tape_storage(), "completed")
	Controls.set_disabled(self, false)
	tape_storage_button.grab_focus()
	update_ui()

func _on_RestButton_pressed():
	if animation_player.is_playing():
		return
	Controls.set_disabled(self, true)
	if resting_cost != 0 and resting_currency != null:
		if not MenuHelper.consume_item(resting_currency, resting_cost):
			Controls.set_disabled(self, false)
			return
		update_ui()
	choose_option("rest")
