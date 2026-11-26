extends SceneTree
## Công cụ chuyển một lần: dựng buồng thử và các màn giao diện bằng code rồi lưu thành file .tscn.
## Sau khi chạy, các file .tscn là nguồn chính (sửa trong editor). Chạy lại sẽ GHI ĐÈ mọi chỉnh sửa tay.
## Chạy: godot --headless --path . --script res://tools/migrate_scenes.gd [-- chamber|ui]

const UI := preload("res://game/ui/ui_builder.gd")
const CH := preload("res://game/world/chamber_builder.gd")


func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_own(c, owner_node)


func _save(root: Node, path: String) -> bool:
	_own(root, root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		printerr("pack failed ", path, " ", err)
		return false
	err = ResourceSaver.save(ps, path)
	root.free()
	if err != OK:
		printerr("save failed ", path, " ", err)
		return false
	print("saved ", path)
	return true


func _init() -> void:
	var what := "all"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		what = args[0]
	var ok := true
	seed(2024)
	if what == "all" or what == "chamber":
		for v in CH.VARIANTS.size():
			ok = _save(CH.build(v), "res://game/world/" + String(CH.VARIANTS[v].file)) and ok
	if what == "all" or what == "ui":
		ok = _save(UI.hud(), "res://game/ui/hud.tscn") and ok
		ok = _save(UI.intro_banner(), "res://game/ui/intro_banner.tscn") and ok
		ok = _save(UI.result_panel(), "res://game/ui/result_panel.tscn") and ok
		ok = _save(UI.lobby_panel(), "res://game/ui/lobby_panel.tscn") and ok
		ok = _save(UI.main_menu(), "res://game/ui/main_menu.tscn") and ok
		ok = _save(UI.pause_menu(), "res://game/ui/pause_menu.tscn") and ok
		ok = _save(UI.settings_menu(), "res://game/ui/settings_menu.tscn") and ok
		ok = _save(UI.join_dialog(), "res://game/ui/join_dialog.tscn") and ok
	quit(0 if ok else 1)
