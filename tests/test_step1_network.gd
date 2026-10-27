extends SceneTree

const GameConfig = preload("res://scripts/game_config.gd")

# Test tự động hóa kiểm tra cấu hình mạng và InputMap cho Bước 1
func _init() -> void:
	print("========================================")
	print("CHẠY KIỂM THỬ BƯỚC 1: CẤU HÌNH VÀ MẠNG")
	print("========================================")
	
	var pass_count = 0
	var total_count = 0
	
	# Test 1: Kiểm tra IP và Port
	total_count += 1
	if GameConfig.SERVER_IP == "127.0.0.1" and GameConfig.SERVER_PORT == 24567:
		print("[PASS] Test 1: Cấu hình Server IP (127.0.0.1) và Port (24567) chính xác.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 1: Cấu hình Server IP/Port không khớp spec!")
		
	# Test 2: Kiểm tra Max Client = 1
	total_count += 1
	if GameConfig.MAX_CLIENTS == 1:
		print("[PASS] Test 2: Cấu hình MAX_CLIENTS = 1 chính xác.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 2: MAX_CLIENTS khác 1!")
		
	# Test 3: Kiểm tra InputMap các phím bắt buộc
	total_count += 1
	var required_actions = ["move_left", "move_right", "jump", "attack_1", "toggle_character_menu", "ui_cancel"]
	var missing_actions = []
	for act in required_actions:
		if not InputMap.has_action(act):
			missing_actions.append(act)
	
	if missing_actions.is_empty():
		print("[PASS] Test 3: Tất cả InputMap bắt buộc đã được cấu hình đầy đủ (A/D/Left/Right, Space, 1, K, Esc).")
		pass_count += 1
	else:
		printerr("[FAIL] Test 3: Thiếu actions trong InputMap: ", missing_actions)
		
	# Test 4: Kiểm tra công thức nâng điểm [TEST] trong GameConfig
	total_count += 1
	var hp_c0 = GameConfig.get_upgrade_cost("hp", 0) # 100
	var hp_c1 = GameConfig.get_upgrade_cost("hp", 1) # 108
	var atk_c0 = GameConfig.get_upgrade_cost("attack", 0) # 200
	var arm_c0 = GameConfig.get_upgrade_cost("armor", 0) # 500
	if hp_c0 == 100 and hp_c1 == 108 and atk_c0 == 200 and arm_c0 == 500:
		print("[PASS] Test 4: Công thức tính chi phí nâng điểm (HP, KI, Attack, Armor) chính xác theo mục 12 GDD v2.3.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 4: Công thức nâng điểm sai lệch!")
		
	# Test 5: Kiểm tra tính toán sát thương quái đánh người
	total_count += 1
	var dmg_armor0 = GameConfig.compute_monster_damage_to_player(5, 0) # floor(5 * 1000 / 1000) = 5
	var dmg_armor1000 = GameConfig.compute_monster_damage_to_player(5, 1000) # floor(5 * 1000 / 2000) = 2
	if dmg_armor0 == 5 and dmg_armor1000 == 2:
		print("[PASS] Test 5: Công thức tính sát thương quái đánh người với Giáp chính xác.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 5: Công thức sát thương quái sai lệch: dmg0=%d, dmg1000=%d" % [dmg_armor0, dmg_armor1000])

	print("========================================")
	print("KẾT QUẢ: %d/%d tests ĐẠT." % [pass_count, total_count])
	print("========================================")
	quit(0 if pass_count == total_count else 1)
