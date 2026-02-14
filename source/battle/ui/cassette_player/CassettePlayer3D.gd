extends Spatial

signal button_pressed(menu_name)

export (String) var force_order: String = "" setget set_force_order

onready var animation_player = $AnimationPlayer
onready var cassette_player = find_node("CassettePlayer")
onready var focus_manager = find_node("FocusManager3D")
onready var fusion_button = find_node("FusionButton")
onready var input_tiltable = find_node("InputTiltable")
onready var fusion_meter = find_node("FusionMeter")
onready var force_order_overlay = $CanvasLayer / ForceOrderOverlay
onready var force_order_mat = force_order_overlay.material
onready var flee_chance_label = $CanvasLayer / FleeChanceLabel
onready var flee_chance_tween = $CanvasLayer / FleeChanceLabel / Tween
onready var flee_button = find_node("FleeButton")
onready var item_button = find_node("ItemButton")

var fighter: Node
var flee_chance_offset: Vector2 = Vector2(0.0, - 33.0)
var showing: bool
var hiding: bool

func _ready():
	GlobalUI.manage_visibility($Spatial)
	GlobalUI.manage_visibility(force_order_overlay)

	# Accessibility: Connect focus signals for TTS announcements
	_connect_button_focus("FightButton", "Fight")
	_connect_button_focus("FormsButton", "Forms")
	_connect_button_focus("ItemButton", "Items")
	_connect_button_focus("FleeButton", "Flee")
	_connect_button_focus("RecordButton", "Record")
	# Fusion button needs special handling for state
	if fusion_button and fusion_button.has_signal("focus_entered"):
		fusion_button.connect("focus_entered", self, "_announce_fusion_button")

	if SceneManager.current_scene == self:
		show()
	else:
		visible = false
		focus_manager.disabled = true

func _connect_button_focus(button_name: String, announcement: String):
	var button = focus_manager.get_node_or_null(button_name)
	if button and button.has_signal("focus_entered"):
		button.connect("focus_entered", self, "_announce_button_focus", [announcement])

func _exit_tree():
	if visible:
		GlobalUI.suppress_dof_blur_near = false

func get_button(order: String) -> Spatial:
	if order == "":
		return null
	return focus_manager.get_node(order + "Button")

func set_fighter(value: Node):
	fighter = value
	for child in focus_manager.get_children():
		child.update(fighter)
	if fighter.battle.is_net_game:
		var request = fighter.battle.get_net_request()
		if not request.items_allowed_in_battle:
			item_button.focusable = false
	focus_manager.setup_focus()
	fusion_meter.fighter = fighter
	
	if fighter and Character.is_archangel(fighter.get_character_kind()):
		cassette_player.material_override.set_shader_param("archangel_amount", 1.0)
	else:
		cassette_player.material_override.set_shader_param("archangel_amount", 0.0)
	
	var flee_chance = BattleFormulas.get_perceptual_chance(fighter.get_flee_chance().to_float())
	flee_chance_label.text = Loc.trf("UI_BATTLE_FLEE_CHANCE", [int(round(flee_chance * 100.0))])

func get_current_button():
	return focus_manager.focus_owner

func _process(_delta):
	_update_force_order_overlay()
	if flee_chance_label.visible:
		_update_flee_chance_position()

func set_force_order(value: String):
	force_order = value
	var forced_button = get_button(force_order)
	for child in focus_manager.get_children():
		child.force_unfocusable = forced_button != null and child != forced_button
	if forced_button != null:
		focus_manager.initial_focus = focus_manager.get_path_to(forced_button)
	else:
		focus_manager.initial_focus = NodePath()
	focus_manager.setup_focus()
	_update_force_order_overlay()

func _update_force_order_overlay():
	if force_order == "":
		force_order_mat.set_shader_param("opacity", 0.0)
	else:
		force_order_mat.set_shader_param("opacity", 0.25)
		var button = get_button(force_order)
		if button != null:
			var pos = get_viewport().get_camera().unproject_position(button.global_transform.origin)
			pos *= get_viewport().size / force_order_overlay.rect_size
			force_order_mat.set_shader_param("hole_position", pos)

