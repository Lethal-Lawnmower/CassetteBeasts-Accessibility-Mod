extends Control

signal option_chosen(option)

const COLOR_BUFF: Color = Color(1459571455)
const COLOR_DEBUFF: Color = Color(4282531839)
const COLOR_TRANSMUT: Color = Color(4294923775)
const COLOR_OTHER: Color = Color(4294967295)

const StatusEffectIconNode = preload("res://battle/ui/StatusEffectIconNode.tscn")
const TargetButton = preload("TargetButton.tscn")

onready var icon_container = $IconContainer
onready var target_buttons = $TargetButtonContainer

var battle
var fighter
var move: BattleMove
var item: BaseItem
var current_button = null

func setup_targets_for_move(battle, fighter, move: BattleMove):
	self.battle = battle
	self.fighter = fighter
	self.move = move
	self.item = null
	
	var target_sets = []
	var initial_target_set = []
	
	if move.target_type == BattleMove.TargetType.TARGET_ONE or move.target_type == BattleMove.TargetType.TARGET_ONE_ALLY or move.target_type == BattleMove.TargetType.TARGET_ONE_ALLY_NOT_SELF or move.target_type == BattleMove.TargetType.TARGET_ONE_ENEMY:
		var targets_by_team = {}
		var target_self = null
		var initial_target = null
		for f in battle.get_fighters(false):
			if move.target_type == BattleMove.TargetType.TARGET_ONE_ALLY and f.team != fighter.team:
				continue
			if move.target_type == BattleMove.TargetType.TARGET_ONE_ALLY_NOT_SELF and (f.team != fighter.team or f == fighter):
				continue
			if move.target_type == BattleMove.TargetType.TARGET_ONE_ENEMY and f.team == fighter.team:
				continue
			target_sets.push_back([f])
			if not targets_by_team.has(f.team):
				targets_by_team[f.team] = []
			targets_by_team[f.team].push_back(f)
			if f == fighter:
				target_self = f
		if move.default_target == BattleMove.DefaultTarget.DEFAULT_TARGET_ENEMY:
			for slot in battle.get_slots():
				var f = slot.get_fighter()
				if not f or f.team == fighter.team:
					continue
				if not targets_by_team.has(f.team) or not targets_by_team[f.team].has(f):
					continue
				initial_target = f
				break
		elif move.default_target == BattleMove.DefaultTarget.DEFAULT_TARGET_ALLY:
			if targets_by_team.has(fighter.team):
				for target in targets_by_team[fighter.team]:
					if target != target_self:
						initial_target = target
						break
		else:
			initial_target = target_self
		
		if initial_target:
			initial_target_set = [initial_target]
	
	elif move.target_type == BattleMove.TargetType.TARGET_TEAM:
		var teams = battle.get_active_teams()
		var target_set_self = null
		var target_set_other = null
		for team in teams.keys():
			var fighters = teams[team]
			
			if team == fighter.team:
				target_set_self = fighters
			elif not target_set_other:
				target_set_other = fighters
			
			target_sets.push_back(fighters)
			
		if target_set_self != null:
			if move.default_target != BattleMove.DefaultTarget.DEFAULT_TARGET_ENEMY:
				initial_target_set = target_set_self
			else:
				initial_target_set = target_set_other
	
	_setup_targets(target_sets, initial_target_set, move.target_type)

func _get_slots(target_set: Array) -> Array:
	var result = []
	for target in target_set:
		assert (target.slot)
		result.push_back(target.slot)
	return result

func setup_targets_for_item(battle, fighter, item: BaseItem):
	self.battle = battle
	self.fighter = fighter
	self.move = null
	self.item = item
	
	var fighters = battle.get_fighters(false)
	var target_sets = []
	var self_target_set = []
	var valid_target_set = []
	
	for f in fighters:
		var target_set = [f]
		var is_valid = item.are_targets_valid(fighter, target_set)
		if is_valid:
			if valid_target_set.size() == 0:
				valid_target_set = target_set
			if f == fighter:
				self_target_set = target_set
		target_sets.push_back(target_set)
		
	_setup_targets(target_sets, self_target_set if self_target_set.size() > 0 else valid_target_set)

