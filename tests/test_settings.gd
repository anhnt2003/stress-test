extends RefCounted
## Cài đặt: lưu rồi đọc lại đúng giá trị, giá trị hỏng bị kẹp lại.

const PATH := "user://test_settings.cfg"


func run(t) -> void:
	var s := Settings.load_or_default(PATH + ".missing")
	t.ok("mặc định có token", s.token.length() == 16)
	s.music = 0.25
	s.gore = false
	s.resolution = 3
	s.player_name = "ĐỐI TƯỢNG"
	t.check("lưu", s.save(PATH), OK)
	var r := Settings.load_or_default(PATH)
	t.check("đọc nhạc", r.music, 0.25)
	t.check("đọc máu me", r.gore, false)
	t.check("đọc độ phân giải", r.resolution, 3)
	t.check("đọc tên", r.player_name, "ĐỐI TƯỢNG")
	t.check("giữ token", r.token, s.token)
	var cf := ConfigFile.new()
	cf.set_value("settings", "resolution", 99)
	cf.set_value("settings", "master", 7.0)
	cf.save(PATH)
	var b := Settings.load_or_default(PATH)
	t.check("kẹp độ phân giải", b.resolution, Settings.RESOLUTIONS.size() - 1)
	t.check("kẹp âm lượng", b.master, 1.0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
