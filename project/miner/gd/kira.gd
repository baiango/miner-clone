extends CharacterBody3D

@onready var h := $h
@onready var v := $h/v


func _lerp3_xz(from: Vector3, to: Vector3, weight: float) -> Vector3:
	from.x = lerp(from.x, to.x, weight)
	from.z = lerp(from.z, to.x, weight)
	return from


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	var mouse_sensitivity := 0.1

	if event is InputEventMouseMotion:
		var camera_input: Vector2 = event.get_relative()
		h.rotate_y(deg_to_rad(-camera_input.x * mouse_sensitivity))
		v.rotate_x(deg_to_rad(-camera_input.y * mouse_sensitivity))
		v.rotation.x = clamp(v.rotation.x, -PI/2, PI/2)

	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode else Input.MOUSE_MODE_CAPTURED

	if Input.is_action_just_pressed("ctrl + f4"):
		position = Vector3.BACK
		get_node(Glob.BLKS as String).reset()
		$reset.play()


enum OneshotRequest { Empty, Fire }
func _physics_process(delta):
	var jmp_snd := $Skeleton3D/Body/jump
	# movement
	var input := Vector2(Input.get_axis("w","s"), Input.get_axis("a","d"))

	velocity += (h.transform.basis.z * input.x +
				h.transform.basis.x * input.y) * delta * 5# * 10 # * 10 is for debug.
	velocity.y -= 9.8 * delta

	if Input.is_action_just_pressed(" ") and is_on_floor():
		velocity.y = 9
		jmp_snd.play()

	velocity.y = clampf(velocity.y, -55, 55)
	move_and_slide()
	velocity = _lerp3_xz(velocity, Vector3.ZERO, delta * 5)

	# mesh
	var ske := $Skeleton3D
	var movement_input_pressed := true if input != Vector2.ZERO else false
	if movement_input_pressed:
		ske.rotation.y = lerp_angle(ske.rotation.y,
				h.rotation.y + atan2(input.y, input.x), delta * 4)

	# animations
	var ani := $AnimationTree
	var movement_input_strength := signf(abs(input.x) + abs(input.y))
	var walk_blend := ani.get("parameters/walk/blend_amount") as float

	var walk_blend_lerped = lerpf(walk_blend, movement_input_strength, delta * 5)
	walk_blend = walk_blend_lerped if walk_blend_lerped > 0.05 else 0.0
	ani.set("parameters/walk/blend_amount", walk_blend)

	if Input.is_action_just_pressed("lmb"):
		if not anim_locked:
			ani.set("parameters/mine/request", OneshotRequest.Fire)


var anim_locked := false
func _on_animation_tree_animation_started(_anim_name):
	anim_locked = true


func _on_animation_tree_animation_finished(_anim_name):
	anim_locked = false
