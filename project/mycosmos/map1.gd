extends Node3D


enum DebugInfo { None, Hex, Str }
var dbg := DebugInfo.Hex

enum Trig { rm1 }
const Trigger_str := ["rm1 triggered"]

func _ready() -> void:
	$mesh3.set_scale(Vector3.ZERO)
	$enemy.set_scale(Vector3.ZERO)
	$"../WorldEnvironment".get_environment().set_sdfgi_read_sky_light(false)
	$"../WorldEnvironment".get_environment().set_sdfgi_use_occlusion(true)


func _on_rm_mesh_1_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"): return
	if dbg >= DebugInfo.Str: print(Trigger_str[Trig.rm1])
	elif dbg >= DebugInfo.Hex: print(_int_to_hex_string(Trig.rm1))

	$mesh1.free()
	$mesh1_lm.free()
	$mesh3.set_scale(Vector3.ONE)
	$enemy.set_scale(Vector3.ONE)
	$rm_mesh1.queue_free()
	$"../WorldEnvironment".get_environment().set_sdfgi_read_sky_light(true)
	$"../WorldEnvironment".get_environment().set_sdfgi_use_occlusion(false)
	await RenderingServer.frame_post_draw
	$"../WorldEnvironment".get_environment().set_sdfgi_use_occlusion(true)

func _int_to_hex_string(num: int, padding: int = 2) -> String:
	var padding_zeros := ""
	for __ in padding: padding_zeros += "0"

	if num == 0: return "".join(["0x", padding_zeros])
	var hex_digits := "0123456789abcdef"
	var hex_string := ""
	while num > 0:
		var remainder := num & 15
		hex_string = hex_digits[remainder] + hex_string
		num = num / 16

	padding_zeros = padding_zeros.left(max(0, padding - len(hex_string)))
	return "".join(["0x", padding_zeros, hex_string])
