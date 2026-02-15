extends "res://menus/BaseMenu.gd"

const MoveButton = preload("res://battle/ui/MoveButton.tscn")
const Smack = preload("res://data/battle_moves/smack.tres")

onready var menu = find_node("Menu")
onready var move_buttons = find_node("MoveButtons")
onready var move_info_panel = find_node("MoveInfoPanel")

var battle
var fighter
var current_focus

func _ready():
	move_info_panel.move = null

func setup_moves(battle, fighter):
	self.battle = battle
	self.fighter = fighter

	for child in move_buttons.get_children():
		child.queue_free()
		move_buttons.remove_child(child)

	var i = 0
	var moves = fighter.get_moves().duplicate()

	var usable_moves = 0
	for move in moves:
		if move.cost <= fighter.status.ap and not move.is_passive_only:
			usable_moves += 1
	if usable_moves == 0:
		moves.push_front(Smack)

	var total_moves = moves.size()
	for move in moves:
		var button = MoveButton.instance()
		button.battle = battle
		button.fighter = fighter
		button.move = move
		move_buttons.add_child(button)
		move_buttons.move_child(button, i)
		button.connect("pressed", self, "_on_MoveButton_pressed", [move])
		# Accessibility: Connect focus signal for TTS announcements
		button.connect("focus_entered", self, "_on_MoveButton_focus_entered", [move, i, total_moves])
		i += 1
	move_buttons.setup_focus()

func grab_focus():
	move_buttons.grab_focus()

func _on_MoveButton_pressed(move):
	choose_option(move)

func _process(_delta):
	var focus = get_focus_owner()
	if focus != current_focus:
		current_focus = focus
		if focus != null:
			var move = focus.get("move")
			if move != null:
				update_info_panel(move)
				_speak_move(move, focus)
		else:
			update_info_panel(null)

func _speak_move(move, button):
	if not Accessibility:
		return

	var move_name = Loc.tr(move.name)
	var announcement = move_name

	# AP cost
	if not move.is_passive_only:
		announcement += ", " + str(move.cost) + " A P"
	else:
		announcement += ", passive"

	# Type
	if move.elemental_types.size() > 0 and move.elemental_types[0]:
		announcement += ", " + Loc.tr(move.elemental_types[0].name)

	# Category (melee, ranged, status)
	if move.category_name:
		announcement += ", " + Loc.tr(move.category_name)

	# Power
	if move.power > 0:
		announcement += ", power " + str(move.power)

	# Accuracy (only if not 100%)
	if move.accuracy < 100:
		announcement += ", " + str(move.accuracy) + " percent accuracy"

	# Hits
	var min_hits = move.min_hits if "min_hits" in move and move.min_hits else 1
	var max_hits = move.max_hits if "max_hits" in move and move.max_hits else 1
	if min_hits > 1 or max_hits > 1:
		if min_hits == max_hits:
			announcement += ", " + str(min_hits) + " hits"
		else:
			announcement += ", " + str(min_hits) + " to " + str(max_hits) + " hits"

	# Description
	if move.description and move.description != "":
		announcement += ". " + Loc.tr(move.description)

	# Disabled status
	if button.disabled:
		if move.is_passive_only:
			announcement += ". Cannot use"
		elif fighter and move.cost > fighter.status.ap:
			announcement += ". Not enough A P"

	Accessibility.speak(announcement, true)
	
	
	
	menu.rect_min_size.x = max(menu.rect_min_size.x, menu.rect_size.x)
	menu.rect_min_size.y = max(menu.rect_min_size.y, menu.rect_size.y)

func show():
	current_focus = null
	update_info_panel(null)
	return .show()

func update_info_panel(move):
	move_info_panel.fighter = fighter
	move_info_panel.move = move

func _on_MoveButton_focus_entered(move, index: int, total: int):
	if not Accessibility:
		return
	if move == null:
		Accessibility.speak("Empty slot, " + str(index + 1) + " of " + str(total), true)
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
	var button = move_buttons.get_child(index)
	if button and button.disabled:
		if move.is_passive_only:
			announcement += ", passive only"
		elif fighter and move.cost > fighter.status.ap:
			announcement += ", not enough A P"

	# Add position info
	announcement += ", " + str(index + 1) + " of " + str(total)

	Accessibility.speak(announcement, true)

