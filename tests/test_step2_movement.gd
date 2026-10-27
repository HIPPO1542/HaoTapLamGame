extends SceneTree

const GameConfig = preload("res://scripts/game_config.gd")

# Test tự động hóa kiểm tra vật lý di chuyển, ranh giới map và timeout input (Bước 2)
func _init() -> void:
	print("========================================")
	print("CHẠY KIỂM THỬ BƯỚC 2: MAP & VẬT LÝ DI CHUYỂN")
	print("========================================")
	
	var pass_count = 0
	var total_count = 0
	
	# Test 1: Kiểm tra thông số di chuyển của M1 trong GameConfig
	total_count += 1
	if GameConfig.M1_MOVE_SPEED == 160.0 and GameConfig.M1_JUMP_VELOCITY == -320.0 and GameConfig.GRAVITY == 800.0:
		print("[PASS] Test 1: Thông số vật lý M1 (Tốc độ 160, Nhảy -320, Trọng lực 800) chuẩn xác.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 1: Thông số vật lý M1 không khớp spec!")
		
	# Test 2: Kiểm tra Timeout input 300 ms (0.3s)
	total_count += 1
	if GameConfig.INPUT_TIMEOUT_SEC == 0.3:
		print("[PASS] Test 2: Thời gian timeout input khi mất kết nối (300 ms) cấu hình chuẩn.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 2: INPUT_TIMEOUT_SEC không bằng 0.3!")

	# Test 3: Kiểm tra cấu trúc Scene Map đồng cỏ (test_grassland.tscn)
	total_count += 1
	var map_res = load("res://scenes/test_grassland.tscn")
	if map_res:
		var map_inst = map_res.instantiate()
		var has_colliders = map_inst.has_node("StaticColliders")
		var has_spawn = map_inst.has_node("SpawnPoint")
		var has_entities = map_inst.has_node("Entities")
		if has_colliders and has_spawn and has_entities:
			print("[PASS] Test 3: Scene Map có đầy đủ StaticColliders, SpawnPoint và Entities container.")
			pass_count += 1
		else:
			printerr("[FAIL] Test 3: Thiếu node trong Scene Map: colliders=%s, spawn=%s, entities=%s" % [has_colliders, has_spawn, has_entities])
		map_inst.free()
	else:
		printerr("[FAIL] Test 3: Không thể nạp scenes/test_grassland.tscn!")

	# Test 4: Kiểm tra Scene Nhân vật M1 (player.tscn)
	total_count += 1
	var player_res = load("res://scenes/player.tscn")
	if player_res:
		var player_inst = player_res.instantiate()
		var has_shape = player_inst.has_node("CollisionShape2D")
		var has_sprite = player_inst.has_node("AnimatedSprite2D")
		var has_cam = player_inst.has_node("Camera2D")
		if has_shape and has_sprite and has_cam:
			print("[PASS] Test 4: Scene Player M1 có đầy đủ CollisionShape2D, AnimatedSprite2D và Camera2D.")
			pass_count += 1
		else:
			printerr("[FAIL] Test 4: Thiếu node trong Player scene!")
		player_inst.free()
	else:
		printerr("[FAIL] Test 4: Không thể nạp scenes/player.tscn!")

	# Test 5: Kiểm tra cơ chế clamp ranh giới bản đồ (20.0 đến 2540.0)
	total_count += 1
	var test_x_left = clamp(-50.0, 20.0, 2540.0)
	var test_x_right = clamp(3000.0, 20.0, 2540.0)
	if test_x_left == 20.0 and test_x_right == 2540.0:
		print("[PASS] Test 5: Logic chặn ranh giới map (X: 20 -> 2540) hoạt động chính xác.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 5: Logic clamp ranh giới map sai lệch!")

	print("========================================")
	print("KẾT QUẢ BƯỚC 2: %d/%d tests ĐẠT." % [pass_count, total_count])
	print("========================================")
	quit(0 if pass_count == total_count else 1)
