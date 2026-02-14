extends "res://menus/party/PartyMenu.gd"

const TAPES_UPGRADE_ONLY_ONCE: bool = true

export (int) var exp_yield: int = 0
export (Resource) var loot_table: Resource = null

onready var exp_fill_audio_player = $ExpFillAudioPlayer
onready var exp_up_audio_player = $ExpUpAudioPlayer
onready var exp_label = $Scroller / ExpLabel

var loot_rand: Random = Random.new()
var extra_loot: Array
var speed: float = 1.0
var highest_total_exp: int = 0
var whitelist: Array
var bg_partners: Array
var started: bool = false

func _init():
	disable_input = true

func _ready():
	exp_label.visible = false
	
	for partner in SaveState.party.partners:
		if SaveState.party.current_partner_id == partner.partner_id or not SaveState.party.is_partner_unlocked(partner.partner_id):
			continue
		bg_partners.push_back(partner)

func grab_focus():
	if started:
		return
	started = true
	
	for member in party:
		if member[0] != null:
			highest_total_exp = int(max(member[0].get_total_exp(), highest_total_exp))
	
	if SaveState.party.HEAL_TAPES_AFTER_BATTLE:
		var full_hp = Rational.new(1, 1)
		for button in party_member_buttons:
			if button.tape and not button.tape.is_broken():
				button.rewind_tape_to(full_hp)
		for button in tape_buttons:
			if button.tape and not button.tape.is_broken():
				button.rewind_tape_to(full_hp)
	
	yield(Co.wait(0.5), "completed")
	apply_exp()

func queue_levels(leveling: Array, points: Dictionary):
	leveling.clear()
	for member in party:
		if member[0] == null or member[0].level >= SaveState.max_level:
			continue
		var to_add = int(min(points[member[0]], member[0].get_exp_to_next_level() - member[0].exp_points))
		member[0].exp_points += to_add
		points[member[0]] -= to_add
		if member[0].exp_points >= member[0].get_exp_to_next_level():
			leveling.push_back(member[0])
	
	for partner in bg_partners:
		if partner.level >= SaveState.max_level:
			continue
		var to_add = int(min(points[partner], partner.get_exp_to_next_level() - partner.exp_points))
		partner.exp_points += to_add
		points[partner] -= to_add
		if partner.exp_points >= partner.get_exp_to_next_level():
			leveling.push_back(partner)
	
	for tape in active_tapes:
		var to_add = int(min(points[tape], tape.get_exp_to_next_grade() - tape.exp_points))
		tape.exp_points += to_add
		points[tape] -= to_add
		if tape.exp_points >= tape.get_exp_to_next_grade():
			leveling.push_back(tape)
		if TAPES_UPGRADE_ONLY_ONCE:
			points[tape] = points[tape] %tape.get_exp_to_next_grade()
	for tape in inactive_tapes:
		var to_add = int(min(points[tape], tape.get_exp_to_next_grade() - tape.exp_points))
		tape.exp_points += to_add
		points[tape] -= to_add
		if tape.exp_points >= tape.get_exp_to_next_grade():
			leveling.push_back(tape)
		if TAPES_UPGRADE_ONLY_ONCE:
			points[tape] = points[tape] %tape.get_exp_to_next_grade()

func level_up_all(leveling: Array, unlocked_stickers: Array):
	for leveler in leveling:
		if leveler is Character:
			level_up(leveler)
		else:
			assert (leveler is MonsterTape)
			unlocked_stickers.push_back(grade_up(leveler))
	update_ui()

