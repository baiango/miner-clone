class_name Kira extends CharacterBody3D

@onready var h := $h as Node3D
@onready var v := $h/v as Node3D


func _lerp3_xz(from: Vector3, to: Vector3, weight: float) -> Vector3:
	from.x = lerpf(from.x, to.x, weight)
	from.z = lerpf(from.z, to.x, weight)
	return from


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	var mouse_sensitivity := 0.1
	if event as InputEventMouseMotion:
		var camera_input := (event as InputEventMouseMotion).get_relative() as Vector2
		h.rotate_y(deg_to_rad(-camera_input.x * mouse_sensitivity))
		v.rotate_x(deg_to_rad(-camera_input.y * mouse_sensitivity))
		v.set_rotation(Vector3(clamp(v.rotation.x, -PI/2, PI/2), v.get_rotation().y, v.get_rotation().z))

	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode else Input.MOUSE_MODE_CAPTURED

	if Input.is_action_just_pressed("ctrl + f4"):
		position = Vector3.BACK
		(Glob.BLKS as Chunk).reset()
		($reset as AudioStreamPlayer).play()


enum OneshotRequest { Empty, Fire }
var walk_blend := 0.0
func _physics_process(delta: float) -> void:
	var jmp_snd := $Skeleton3D/Body/jump as AudioStreamPlayer3D
	# movement
	var input := Vector2(Input.get_axis("w","s"), Input.get_axis("a","d"))

	velocity += (h.transform.basis.z * input.x +
				h.transform.basis.x * input.y) * delta * 5# * 10 # debug
	velocity.y -= 9.8 * delta

	if Input.is_action_just_pressed(" ") and is_on_floor():
		velocity.y = 9
		jmp_snd.play()

	velocity.y = clampf(velocity.y, -55, 55)
	move_and_slide()
	velocity = _lerp3_xz(velocity, Vector3.ZERO, delta * 5)

	# mesh
	var ske := $Skeleton3D as Skeleton3D
	var movement_input_pressed := true if input != Vector2.ZERO else false
	if movement_input_pressed:
		ske.rotation.y = lerp_angle(ske.rotation.y,
				h.rotation.y + atan2(input.y, input.x), delta * 4)

	# animations
	var ani := $AnimationTree as AnimationTree
	var movement_input_strength := signf(absf(input.x) + absf(input.y))

	var walk_blend_lerped := lerpf(walk_blend, movement_input_strength, delta * 5)
	walk_blend = walk_blend_lerped if walk_blend_lerped > 0.05 else 0.0
	ani.set("parameters/walk/blend_amount", walk_blend)

	if Input.is_action_just_pressed("lmb"):
		if not anim_locked:
			ani.set("parameters/mine/request", OneshotRequest.Fire)


var anim_locked := false
func _on_animation_tree_animation_started(anim_name: StringName) -> void:
	anim_locked = true


func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	anim_locked = false
