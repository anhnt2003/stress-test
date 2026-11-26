class_name Chamber
extends Node3D
## Buồng thử (nạp từ chamber_*.tscn): quạt trần, đèn báo động, đèn chập chờn, màn hình của Cỗ Máy.

const SCENES := ["res://game/world/chamber_09.tscn", "res://game/world/chamber_13.tscn", "res://game/world/chamber_21.tscn"]

@onready var fan: Node3D = %Fan
@onready var beacon: Node3D = %Beacon
@onready var flicker_light: OmniLight3D = %FlickerLight
@onready var flicker_lamp: MeshInstance3D = %FlickerLamp
@onready var cam_led: MeshInstance3D = %CamLed
@onready var monitor: Label3D = %Monitor
@onready var gore_props: Node3D = %GoreProps
var tubes: Node3D

var monitor_t := 0.0
var _idle_text := ""
var _gore := true


func _ready() -> void:
	tubes = get_node_or_null("%Tubes")
	set_gore(_gore)


static func create(variant: int) -> Chamber:
	return (load(SCENES[clampi(variant, 0, SCENES.size() - 1)]) as PackedScene).instantiate()


func animate(t: float, dt: float) -> void:
	fan.rotation.y += dt * 1.6
	beacon.rotation.y += dt * 2.4
	var on := not (fmod(t, 2.9) < 0.12 or (fmod(t, 6.1) > 2.0 and fmod(t, 6.1) < 2.5 and fmod(t, 0.16) < 0.08))
	flicker_light.light_energy = 1.6 if on else 0.05
	(flicker_lamp.material_override as StandardMaterial3D).emission_energy_multiplier = 4.0 if on else 0.2
	(cam_led.material_override as StandardMaterial3D).emission_energy_multiplier = 4.0 if fmod(t, 1.2) < 0.6 else 0.2
	if tubes:   # đèn tuýp buồng 13 thỉnh thoảng nháy
		tubes.visible = not (fmod(t, 4.3) < 0.07 or (fmod(t, 9.7) > 6.0 and fmod(t, 9.7) < 6.25 and fmod(t, 0.1) < 0.05))
	monitor_t = maxf(0.0, monitor_t - dt)
	if monitor_t <= 0.0:
		var cur := "_" if fmod(t, 1.0) < 0.5 else " "
		monitor.text = _idle_text + cur
		monitor.modulate = Palette.AMBER
		monitor.visible = true
	else:
		monitor.visible = fmod(monitor_t, 0.5) > 0.12


## Dòng chữ thường trực trên màn hình (con trỏ nhấp nháy được thêm vào cuối).
func set_idle(text: String) -> void:
	_idle_text = text


## Báo động trên màn hình trong `dur` giây.
func alert(text: String, color := Color(1.0, 0.15, 0.1), dur := 2.6) -> void:
	monitor_t = dur
	monitor.text = text
	monitor.modulate = color


func clear_alert() -> void:
	monitor_t = 0.0


func set_gore(on: bool) -> void:
	_gore = on
	if not is_node_ready():
		return
	gore_props.visible = on
	for path in ["Room/Floor", "Room/WallBack"]:
		var mi := get_node_or_null(path) as MeshInstance3D
		if mi and mi.material_override is ShaderMaterial:
			(mi.material_override as ShaderMaterial).set_shader_parameter("gore", 1.0 if on else 0.0)
