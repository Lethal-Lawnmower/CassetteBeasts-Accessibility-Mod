extends SimpleSlidingControl

const NotificationMessage = preload("NotificationMessage.gd")

var message: NotificationMessage setget set_message

onready var title_label = get_node(@"%TitleLabel")
onready var message_label = get_node(@"%MessageLabel")
onready var audio_player = $AudioStreamPlayer
onready var icon = $IconPanel / Icon
onready var net_player_head = $IconPanel / NetPlayerHead

var _hiding = false

func _ready():
	set_message(message)
	connect("showing", self, "now_showing")
	connect("hiding", self, "now_hiding")

func set_message(value: NotificationMessage):
	if _hiding:
		return
	
	if message:
		message.disconnect("changed", self, "_on_message_changed")
	message = value
	if message:
		message.connect("changed", self, "_on_message_changed")
		_on_message_changed()

func is_valid():
	return message and message.is_valid()

func _on_message_changed():
	if message_label and not _hiding and is_valid():
		title_label.text = Loc.tr(message.title)
		title_label.get_parent().visible = message.title != ""
		message_label.text = Loc.tr(message.text)
		icon.texture = message.icon
		net_player_head.visible = false
		if message.net_player_id != null:
			var player_info = Net.players.get_player_info(message.net_player_id)
			if player_info:
				net_player_head.part_names = player_info.human_part_names.duplicate()
				net_player_head.colors = player_info.human_colors.duplicate()
				net_player_head.visible = true
				net_player_head.refresh()
				icon.texture = null

func now_showing():
	if message and message.audio:
		audio_player.stream = message.audio
		audio_player.play()

	# Accessibility: Announce notification
	if Accessibility and message:
		var announcement = ""
		if message.title != "":
			announcement = Loc.tr(message.title) + ": "
		announcement += Loc.tr(message.text)
		Accessibility.speak(announcement, false)

func now_hiding():
	if not _hiding:
		_hiding = true
		if message:
			message.disconnect("changed", self, "_on_message_changed")
