extends ContainerButton

const Generator = preload("res://data/quests/noticeboard/noticeboard_generator.tres")
const NoticeboardRecord = preload("res://data/NoticeboardRecord.gd")

onready var title_label = find_node("TitleLabel")
onready var completed_label = find_node("CompletedLabel")
onready var description_label = find_node("DescriptionLabel")
onready var input_prompt = find_node("InputPrompt")
onready var input_icon = find_node("InputIcon")
onready var input_prompt_label = find_node("InputPromptLabel")

var disabled: bool = false
var record: NoticeboardRecord setget set_record
var quest_node: Quest
var is_generated: bool

func _ready():
	update_ui()
	InputIcons.connect("icons_changed", self, "update_input_icon")

func _enter_tree():
	setup_quest_node()

func _exit_tree():
	clear_quest_node()

func set_record(value: NoticeboardRecord):
	record = value
	
	clear_quest_node()
	
	if is_inside_tree():
		setup_quest_node()

func setup_quest_node():
	if record == null:
		is_generated = false
		return
	
	if record.accepted and SaveState.quests.has_quest(record.quest):
		quest_node = SaveState.quests.get_quest(record.quest)
		is_generated = true
	
	if not quest_node:
		quest_node = record.quest.instance()
		is_generated = quest_node.generate(record.params)
		if is_generated:
			quest_node.reserve_locations()

func clear_quest_node():
	if quest_node:
		if not quest_node.is_inside_tree():
			if is_generated:
				quest_node.unreserve_locations()
			quest_node.queue_free()
		quest_node = null

func is_completed() -> bool:
	return record and record.accepted and SaveState.quests.is_completed(record.quest)

func _hof_update_modulate(_delta, _target_mod):
	
	pass

func update_input_icon():
	input_icon.texture = InputIcons.get_action_icon_texture("ui_accept")

func _focus_entered():
	if not record or is_completed():
		input_prompt.visible = false
		# Accessibility: Announce completed quest
		if Accessibility and record and is_completed():
			var title = quest_node.get_title() if quest_node else "Unknown quest"
			Accessibility.speak(Loc.tr(title) + ", completed", true)
		return
	update_input_icon()
	if record.accepted:
		input_prompt_label.text = "NOTICEBOARD_QUEST_BUTTON_VIEW"
	else:
		input_prompt_label.text = "NOTICEBOARD_QUEST_BUTTON_ACCEPT"
	input_prompt.visible = true

	# Accessibility: Announce quest info
	if Accessibility and quest_node:
		var announcement = Loc.tr(quest_node.get_title())
		if record.accepted:
			announcement += ", in progress. Press to view details."
		else:
			announcement += ". " + Loc.tr(quest_node.get_description()) + ". Press to accept."
		Accessibility.speak(announcement, true)

func _focus_exited():
	input_prompt.visible = false

func update_ui():
	if not quest_node or not record:
		title_label.text = "UNKNOWN_NAME"
		completed_label.visible = false
		description_label.text = "NOTICEBOARD_QUEST_FALLBACK_DESCRIPTION"
		disabled = true
		return
	
	var completed = is_completed()
	
	title_label.text = quest_node.get_title()
	completed_label.visible = completed
	
	if record.accepted:
		modulate = Color(1.0, 1.0, 1.0, 0.5)
	else:
		modulate = Color.white
	
	disabled = completed
	
	description_label.visible = not completed
	if not completed:
		if is_generated:
			description_label.text = quest_node.get_description()
		else:
			description_label.text = "NOTICEBOARD_QUEST_FALLBACK_DESCRIPTION"

func _pressed():
	if record:
		if is_completed():
			return
		
		var focus_owner = get_focus_owner()
		if focus_owner:
			focus_owner.release_focus()
		
		if record.accepted:
			yield(MenuHelper.show_quest_log(record.quest), "completed")
		elif not is_generated:
			GlobalMessageDialog.clear_state()
			yield(GlobalMessageDialog.show_message("NOTICEBOARD_QUEST_CANNOT_ACCEPT"), "completed")
		else:
			assert ( not quest_node.is_inside_tree())
			var result = yield(MenuHelper.start_quest(quest_node), "completed")
			assert (result)
			SaveState.stats.get_stat("noticeboard_quests_started").report_event(record.quest)
		
		update_ui()
		grab_focus()