func apply_exp():
	var leveling = []
	var unlocked_stickers = []

	GlobalMessageDialog.clear_state()

	if whitelist.size() == 0:
		exp_label.visible = true
		exp_label.text = Loc.trf("BATTLE_EXP_POINTS", [exp_yield])
		# Accessibility: Announce EXP gained
		if Accessibility:
			Accessibility.speak(str(exp_yield) + " experience points", true)
	else:
		exp_label.visible = false
	
	reset_pitch()
	
	var points = {}
	for member in party:
		if member[0] == null:
			continue
		if member[0].relationship_level > 0 and whitelist.size() == 0:
			member[0].relationship_points += exp_yield
		
		if whitelist.size() == 0 or whitelist.has(member[0]):
			points[member[0]] = exp_yield
		else:
			points[member[0]] = 0
		
		if whitelist.size() == 0:
			var p = member[0].get_total_exp() + exp_yield
			if p < highest_total_exp:
				points[member[0]] += int(min(exp_yield * 2, highest_total_exp - p))
	
	for partner in bg_partners:
		if whitelist.size() == 0 or whitelist.has(partner):
			points[partner] = exp_yield / 2
		else:
			points[partner] = 0
	
	for tape in active_tapes:
		if whitelist.size() == 0 or whitelist.has(tape):
			points[tape] = exp_yield
		else:
			points[tape] = 0
	for tape in inactive_tapes:
		if whitelist.size() == 0 or whitelist.has(tape):
			points[tape] = exp_yield
		else:
			points[tape] = 0
	
	queue_levels(leveling, points)
	yield(animate_exp_bars(leveling), "completed")
	level_up_all(leveling, unlocked_stickers)
	while leveling.size() > 0:
		speed_up()
		queue_levels(leveling, points)
		yield(animate_exp_bars(leveling), "completed")
		level_up_all(leveling, unlocked_stickers)
	
	yield(Co.wait(1.0), "completed")
	exp_label.visible = false
	
	var rewards = []
	if loot_table != null:
		rewards = loot_table.generate_rewards(loot_rand, exp_yield)
	rewards += extra_loot
	if rewards.size() > 0 or unlocked_stickers.size() > 0:
		yield(MenuHelper.give_items(rewards, unlocked_stickers), "completed")
	
	SaveState.party.notify_tapes_changed()
	
	yield(Co.wait(1.0), "completed")
	cancelable = true
	cancel()

func animate_exp_bars(leveling: Array):
	var co_list = []
	for button in party_member_buttons:
		var co = button.animate_character_exp_points(speed)
		if co and (leveling.has(button.character) or leveling.size() == 0):
			co_list.push_back(co)
		co = button.animate_tape_exp_points(speed)
		if co and (leveling.has(button.tape) or leveling.size() == 0):
			co_list.push_back(co)
	for button in tape_buttons:
		var co = button.animate_exp_points(speed)
		if co and (leveling.has(button.tape) or leveling.size() == 0):
			co_list.push_back(co)
	if co_list.size() > 0:
		exp_fill_audio_player.play()
	yield(Co.join(co_list), "completed")

func speed_up():
	for audio_player in [exp_fill_audio_player, exp_up_audio_player]:
		if audio_player.pitch_scale < 8.0:
			audio_player.pitch_scale += 0.25
		else:
			audio_player.pitch_scale = 1.0
	speed += speed * 0.1

func reset_pitch():
	exp_fill_audio_player.pitch_scale = 0.75
	exp_up_audio_player.pitch_scale = 0.75

func level_up(character: Character):
	for button in party_member_buttons:
		if button.character == character:
			exp_up_audio_player.play()
			break
	character.exp_points = 0
	character.level += 1

	# Accessibility: Announce level up
	if Accessibility:
		var char_name = character.name if character.name else "Character"
		Accessibility.speak(char_name + " leveled up to level " + str(character.level), false)

	if character != SaveState.party.partner:
		character.background_levels_gained += 1

func grade_up(tape: MonsterTape):
	exp_up_audio_player.play()
	tape.exp_points = 0
	tape.grade += 1

	# Accessibility: Announce grade up
	if Accessibility:
		var tape_name = tape.get_name() if tape.has_method("get_name") else "Tape"
		Accessibility.speak(tape_name + " upgraded to grade " + str(tape.grade), false)

	var upgrade = tape.get_upgrade(tape.grade)
	assert (upgrade != null)
	var result = upgrade.apply_player(tape)
	if result is LootRecord:
		assert (result.tape == tape)
		if result.sticker_index == - 1 and not result.dropped:
			var left_over = SaveState.inventory.add_new_item(result.item, result.amount)
			if left_over > 0:
				WorldSystem.drop_item(result.item, left_over)
				result.dropped = true
	return result
