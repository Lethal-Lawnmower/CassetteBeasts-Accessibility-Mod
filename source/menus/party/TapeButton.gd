extends TextureButton

const NORMAL_TEXTURE = preload("res://ui/party/tape.png")
const BOOTLEG_TEXTURE = preload("res://ui/party/tape_bootleg.png")
const EMPTY_TEXTURE = preload("res://ui/party/tape_empty.png")

const FULL_REWIND_DURATION = 1.0

export (Resource) var tape: Resource = null setget set_tape
export (bool) var choosable: bool = true setget set_choosable

onready var type_icon_container: Container = find_node("TypeIconContainer")
onready var name_label: Label = find_node("NameLabel")
onready var favorite_icon: TextureRect = find_node("FavoriteIcon")
onready var grade_stars = find_node("GradeStars")
onready var monster_sticker: TextureRect = find_node("MonsterSticker")
onready var container = $ScaleToFitParent / MarginContainer
onready var behind_container = $ScaleToFitParent2 / BehindContainer
onready var overlay = $ScaleToFitParent / Overlay
onready var exp_bar = find_node("ExpBar")
onready var hp_bar = find_node("HPBar")
onready var left_reel = find_node("LeftReel")
onready var right_reel = find_node("RightReel")
onready var audio_stream_player = $AudioStreamPlayer
onready var unchoosable_panel = $ScaleToFitParent / Unchooseable

var form: MonsterForm
var rewinding: bool = false
var rewind_tween: Tween

func _ready():
	rewind_tween = Tween.new()
	add_child(rewind_tween)
	set_tape(tape)
	set_choosable(choosable)
	# Accessibility: Connect focus signal for TTS announcements
	connect("focus_entered", self, "_on_focus_entered_accessibility")

func set_choosable(value: bool):
	choosable = value
	if unchoosable_panel:
		unchoosable_panel.visible = not choosable

func set_tape(value: MonsterTape):
	tape = value
	if Engine.editor_hint:
		return
	form = tape.create_form() if tape else null
	if tape:
		texture_normal = NORMAL_TEXTURE if not tape.is_bootleg() else BOOTLEG_TEXTURE
	else:
		texture_normal = EMPTY_TEXTURE
	
	if name_label:
		container.visible = tape != null
		behind_container.visible = tape != null
		overlay.visible = tape != null
		
		if tape:
			name_label.text = tape.get_name()
		else:
			name_label.text = form.name if form != null else "???"
		favorite_icon.visible = tape != null and tape.favorite
		
		grade_stars.set_grade(0 if tape == null else tape.grade)
		
		if tape:
			if not rewinding:
				hp_bar.value = tape.hp.to_int_ceil_nonzero(hp_bar.max_value)
				left_reel.progress = tape.hp.to_float()
				right_reel.progress = tape.hp.to_float()
			
			if tape.is_broken():
				modulate = Color(0.5, 0.5, 0.5, 1.0)
			else:
				modulate = Color.white
		
		var types = form.elemental_types if form != null else []
		for child in type_icon_container.get_children():
			type_icon_container.remove_child(child)
			child.queue_free()
		for type in types:
			var icon = TextureRect.new()
			icon.expand = true
			icon.rect_min_size = Vector2(42, 42)
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			icon.texture = type.icon
			type_icon_container.add_child(icon)
		
		monster_sticker.texture = form.tape_sticker_texture if form else null
		
		exp_bar.set_max_exp_points(tape.get_exp_to_next_grade() if tape else 1)
		exp_bar.set_exp_points(tape.exp_points if tape else 0)

func animate_exp_points(overflow_speed: float = 1.0):
	if not tape:
		return null
	
	var speed = overflow_speed if tape.exp_points >= tape.get_exp_to_next_grade() else 1.0
	var result = exp_bar.animate_exp_points(tape.exp_points, speed)
	
	if not rewinding and tape.exp_points != exp_bar.exp_points:
		var exp_offset = 0.05
		rewind_tween.remove_all()
		rewind_tween.interpolate_property(left_reel, "exp_offset", null, left_reel.exp_offset + exp_offset, exp_bar.tween_duration / speed)
		rewind_tween.interpolate_property(right_reel, "exp_offset", null, right_reel.exp_offset + exp_offset, exp_bar.tween_duration / speed)
		rewind_tween.start()
	
	return result

func rewind_tape_to(value: Rational, sfx: AudioStream = null):
	if tape == null:
		return
	if tape.hp.compare(value) != 0 and not rewinding:
		audio_stream_player.stream = sfx
		audio_stream_player.play()
		
		var duration = FULL_REWIND_DURATION * abs(value.to_float() - tape.hp.to_float())
		tape.hp.set_to(value.numerator, value.denominator)
		rewinding = true
		
		rewind_tween.stop_all()
		rewind_tween.remove_all()
		rewind_tween.interpolate_property(hp_bar, "value", null, tape.hp.to_int_ceil_nonzero(hp_bar.max_value), duration)
		rewind_tween.interpolate_property(left_reel, "progress", null, tape.hp.to_float(), duration)
		rewind_tween.interpolate_property(right_reel, "progress", null, tape.hp.to_float(), duration)
		rewind_tween.start()
		yield(Co.wait_for_tween(rewind_tween), "completed")
		rewinding = false

func _on_focus_entered_accessibility():
	if not Accessibility:
		return

	if tape == null:
		Accessibility.speak("Empty slot", true)
		return

	var tape_name = tape.get_name() if tape.has_method("get_name") else "Unknown"
	var species_name = ""
	var type_names = []
	var hp_percent = 100.0
	var is_broken = false
	var grade_value = 0

	# Get form info
	if form:
		species_name = Loc.tr(form.name) if "name" in form else ""
		# Get type names
		if "elemental_types" in form:
			for etype in form.elemental_types:
				if etype and "name" in etype:
					type_names.append(Loc.tr(etype.name))

	if species_name == "":
		species_name = tape_name

	# Get HP percentage
	if tape.has_method("hp") or "hp" in tape:
		hp_percent = tape.hp.to_float() * 100.0 if tape.hp else 100.0

	# Check if broken
	if tape.has_method("is_broken"):
		is_broken = tape.is_broken()

	# Get grade
	if "grade" in tape:
		grade_value = tape.grade

	Accessibility.announce_tape_info(tape_name, species_name, type_names, hp_percent, is_broken, grade_value)
