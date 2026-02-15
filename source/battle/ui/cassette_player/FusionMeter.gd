extends MeshInstance

const FusionMeter = preload("res://global/save_state/Party_FusionMeter.gd")

var fighter: Node = null
var fusion_meter: FusionMeter
var value: float = 0.0 setget set_value
var _was_full: bool = false  # Track if fusion meter was already full

func _ready():
	update()

func set_value(new_value: float):
	value = clamp(new_value, 0.0, 1.0)
	material_override.set_shader_param("uv1_offset", Vector3((1.0 - new_value) / 2.0, 0, 0))

func _set_glow(filled: bool):
	material_override.set_shader_param("glowing", 1.0 if filled else 0.0)

func update():
	if fighter:
		fusion_meter = fighter.battle.get_fusion_meter()
	else:
		fusion_meter = SaveState.party.fusion_meter

	visible = fighter and (fighter.is_fusion() or fighter.get_fuser() != null)

	set_value(fusion_meter.value.to_float())
	var is_full = fusion_meter.is_full()
	_set_glow(is_full)

	# Accessibility: Announce when fusion meter becomes full
	if is_full and not _was_full:
		if Accessibility:
			Accessibility.speak("Fusion ready!", true)
	_was_full = is_full
