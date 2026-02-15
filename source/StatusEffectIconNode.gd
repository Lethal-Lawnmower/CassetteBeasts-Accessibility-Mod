extends Control

onready var amount_label = $AmountLabel
onready var icon = $Icon

var id: int
var current_snapshot = null
var tween_duration: float = 0.5
var tween: Tween
var fading_out: bool = false
var effect: StatusEffect
var amount = null
var tooltip: Control

func _ready():
	tween = Tween.new()
	add_child(tween)
	if current_snapshot != null:
		set_snapshot(current_snapshot)
	
	connect("focus_entered", self, "_on_focus_entered")
	connect("focus_exited", self, "_on_focus_exited")
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")

func set_snapshot(snapshot):
	id = snapshot.id
	current_snapshot = snapshot
	if icon != null and amount_label != null:
		set_effect(snapshot.effect)
		set_amount(snapshot.duration)

func set_effect(value: StatusEffect):
	effect = value
	if effect.icon != null:
		icon.texture = effect.icon
	else:
		icon.texture = null
	update_amount_label()

func set_amount(value):
	amount = value
	update_amount_label()

func update_amount_label():
	amount_label.visible = amount != null or (effect and effect.has_duration)
	if amount != null:
		amount_label.text = str(amount)
	elif effect and effect.has_duration:
		amount_label.text = "∞"

func fade_in():
	icon.modulate = Color(1.0, 1.0, 1.0, 0.0)
	tween.stop_all()
	tween.remove_all()
	tween.interpolate_property(icon, "rect_scale", Vector2(3.0, 3.0), Vector2(1.0, 1.0), tween_duration, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween.interpolate_property(icon, "modulate", Color(1.0, 1.0, 1.0, 0.0), Color.white, tween_duration, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween.start()
	yield(Co.wait_for_tween(tween), "completed")

func fade_out():
	if fading_out:
		return Co.pass()
	fading_out = true
	tween.stop_all()
	tween.remove_all()
	tween.interpolate_property(icon, "rect_scale", null, Vector2(3.0, 3.0), tween_duration, Tween.TRANS_CUBIC, Tween.EASE_IN)
	tween.interpolate_property(icon, "modulate", null, Color(1.0, 1.0, 1.0, 0.0), tween_duration, Tween.TRANS_CUBIC, Tween.EASE_IN)
	tween.start()
	yield(Co.wait_for_tween(tween), "completed")
	queue_free()

func _on_focus_entered():
	show_tooltip()
func _on_focus_exited():
	hide_tooltip()
func _on_mouse_entered():
	show_tooltip()
func _on_mouse_exited():
	hide_tooltip()

func show_tooltip():
	var text = tr(effect.name)
	if amount != null:
		text = Loc.trf("UI_BATTLE_STATUS_EFFECT_TOOLTIP", {
			status_effect = effect.name,
			amount = str(int(amount))
		})

	if effect.description != "":
		text += "\n" + tr(effect.description)

	# Accessibility: Announce status effect
	if Accessibility:
		var announcement = tr(effect.name)
		if amount != null:
			announcement += ", " + str(int(amount)) + " turns remaining"
		if effect.description != "":
			announcement += ". " + tr(effect.description)
		Accessibility.speak(announcement, true)
	
	if not tooltip:
		var canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 2
		add_child(canvas_layer)
		tooltip = preload("res://nodes/wrapped_tooltip/WrappedTooltip.tscn").instance()
		canvas_layer.add_child(tooltip)
	tooltip.text = text
	
	tooltip.rect_position = get_global_rect().position + Vector2(rect_size.x / 2 - tooltip.rect_size.x / 2, rect_size.y)
	var gr = tooltip.get_global_rect()
	var vps = get_viewport().get_size_override()
	if gr.position.x < 0:
		tooltip.rect_position.x += - gr.position.x
	if gr.end.x > vps.x:
		tooltip.rect_position.x -= gr.end.x - vps.x
	if gr.end.y > vps.y:
		tooltip.rect_position.y -= gr.end.y - vps.y
	
	tooltip.visible = true

func hide_tooltip():
	if tooltip:
		tooltip.visible = false
