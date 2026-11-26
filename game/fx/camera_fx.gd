class_name CameraFX
extends Camera3D
## Camera chính diện, giữa phòng: rung khi có va đập, loé đỏ khi có người chết, lớp hậu kỳ sepia + dither.

## Nhìn thẳng từ phía trước vào màn hình Cỗ Máy trên tường sau, cùng độ cao / khoảng cách / góc cúi như
## camera góc phòng cũ (sàn chơi vẫn nằm trọn phía trên dải bảng điểm).
const DEFAULT_BASE := Vector3(0.0, 4.95, 7.7)
const DEFAULT_LOOK := Vector3(0.0, 0.5, -0.8)
## Để đủ xa, camera đứng sau tường trước của buồng (mặt ngoài z = 7.0); mặt phẳng cắt gần cắt bỏ bức tường đó
## (mặt trong quay lưng về camera nên tự bị loại). Mọi thứ trong phòng đều cách camera hơn 3 m.
const NEAR_CLIP := 2.2
const RENDER_3D_HEIGHT := 450.0   # số dòng điểm ảnh của cảnh 3D (= window/size/viewport_height)

var base := DEFAULT_BASE
var look := DEFAULT_LOOK
var shake := 0.0
var flash := 0.0
var post_mat: ShaderMaterial
var shake_scale := 1.0


func _ready() -> void:
	fov = 54.0
	near = NEAR_CLIP
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
	get_viewport().size_changed.connect(fit_3d)
	fit_3d()


## Chữ / UI vẽ theo độ phân giải thật của màn hình (stretch "canvas_items") cho nét; riêng cảnh 3D vẫn vẽ
## ở khoảng RENDER_3D_HEIGHT dòng rồi phóng lên như trước: giữ phong cách thô và nhẹ máy (bản web, màn retina).
func fit_3d() -> void:
	var vp := get_viewport()
	var px := Vector2((vp as Window).size) if vp is Window else vp.get_visible_rect().size
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = render_scale(px)


## Tỉ lệ vẽ 3D cho khung hình cỡ `win` điểm ảnh (giữ tỉ lệ 16:9, có viền đen nếu cửa sổ khác tỉ lệ).
static func render_scale(win: Vector2) -> float:
	var content_h := minf(win.y, win.x * 9.0 / 16.0)
	if content_h <= 0.0:
		return 1.0
	return clampf(RENDER_3D_HEIGHT / content_h, 0.25, 1.0)


## Hướng nhìn ngang của camera (để xoay hướng điều khiển cho khớp màn hình): 0 = nhìn thẳng về -z.
static func yaw() -> float:
	return atan2(DEFAULT_BASE.x - DEFAULT_LOOK.x, DEFAULT_BASE.z - DEFAULT_LOOK.z)


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
