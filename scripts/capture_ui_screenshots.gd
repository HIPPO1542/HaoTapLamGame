extends SceneTree

var current_step = 0
var timer = 0.0

var map_inst = null
var player_inst = null
var hud_inst = null
var char_panel_inst = null
var death_panel_inst = null

func _init() -> void:
	DirAccess.make_dir_absolute("res://screenshots")
	print("\n[Screenshot Generator] Bắt đầu khởi tạo chụp ảnh UI...")

	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)

	# 1. Map & Player (giả lập thế giới)
	var map_scene = load("res://scenes/test_grassland.tscn")
	map_inst = map_scene.instantiate()
	root.add_child(map_inst)

	var player_scene = load("res://scenes/player.tscn")
	player_inst = player_scene.instantiate()
	player_inst.is_server_entity = true # Ngăn chặn client rpc khi không nối server
	player_inst.global_position = Vector2(240, 580)
	map_inst.get_node("Entities").add_child(player_inst)

	# 2. UI Scenes
	var hud_scene = load("res://scenes/ui/hud.tscn")
	hud_inst = hud_scene.instantiate()
	root.add_child(hud_inst)

	var char_scene = load("res://scenes/ui/character_stats_panel.tscn")
	char_panel_inst = char_scene.instantiate()
	root.add_child(char_panel_inst)

	var death_scene = load("res://scenes/ui/death_respawn_panel.tscn")
	death_panel_inst = death_scene.instantiate()
	root.add_child(death_panel_inst)

	char_panel_inst.visible = false
	death_panel_inst.visible = false

func _process(delta: float) -> bool:
	timer += delta
	if timer < 0.25:
		return false # Chờ 0.25s
	
	timer = 0.0
	current_step += 1

	if current_step == 1:
		hud_inst.update_status(95, 100, 78, 100, 1250, 480)
		hud_inst.visible = true
		_save_screenshot("res://screenshots/ui_hud_1280x720.png")
		print("[Screenshot Generator] Đã chụp ảnh 1: HUD 1280x720")

		# Chuẩn bị Menu K
		char_panel_inst.visible = true
		char_panel_inst.current_tl = 1250
		char_panel_inst.current_tn = 480
		char_panel_inst.current_stats = {
			"hp_current": 95, "hp_max": 120,
			"ki_current": 78, "ki_max": 120,
			"attack": 12, "armor": 1
		}
		char_panel_inst.current_counts = {
			"hp": 1, "ki": 1, "attack": 2, "armor": 1
		}
		char_panel_inst._update_ui()
		return false

	elif current_step == 2:
		# Chụp ảnh 2: Menu K ở 1280x720
		_save_screenshot("res://screenshots/ui_menu_k_1280x720.png")
		print("[Screenshot Generator] Đã chụp ảnh 2: Menu K 1280x720")

		char_panel_inst.visible = false
		death_panel_inst.open_panel()
		return false

	elif current_step == 3:
		# Chụp ảnh 3: Bảng Hồi sinh ở 1280x720
		_save_screenshot("res://screenshots/ui_respawn_1280x720.png")
		print("[Screenshot Generator] Đã chụp ảnh 3: Respawn 1280x720")

		# Đổi kích thước cửa sổ 1600x900 để test responsive
		DisplayServer.window_set_size(Vector2i(1600, 900))
		root.size = Vector2i(1600, 900)
		death_panel_inst.visible = false
		return false

	elif current_step == 4:
		# Chụp ảnh 4: HUD responsive ở 1600x900
		_save_screenshot("res://screenshots/ui_hud_1600x900.png")
		print("[Screenshot Generator] Đã chụp ảnh 4: HUD 1600x900")

		char_panel_inst.visible = true
		return false

	elif current_step == 5:
		# Chụp ảnh 5: Menu K responsive ở 1600x900
		_save_screenshot("res://screenshots/ui_menu_k_1600x900.png")
		print("[Screenshot Generator] Đã chụp ảnh 5: Menu K 1600x900")

		char_panel_inst.visible = false
		death_panel_inst.open_panel()
		return false

	elif current_step == 6:
		# Chụp ảnh 6: Respawn responsive ở 1600x900
		_save_screenshot("res://screenshots/ui_respawn_1600x900.png")
		print("[Screenshot Generator] Đã chụp ảnh 6: Respawn 1600x900")

		print("\n[Screenshot Generator] HOÀN TẤT TOÀN BỘ 6 ẢNH CHỤP GIAO DIỆN CHUẨN XÁC!")
		quit(0)
		return true

	return false

func _save_screenshot(path: String) -> void:
	var img = root.get_texture().get_image()
	if img:
		img.save_png(path)
		print("  -> Đã lưu file: ", path, " (size: %dx%d)" % [img.get_width(), img.get_height()])
	else:
		printerr("  -> LỖI: Không thể lấy viewport image!")
