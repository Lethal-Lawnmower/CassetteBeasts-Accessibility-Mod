extends Button

export (String) var label_format: String = ""

var player_id = null setget set_player_id

onready var sprite = $HBoxContainer / Control / Sprite
onready var player_name_label = $HBoxContainer / VBoxContainer / PlayerNameLabel
onready var display_name_label = $HBoxContainer / VBoxContainer / DisplayNameLabel
onready var system_icon = $HBoxContainer / SystemIcon

func _ready():
	set_player_id(player_id)

	Net.players.connect("player_info_changed", self, "_on_player_info_changed")

	# Accessibility: Connect focus signal
	connect("focus_entered", self, "_on_focus_entered_accessibility")

func _on_focus_entered_accessibility():
	if not Accessibility:
		return

	var info = Net.players.get_player_info(player_id) if player_id != null else null
	if not info:
		Accessibility.speak("Unknown player", true)
		return

	var player_name = info.player_name if info.player_name else "Unknown"
	var announcement = player_name

	if player_id == Net.local_id:
		announcement += ", you"

	if info.user_info and info.user_info.display_name:
		announcement += ", " + info.user_info.display_name

	Accessibility.speak(announcement, true)

func set_player_id(value):
	player_id = value
	if sprite:
		var info = Net.players.get_player_info(player_id) if player_id != null else null
		
		sprite.visible = info != null
		if info:
			sprite.part_names = info.human_part_names.duplicate()
			sprite.colors = info.human_colors.duplicate()
			sprite.refresh()
		
		var label_text = info.player_name if info else "UNKNOWN_NAME"
		
		if player_id == Net.local_id:
			label_text = Loc.trf("ONLINE_PLAYER_LIST_LOCAL_PLAYER", {
				player_name = label_text
			})
		if label_format != "":
			label_text = Loc.trgf(label_format, info.pronouns, {
				player_name = label_text
			})
		
		player_name_label.text = label_text
		
		display_name_label.text = info.user_info.display_name if info and info.user_info else ""
		
		system_icon.visible = info and info.user_info
		if info and info.user_info:
			system_icon.icon = info.user_info.system_icon

func _on_player_info_changed(id):
	if id != player_id:
		return
	set_player_id(player_id)