func _setup_targets(target_sets: Array, initial_target_set: Array, target_type: int = BattleMove.TargetType.TARGET_ONE):
	current_button = null
	
	for child in target_buttons.get_children():
		child.queue_free()
		target_buttons.remove_child(child)
	
	for target_set in target_sets:
		assert (target_set.size() > 0)
		assert (target_type == BattleMove.TargetType.TARGET_TEAM or target_set.size() == 1)
		var team = target_set[0].team
		var slots = _get_slots(target_set)
		
		var button = TargetButton.instance()
		button.battle = battle
		button.slots = slots
		button.text = tr("BATTLE_TARGET_TEAM" + str(team)) if target_type == BattleMove.TargetType.TARGET_TEAM else target_set[0].get_name_with_disambiguator()
		if item:
			button.disabled = not item.are_targets_valid(fighter, target_set)
		target_buttons.add_child(button)
		
		if not button.disabled:
			button.connect("pressed", self, "chose_targets", [slots])
		button.connect("focus_entered", self, "focus_targets", [button, target_set])
		
		for slot in slots:
			if not button.disabled:
				slot.connect("pressed", self, "chose_targets", [slots])
			slot.connect("mouse_entered", self, "focus_targets", [button, target_set])
		
		if target_set == initial_target_set:
			current_button = button
	
	target_buttons.setup_focus()

func focus_targets(button, targets: Array):
	if not is_inside_tree():
		return

	if current_button and current_button != button and current_button.is_hovered():
		return

	current_button = button
	if not current_button.has_focus():
		current_button.grab_focus()

	# Accessibility: Announce target
	_announce_target(targets)
	
	var slots = []
	for target in targets:
		slots.push_back(target.slot)
	
	var hint = Vector3(0, 0, 0)
	var effects = []
	for target in targets:
		var h = Vector3()
		if move:
			h = move.get_effect_hint(fighter, target)
		elif item:
			h = item.get_effect_hint(target)
		if h is Array:
			for effect in h:
				if not effects.has(effect):
					effects.push_back(effect)
					hint += effect.get_effect_hint(target)
		elif h is Vector3:
			hint += h
		else:
			assert (h == null)
	
	var icons = icon_container.get_child(0)
	for child in icons.get_children():
		icons.remove_child(child)
		child.queue_free()
	for effect in effects:
		var texture = TextureRect.new()
		texture.texture = effect.icon
		texture.expand = true
		texture.rect_min_size = Vector2(48, 48)
		icons.add_child(texture)
	icon_container.rect_size.x = 0
	icon_container.rect_min_size.y = button.rect_size.y
	icon_container.visible = effects.size() > 0
	update_icon_container_position()
	icons.queue_sort()
	icon_container.queue_sort()
	
	if effects.size() == 0 and move and move.power > 0:
		hint += Vector3(0, 1, 0)
	
	var hint_color = COLOR_OTHER
	if hint.x > 0 or (hint.y > 0 and hint.z > 0):
		hint_color = COLOR_TRANSMUT
	elif hint.y > 0:
		hint_color = COLOR_DEBUFF
	elif hint.z > 0:
		hint_color = COLOR_BUFF
	
	battle.selection.select_target(slots, hint_color)

func unfocus_targets():
	if not is_inside_tree():
		return
	current_button = null
	icon_container.visible = false
	battle.selection.select_target([], Color.white)

func chose_targets(target_slots: Array):
	if not is_inside_tree():
		return
	emit_signal("option_chosen", target_slots)

func cancel():
	unfocus_targets()
	emit_signal("option_chosen", null)
	.hide()

func show():
	.show()
	grab_focus()

func hide():
	.hide()
	unfocus_targets()

func grab_focus():
	if not current_button:
		assert (target_buttons.get_child_count() > 0)
		current_button = target_buttons.get_child(0)
	current_button.grab_focus()

func _process(_delta):
	update_icon_container_position()

func update_icon_container_position():
	if not current_button:
		return
	if current_button.team == 0:
		icon_container.rect_global_position = current_button.rect_global_position + current_button.rect_size * Vector2(1.0, 0.0)
	else:
		icon_container.rect_global_position = current_button.rect_global_position - icon_container.rect_size * Vector2(1.0, 0.0)

func _announce_target(targets: Array):
	if not Accessibility or targets.size() == 0:
		return

	var announcement = "Target: "
	var target_names = []
	for target in targets:
		var name = target.get_name_with_disambiguator() if target.has_method("get_name_with_disambiguator") else "Unknown"
		target_names.append(name)

	announcement += ", ".join(target_names)

	# Indicate ally or enemy
	var team = targets[0].team if targets.size() > 0 else -1
	if team == fighter.team:
		announcement += ", ally"
	else:
		announcement += ", enemy"

	# Add HP info if single target
	if targets.size() == 1 and targets[0].has_method("get_hp_percent"):
		var hp_percent = targets[0].get_hp_percent()
		announcement += ", " + str(int(hp_percent * 100)) + " percent health"

	Accessibility.speak(announcement, true)
