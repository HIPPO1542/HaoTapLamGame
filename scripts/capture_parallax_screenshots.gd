extends SceneTree

# Kịch bản kiểm thử hiệu ứng chiều sâu Parallax và chụp ảnh tại các vị trí Camera khác nhau
# Kiểm tra ở 1280x720 và 1600x900

var current_step = 0
var timer = 0.0

var map_inst = null
var player_inst = null
var hud_inst = null
var slimes = []

func _init() -> void:
	DirAccess.make_dir_absolute("res://screenshots")
	print("\n[Parallax Test] Khởi tạo Scene Map kiểm thử chiều sâu Parallax...")

	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)

	# 1. Map
	var map_scene = load("res://scenes/test_grassland.tscn")
	map_inst = map_scene.instantiate()
	root.add_child(map_inst)

	# 2. Player
	var player_scene = load("res://scenes/player.tscn")
	player_inst = player_scene.instantiate()
	player_inst.is_server_entity = true
	player_inst.global_position = Vector2(240, 580)
	map_inst.get_node("Entities").add_child(player_inst)

	# Bật camera của player
	var cam = player_inst.get_node_or_null("Camera2D")
	if cam:
		cam.enabled = true
		cam.limit_left = 0
		cam.limit_right = 2560
		cam.limit_top = 0
		cam.limit_bottom = 720
		cam.position_smoothing_enabled = false

	# 3. 8 Slimes
	var slime_scene = load("res://scenes/slime.tscn")
	for i in range(8):
		var s = slime_scene.instantiate()
		s.init_slime(i, Vector2(500.0 + i * 200.0, 580.0), true)
		map_inst.get_node("Entities").add_child(s)
		slimes.append(s)

	# 4. HUD
	var hud_scene = load("res://scenes/ui/hud.tscn")
	hud_inst = hud_scene.instantiate()
	root.add_child(hud_inst)
	hud_inst.update_status(100, 100, 100, 100, 2400, 850)

func _process(delta: float) -> bool:
	timer += delta
	if timer < 0.25:
		return false
	
	timer = 0.0
	current_step += 1

	if current_step == 1:
		# Vị trí 1: Đầu map (X = 240) - 1280x720
		player_inst.global_position = Vector2(240, 580)
		_save_screenshot("res://screenshots/map_pos1_spawn_1280x720.png")
		print("[Parallax Test] Đã chụp ảnh 1: Vị trí Camera 1 (Đầu map Spawn X=240, 1280x720)")
		return false

	elif current_step == 2:
		# Vị trí 2: Giữa map (X = 1100) - 1280x720
		# Camera cuộn 860px sang phải chứng minh các lớp trôi với vận tốc khác biệt
		player_inst.global_position = Vector2(1100, 580)
		return false

	elif current_step == 3:
		_save_screenshot("res://screenshots/map_pos2_mid_1280x720.png")
		print("[Parallax Test] Đã chụp ảnh 2: Vị trí Camera 2 (Giữa map Combat X=1100, 1280x720)")
		return false

	elif current_step == 4:
		# Vị trí 3: Cuối map (X = 2200) - 1280x720
		player_inst.global_position = Vector2(2200, 580)
		return false

	elif current_step == 5:
		_save_screenshot("res://screenshots/map_pos3_end_1280x720.png")
		print("[Parallax Test] Đã chụp ảnh 3: Vị trí Camera 3 (Cuối map X=2200, 1280x720)")

		# Đổi độ phân giải sang 1600x900
		DisplayServer.window_set_size(Vector2i(1600, 900))
		root.size = Vector2i(1600, 900)
		player_inst.global_position = Vector2(800, 580)
		return false

	elif current_step == 6:
		# Vị trí 4: Responsive ở 1600x900
		_save_screenshot("res://screenshots/map_responsive_1600x900.png")
		print("[Parallax Test] Đã chụp ảnh 4: Responsive Map (1600x900 tại X=800)")

		print("\n[Parallax Test] HOÀN TẤT THÀNH CÔNG KIỂM THỬ CHIỀU SÂU PARALLAX & BẢN ĐỒ!")
		quit(0)
		return true

	return false

func _save_screenshot(path: String) -> void:
	var img = root.get_texture().get_image()
	if img:
		img.save_png(path)
		print("  -> Đã lưu ảnh: ", path, " (%dx%d)" % [img.get_width(), img.get_height()])
	else:
		printerr("  -> LỖI: Không thể chụp ảnh viewport!")
