extends VBoxContainer

export (Color) var regular_heading_color: Color
export (Color) var bootleg_heading_color: Color

onready var heading_panel = $"%HeadingPanel"
onready var type_icon1 = $"%TypeIcon1"
onready var type_icon2 = $"%TypeIcon2"
onready var boss_name_label = $"%BossNameLabel"
onready var boss_level_label = $"%BossLevelLabel"
onready var subheading_panel = $"%SubheadingPanel"
onready var subtitle_label = $"%SubtitleLabel"
onready var sprite_container = $"%MonsterSpriteContainer"
onready var reward_label = $"%RewardLabel"
onready var hint_label = $"%HintLabel"

var hint_text: String setget set_hint_text
var battle_args = null setget set_battle_args
var max_level: int
var subtitle: String
var primary_enemy_form: BaseForm
var enemy_level: int
var is_bootleg: bool
var is_modified: bool
var loot_table: LootTable
var replacement_loot_table: LootTable setget set_replacement_loot_table
var updated_once: bool

func update_ui():
	if battle_args == null:
		return

	updated_once = true
	analyse_battle_args()

	# Accessibility: Announce raid info
	_announce_raid_info()
	
	assert (primary_enemy_form != null)
	
	if is_bootleg:
		heading_panel.get_stylebox("panel").bg_color = bootleg_heading_color
		subheading_panel.get_stylebox("panel").bg_color = bootleg_heading_color
	else:
		heading_panel.get_stylebox("panel").bg_color = regular_heading_color
		subheading_panel.get_stylebox("panel").bg_color = regular_heading_color
	
	if not is_modified and primary_enemy_form.elemental_types.size() > 0:
		type_icon1.texture = primary_enemy_form.elemental_types[0].icon
		type_icon1.visible = true
	else:
		type_icon1.visible = false
	
	if not is_modified and primary_enemy_form.elemental_types.size() > 1:
		type_icon2.texture = primary_enemy_form.elemental_types[1].icon
		type_icon2.visible = true
	else:
		type_icon2.visible = false
	
	boss_name_label.text = primary_enemy_form.name if not is_modified else "UNKNOWN_NAME"
	boss_level_label.text = Loc.trf("UI_CHARACTER_LEVEL", [enemy_level])
	boss_level_label.visible = enemy_level != 0
	
	subtitle_label.text = subtitle
	
	if hint_text != "":
		hint_label.bbcode_text = hint_text
	elif max_level > 0 and SaveState.party.player.level > max_level:
		hint_label.bbcode_text = Loc.trf("ROGUE_FUSION_RAID_MAX_LEVEL", {max_level = max_level})
	else:
		hint_label.bbcode_text = ""
	
	sprite_container.battle_slot.sprite_container.static_amount = 1.0 if is_modified else 0.0
	
	update_reward()
	show_sprite()

func update_reward():
	var loot = replacement_loot_table if replacement_loot_table else loot_table
	if loot and loot.guaranteed_items.size() > 0:
		var item = loot.guaranteed_items[0]
		var item_amount = loot.guaranteed_item_amounts[0] if loot.guaranteed_item_amounts.size() > 0 else 1
		reward_label.bbcode_text = Loc.trf("ROGUE_FUSION_RAID_REWARD", {
			item = "[img=0x24]" + item.icon.resource_path + "[/img]", 
			item_amount = item_amount
		})
		reward_label.visible = true
	else:
		reward_label.visible = false

func set_replacement_loot_table(value: LootTable):
	replacement_loot_table = value
	if reward_label:
		update_reward()

func set_hint_text(value: String):
	hint_text = value
	if hint_label:
		hint_label.bbcode_text = hint_text

func show_sprite():
	sprite_container.rect_min_size = sprite_container.rect_size
	sprite_container.set_form(primary_enemy_form)
	sprite_container.visible = true
	yield(sprite_container, "form_sprite_set")
	if is_modified:
		sprite_container.battle_slot.sprite_container.static_amount = 1.0
		sprite_container.battle_slot.sprite_container.static_speed = 0.0

func set_battle_args(value):
	var changed = battle_args != value
	battle_args = value
	if battle_args and changed and updated_once:
		update_ui()

func _announce_raid_info():
	if not Accessibility or not primary_enemy_form:
		return

	var announcement = "Raid Boss: "
	if is_modified:
		announcement += "Unknown creature"
	else:
		announcement += Loc.tr(primary_enemy_form.name)

	if enemy_level > 0:
		announcement += ", level " + str(enemy_level)

	if is_bootleg:
		announcement += ", bootleg"

	if subtitle != "":
		announcement += ". " + Loc.tr(subtitle)

	if max_level > 0 and SaveState.party.player.level > max_level:
		announcement += ". Warning: your level exceeds maximum of " + str(max_level)

	Accessibility.speak(announcement, true)

func analyse_battle_args():
	is_bootleg = false
	
	is_modified = battle_args.get("bootleg_modified", false) == true
	
	assert (battle_args.has("fighters"))
	if battle_args.has("fighters"):
		for enemy in battle_args.fighters:
			if enemy.get_characters().size() > 1:
				primary_enemy_form = enemy.get_general_form()
				enemy_level = enemy.get_characters()[0].character.level
				
				for c in enemy.get_characters():
					if c.current_tape and c.current_tape.type_override.size() > 0:
						is_bootleg = true
						break
				break
		
		if not primary_enemy_form:
			for enemy in battle_args.fighters:
				primary_enemy_form = enemy.get_general_form()
				break
	
	if battle_args.get("title_banner"):
		var tb = battle_args.get("title_banner")
		subtitle = Loc.trf(tb.subtitle, tb.title_subs)
	
	max_level = battle_args.get("max_level", 0)
	
	var arg_loot = battle_args.get("loot_table_override")
	if arg_loot is String:
		loot_table = load(arg_loot) as LootTable
	else:
		loot_table = arg_loot as LootTable
