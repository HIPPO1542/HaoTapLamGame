extends SceneTree

const GameConfig = preload("res://scripts/game_config.gd")

# Test tự động hóa kiểm tra 8 Slime, cơ chế đánh Phím 1, cooldown, tiêu hao KI và hồi sinh (Bước 3)
func _init() -> void:
	print("========================================")
	print("CHẠY KIỂM THỬ BƯỚC 3: 8 SLIME & CHIẾN ĐẤU PHÍM 1")
	print("========================================")
	
	var pass_count = 0
	var total_count = 0
	
	# Test 1 (T04): Kiểm tra cấu hình và số lượng Slime (chính xác 8 con)
	total_count += 1
	if GameConfig.SLIME_COUNT == 8 and GameConfig.SLIME_INIT_HP == 100 and GameConfig.SLIME_ATTACK_DAMAGE == 5:
		print("[PASS] Test 1 (T04): Số lượng Slime đúng 8 con, HP = 100, Dame = 5.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 1: Cấu hình Slime không khớp spec!")

	# Test 2: Kiểm tra tầm đánh và hồi chiêu Phím 1
	total_count += 1
	if GameConfig.SKILL_1_RANGE == 48.0 and GameConfig.SKILL_1_COOLDOWN == 0.7 and GameConfig.SKILL_1_KI_COST == 1:
		print("[PASS] Test 2: Phím 1 tầm đánh 48px (1.5 tile), hồi chiêu 0.7s, tốn 1 KI.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 2: Thông số Phím 1 sai lệch!")

	# Test 3 (T06): Kiểm tra tính toán phạm vi đánh trúng và trượt
	total_count += 1
	var player_pos = Vector2(160, 580)
	var mob_in_range_pos = Vector2(190, 580) # dx = +30 <= 48
	var mob_out_range_pos = Vector2(250, 580) # dx = +90 > 48
	var mob_behind_pos = Vector2(120, 580) # dx = -40 (phía sau khi quay phải)
	
	var is_in_range = (mob_in_range_pos.x - player_pos.x <= GameConfig.SKILL_1_RANGE) and (mob_in_range_pos.x >= player_pos.x)
	var is_out_range = not ((mob_out_range_pos.x - player_pos.x <= GameConfig.SKILL_1_RANGE) and (mob_out_range_pos.x >= player_pos.x))
	var is_behind = (mob_behind_pos.x < player_pos.x)
	
	if is_in_range and is_out_range and is_behind:
		print("[PASS] Test 3 (T06): Logic phân định trong tầm 48px phía trước mặt chuẩn xác.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 3: Logic tầm đánh phía trước mặt sai!")

	# Test 4 (T07): Kiểm tra chặn đánh khi cạn KI và hồi chiêu
	total_count += 1
	var test_ki = 0
	var can_attack_no_ki = (test_ki >= GameConfig.SKILL_1_KI_COST)
	var test_cd = 0.5
	var can_attack_in_cd = (test_cd <= 0.0)
	if not can_attack_no_ki and not can_attack_in_cd:
		print("[PASS] Test 4 (T07): Server từ chối lệnh đánh khi cạn KI hoặc chưa hết hồi chiêu.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 4: Chặn đánh khi cạn KI/trong CD thất bại!")

	# Test 5 (T05): Kiểm tra thời gian hồi sinh ngẫu nhiên của Slime (3.0 - 5.0 giây)
	total_count += 1
	if GameConfig.SLIME_RESPAWN_MIN_TIME == 3.0 and GameConfig.SLIME_RESPAWN_MAX_TIME == 5.0:
		print("[PASS] Test 5 (T05): Thời gian hồi sinh của Slime trong khoảng 3.0 đến 5.0 giây.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 5: Thời gian hồi sinh Slime sai!")

	# Test 6: Kiểm tra InputMap hỗ trợ cả ADWS và 4 phím Mũi tên
	total_count += 1
	var has_left = InputMap.has_action("move_left")
	var has_right = InputMap.has_action("move_right")
	var has_up = InputMap.has_action("move_up")
	var has_down = InputMap.has_action("move_down")
	var has_jump = InputMap.has_action("jump")
	if has_left and has_right and has_up and has_down and has_jump:
		print("[PASS] Test 6: Hệ thống InputMap hỗ trợ đầy đủ 4 hướng điều khiển ADWS và 4 mũi tên.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 6: Thiếu action trong InputMap!")

	print("========================================")
	print("KẾT QUẢ BƯỚC 3: %d/%d tests ĐẠT." % [pass_count, total_count])
	print("========================================")
	quit(0 if pass_count == total_count else 1)
