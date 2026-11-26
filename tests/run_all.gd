extends SceneTree
## Chạy toàn bộ kiểm thử: godot --headless --path . --script res://tests/run_all.gd [-- tên_file]
## Mỗi file tests/test_*.gd có hàm run(t) gọi t.check(...). Thoát mã 1 nếu có kiểm tra hỏng.

var failed := 0
var passed := 0
var _suite := ""


func check(name: String, got, want) -> void:
	if typeof(got) == typeof(want) and got == want or str(got) == str(want):
		passed += 1
	else:
		failed += 1
		printerr("FAIL [%s] %s: got %s, want %s" % [_suite, name, str(got), str(want)])


func ok(name: String, cond: bool) -> void:
	check(name, cond, true)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame   # chờ cây scene sẵn sàng
	var only := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		only = args[0]
	var files := Array(DirAccess.get_files_at("res://tests"))
	files.sort()
	for f in files:
		if not (f.begins_with("test_") and f.ends_with(".gd")) or (only != "" and not f.contains(only)):
			continue
		_suite = f.get_basename()
		var before := failed
		var t = load("res://tests/" + f).new()
		if t.has_method("run"):
			t.run(self)
		if t.has_method("run_async"):
			await t.run_async(self)
		print("%s %s" % ["ok  " if failed == before else "FAIL", _suite])
	print("%d đạt, %d hỏng" % [passed, failed])
	quit(1 if failed > 0 else 0)