func show():
	showing = true
	hiding = false
	Notifications.fusion_meter.hide()
	
	GlobalUI.suppress_dof_blur_near = true
	visible = true
	focus_manager.reset_focus()
	animation_player.play("show")
	fusion_meter.update()
	yield(animation_player, "animation_finished")
	if showing:
		focus_manager.disabled = false
		input_tiltable.enable_tilting = true
		showing = false

func defocus():
	input_tiltable.enable_tilting = false
	focus_manager.disabled = true
	animation_player.play("defocus")
	yield(animation_player, "animation_finished")

func refocus():
	fusion_meter.update()
	animation_player.play("refocus")
	yield(animation_player, "animation_finished")
	focus_manager.disabled = false
	input_tiltable.enable_tilting = true

func is_defocused():
	return focus_manager.disabled

func reset_focus():
	focus_manager.reset_focus()

func hide():
	showing = false
	hiding = true
	focus_manager.clear_focus()
	input_tiltable.enable_tilting = false
	focus_manager.disabled = true
	animation_player.play("hide")
	yield(animation_player, "animation_finished")
	if hiding:
		visible = false
		hiding = false
	
	GlobalUI.suppress_dof_blur_near = false

func _on_FightButton_pressed():
	emit_signal("button_pressed", "FightMenu")

func _on_FormsButton_pressed():
	emit_signal("button_pressed", "FormsMenu")

func _on_ItemButton_pressed():
	emit_signal("button_pressed", "ItemMenu")

func _on_FleeButton_pressed():
	emit_signal("button_pressed", "FleeMenu")

func _on_RecordButton_pressed():
	emit_signal("button_pressed", "RecordMenu")

func _on_FusionButton_pressed():
	emit_signal("button_pressed", "Fuse")

func _on_FleeButton_focus_entered():
	flee_chance_label.visible = not fighter.battle.is_net_game
	flee_chance_tween.stop_all()
	flee_chance_tween.remove_all()
	flee_chance_tween.interpolate_property(flee_chance_label, "modulate:a", null, 1.0, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	flee_chance_tween.interpolate_property(flee_chance_label, "custom_colors/font_color_shadow:a", null, 1.0, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	flee_chance_tween.interpolate_property(self, "flee_chance_offset:y", null, - 66, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	flee_chance_tween.start()
	_update_flee_chance_position()

func _update_flee_chance_position():
	var camera = get_viewport().get_camera()
	if not camera:
		return
	var pos = camera.unproject_position(flee_button.global_transform.origin) + flee_chance_offset
	flee_chance_label.margin_left = pos.x
	flee_chance_label.margin_top = pos.y
	flee_chance_label.margin_right = pos.x
	flee_chance_label.margin_bottom = pos.y

func _on_FleeButton_focus_exited():
	flee_chance_tween.stop_all()
	flee_chance_tween.remove_all()
	flee_chance_tween.interpolate_property(flee_chance_label, "modulate:a", null, 0.0, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	flee_chance_tween.interpolate_property(flee_chance_label, "custom_colors/font_color_shadow:a", null, 0.0, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	flee_chance_tween.interpolate_property(self, "flee_chance_offset:y", null, - 33, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	flee_chance_tween.start()
	yield(Co.wait_for_tween(flee_chance_tween), "completed")
	if not flee_button.has_focus():
		flee_chance_label.visible = false

func _announce_button_focus(button_text: String):
	if Accessibility:
		Accessibility.speak(button_text, true)

func _announce_fusion_button():
	if not Accessibility or not fighter:
		return
	var announcement = ""
	if fighter.will_fuse:
		announcement = "Fusion pending"
	elif fighter.is_fusion():
		if fighter.battle.enable_voluntary_unfusion:
			announcement = "Unfuse"
		else:
			announcement = "Cannot unfuse"
	else:
		var fuser = fighter.get_fuser()
		if fuser == null:
			announcement = "Fusion unavailable"
		else:
			var fusion_meter = fighter.battle.get_fusion_meter()
			if fusion_meter.is_full():
				announcement = "Fuse, ready"
			else:
				announcement = "Fuse, not ready"
	Accessibility.speak(announcement, true)
