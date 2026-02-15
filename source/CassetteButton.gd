tool 
extends Spatial

signal focus_entered
signal focus_exited
signal pressed

export (bool) var focusable: bool = true setget set_focusable, is_focusable
export (bool) var disabled: bool = false setget set_disabled
export (NodePath) var focus_next: NodePath
export (NodePath) var focus_previous: NodePath
export (Mesh) var mesh: Mesh setget set_mesh
export (Texture) var texture_normal: Texture setget set_texture_normal
export (Texture) var texture_focused: Texture setget set_texture_focused
export (Texture) var texture_disabled: Texture setget set_texture_disabled

onready var mesh_instance = $StaticBody / MeshInstance
onready var animation_player = $AnimationPlayer

var _has_focus: bool = false
var force_unfocusable: bool = false

func _ready():
	set_mesh(mesh)
	update_texture()

func update(_fighter: Node):
	pass

func set_focusable(value: bool):
	focusable = value
	update_texture()

func is_focusable() -> bool:
	return focusable and not force_unfocusable

func set_disabled(value: bool):
	disabled = value
	update_texture()

func set_mesh(value: Mesh):
	mesh = value
	if mesh_instance:
		mesh_instance.mesh = value.duplicate()
		update_texture()

func set_texture_normal(value: Texture):
	texture_normal = value
	update_texture()

func set_texture_focused(value: Texture):
	texture_focused = value
	update_texture()

func set_texture_disabled(value: Texture):
	texture_disabled = value
	update_texture()

func set_shader_param(param: String, value):
	var mesh = mesh_instance.mesh
	for i in range(mesh.get_surface_count()):
		var mat = mesh.surface_get_material(i)
		assert (mat is SpatialMaterial)
		mat.set(param, value)

func update_texture():
	if not mesh_instance:
		return
	
	var texture = null
	if not focusable:
		texture = texture_disabled
	elif has_focus() and not disabled:
		texture = texture_focused
	else:
		texture = texture_normal
	if texture == null:
		return
	
	set_shader_param("albedo_texture", texture)

func grab_focus():
	if not has_focus() and focusable:
		animation_player.play("focus")
		_has_focus = true
		update_texture()
		emit_signal("focus_entered")

		# Accessibility: Announce button name
		if Accessibility:
			var btn_name = name.replace("Button", "")
			Accessibility.speak(btn_name + " button", true)

func drop_focus():
	if has_focus():
		animation_player.play("unfocus")
		_has_focus = false
		update_texture()
		emit_signal("focus_exited")

func vibrate(magnitude: float, duration: float):
	MultiplayerInput.start_joy_vibration(MultiplayerInput.exclusive_control_player, magnitude, duration)

func press():
	if not focusable or disabled:
		return
	if not has_focus():
		grab_focus()
	if not disabled:
		vibrate(0.1, 0.1)
		animation_player.play("press")
		emit_signal("pressed")

func has_focus() -> bool:
	return _has_focus

func _on_StaticBody_input_event(_camera, event: InputEvent, _click_position, _click_normal, _shape_idx):
	if not focusable:
		return
	if event is InputEventMouseMotion and event.relative != Vector2.ZERO and not has_focus() and not disabled:
		grab_focus()
		get_tree().set_input_as_handled()
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		press()
		get_tree().set_input_as_handled()

func _unhandled_input(event: InputEvent):
	if Engine.editor_hint or not has_focus() or not focusable or not MenuHelper.is_in_top_menu(self):
		return
	if event.is_action_pressed("ui_accept"):
		press()
		get_tree().set_input_as_handled()
	if event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_right"):
		if not focus_next.is_empty():
			get_node(focus_next).grab_focus()
		get_tree().set_input_as_handled()
	if event.is_action_pressed("ui_focus_prev") or event.is_action_pressed("ui_left"):
		if not focus_previous.is_empty():
			get_node(focus_previous).grab_focus()
		get_tree().set_input_as_handled()

