class_name CameraFX
extends Camera3D
## Camera góc phòng: rung khi có va đập, loé đỏ khi có người chết, lớp hậu kỳ sepia + dither.

const DEFAULT_BASE := Vector3(5.2, 4.95, 5.7)
const DEFAULT_LOOK := Vector3(-0.6, 0.5, -0.5)

var base := DEFAULT_BASE
var look := DEFAULT_LOOK
var shake := 0.0
var flash := 0.0
var post_mat: ShaderMaterial
var shake_scale := 1.0


func _ready() -> void:
	fov = 54.0
	current = true
	var post_layer := CanvasLayer.new()
	post_layer.layer = 1
	add_child(post_layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_mat = Build.shader_mat("res://shaders/post.gdshader")
	rect.material = post_mat
	post_layer.add_child(rect)


## Hướng nhìn ngang của camera góc phòng (để xoay hướng điều khiển cho khớp màn hình).
static func yaw() -> float:
	return atan2(5.2 - (-0.6), 5.7 - (-0.5))


func frame(b: Vector3, l: Vector3) -> void:
	base = b
	look = l
	position = base
	look_at(look)
	reset_physics_interpolation()   # đổi cửa: nhảy cảnh, không lướt camera


func kick(amount: float) -> void:
	shake = maxf(shake, amount)


func blink(amount := 1.0) -> void:
	flash = maxf(flash, amount)


func reset_fx() -> void:
	shake = 0.0
	flash = 0.0


func decay(dt: float) -> void:
	flash = maxf(0.0, flash - dt * 2.5)
	shake = maxf(0.0, shake - dt * 2.5)


func update(t: float) -> void:
	post_mat.set_shader_parameter("flash", flash)
	position = base + Vector3(sin(t * 0.25) * 0.08, sin(t * 90.0) * 0.1 * shake * shake_scale, 0)
