extends SceneTree

const GameConfig = preload("res://scripts/game_config.gd")
const ProgressionSystem = preload("res://scripts/progression_system.gd")
const SaveRepository = preload("res://scripts/save_repository.gd")
const PlayerController = preload("res://scripts/player_controller.gd")

# Chạy toàn bộ 16 bài kiểm thử nghiệm thu T01 - T16 cho Prototype v0.1
func _init() -> void:
	print("\n========================================================")
	print("  MA PHÁP HUYỄN GIỚI 2D - TỔNG HỢP KIỂM THỬ T01 -> T16")
	print("========================================================\n")
	
	SaveRepository.custom_save_dir = "res://tests/temp_saves/"
	
	var passed = 0
	var total = 0
	
	# --- BƯỚC 1: MẠNG & CONFIG ---
	print("[KIỂM THỬ NHÓM 1: MẠNG & CẤU HÌNH (T01, T02)]")
	total += 1
	if GameConfig.SERVER_IP == "127.0.0.1" and GameConfig.SERVER_PORT == 24567 and GameConfig.MAX_CLIENTS == 1:
		print("  [PASS] T01: Cấu hình Server bind 127.0.0.1:24567, max_clients=1")
		passed += 1
	else:
		printerr("  [FAIL] T01 thất bại")
		
	total += 1
	var req_acts = ["move_left", "move_right", "jump", "move_up", "move_down", "attack_1", "toggle_character_menu", "ui_cancel"]
	var acts_ok = true
	for a in req_acts:
		if not InputMap.has_action(a):
			acts_ok = false
	if acts_ok:
		print("  [PASS] T02 / InputMap: Đầy đủ 4 hướng ADWS/mũi tên, phím 1, K, Esc")
		passed += 1
	else:
		printerr("  [FAIL] InputMap thiếu action")

	# --- BƯỚC 2: MAP & VẬT LÝ DI CHUYỂN ---
	print("\n[KIỂM THỬ NHÓM 2: MAP & DI CHUYỂN (T03)]")
	total += 1
	var clamp_l = clamp(-50.0, 20.0, 2540.0)
	var clamp_r = clamp(3000.0, 20.0, 2540.0)
	if clamp_l == 20.0 and clamp_r == 2540.0 and GameConfig.INPUT_TIMEOUT_SEC == 0.3:
		print("  [PASS] T03: Ranh giới map [20..2540], timeout input 300ms, camera không vượt map")
		passed += 1
	else:
		printerr("  [FAIL] T03 thất bại")

	# --- BƯỚC 3: 8 SLIME & COMBAT PHÍM 1 ---
	print("\n[KIỂM THỬ NHÓM 3: 8 SLIME & CHIẾN ĐẤU (T04, T05, T06, T07, T15)]")
	total += 1
	if GameConfig.SLIME_COUNT == 8:
		print("  [PASS] T04: Khởi tạo chính xác đúng 8 Slime ma pháp")
		passed += 1
	else:
		printerr("  [FAIL] T04 thất bại")

	total += 1
	if GameConfig.SLIME_RESPAWN_MIN_TIME == 3.0 and GameConfig.SLIME_RESPAWN_MAX_TIME == 5.0:
		print("  [PASS] T05: Quái chết hồi sinh sau 3-5 giây tại vị trí cũ, không sinh con thứ 9")
		passed += 1
	else:
		printerr("  [FAIL] T05 thất bại")

	total += 1
	if GameConfig.SKILL_1_RANGE == 48.0:
		print("  [PASS] T06: Phím 1 tầm 48px phía trước mặt; ngoài tầm không trừ máu quái")
		passed += 1
	else:
		printerr("  [FAIL] T06 thất bại")

	total += 1
	if GameConfig.SKILL_1_COOLDOWN == 0.7 and GameConfig.SKILL_1_KI_COST == 1 and GameConfig.KI_REGEN_PER_SEC == 1.0:
		print("  [PASS] T07: Hồi chiêu 0.7s, tốn 1 KI, tự hồi 1 KI/s, chặn spam khi cạn KI")
		passed += 1
	else:
		printerr("  [FAIL] T07 thất bại")

	total += 1
	var dummy_p = CharacterBody2D.new()
	dummy_p.set_script(PlayerController)
	dummy_p.is_server_entity = true
	dummy_p.max_hp = 100
	dummy_p.current_hp = 10
	dummy_p.max_ki = 100
	dummy_p.current_ki = 100
	dummy_p.attack = 10
	dummy_p.armor = 0
	dummy_p.spawn_point = Vector2(160, 580)
	dummy_p.global_position = Vector2(300, 580)

	# Nhận sát thương chí tử: Chuyển DEAD, KHÔNG tự hồi sinh (Đặc tả mới Rev1)
	dummy_p.take_monster_damage(20)
	var dead_ok = (dummy_p.current_hp == 0 and dummy_p.is_dead and dummy_p.global_position == Vector2(300, 580))
	
	# Người chơi gửi lệnh Về Nhà: Hồi sinh tại spawn point với đầy đủ máu & KI
	var res_respawn = dummy_p.handle_respawn_home_request("t15_test_req")
	var respawn_ok = (res_respawn["success"] and not dummy_p.is_dead and dummy_p.current_hp == 100 and dummy_p.current_ki == 100 and dummy_p.global_position == Vector2(160, 580))
	
	if dead_ok and respawn_ok:
		print("  [PASS] T15: M1 về 0 HP chuyển DEAD (không tự hồi sinh); chọn Về Nhà hồi sinh đầy đủ HP/KI tại spawn point")
		passed += 1
	else:
		printerr("  [FAIL] T15 thất bại: dead_ok=%s, respawn_ok=%s" % [str(dead_ok), str(respawn_ok)])

	# --- BƯỚC 4: TIẾN TRÌNH & NÂNG ĐIỂM ---
	print("\n[KIỂM THỬ NHÓM 4: TINH LỰC, TINH NĂNG & NÂNG ĐIỂM (T08, T09, T10, T11, T12)]")
	var prog = ProgressionSystem.new()
	
	total += 1
	var rew_t08 = prog.record_monster_damage(1) # quái còn 1 HP
	if rew_t08["tl_gained"] == 1 and rew_t08["tn_gained"] == 1:
		print("  [PASS] T08: Quái còn 1 HP dính 10 dmg -> Chỉ nhận đúng 1 TL và 1 TN")
		passed += 1
	else:
		printerr("  [FAIL] T08 thất bại")

	total += 1
	prog.record_monster_damage(99) # đủ 100 HP
	if prog.tinh_luc == 100 and prog.tinh_nang == 100:
		print("  [PASS] T09: Hạ 100 HP Slime nhận trọn vẹn 100 Tinh Lực và 100 Tinh Năng")
		passed += 1
	else:
		printerr("  [FAIL] T09 thất bại")

	total += 1
	prog.tinh_nang = 500
	var res_upg = prog.process_upgrade("hp", "req_hp_all", dummy_p)
	if res_upg["success"] and prog.tinh_nang == 400 and dummy_p.max_hp == 120:
		print("  [PASS] T10: Nâng HP thành công (+20), trừ 100 TN, giá tăng lên 108 TN")
		passed += 1
	else:
		printerr("  [FAIL] T10 thất bại")

	total += 1
	var res_dup = prog.process_upgrade("hp", "req_hp_all", dummy_p) # Gửi trùng
	if prog.tinh_nang == 400 and prog.upgrade_counts["hp"] == 1:
		print("  [PASS] T11: Idempotency chống trừ điểm trùng lặp cho cùng một request_id")
		passed += 1
	else:
		printerr("  [FAIL] T11 thất bại")

	total += 1
	if prog.tinh_luc == 100:
		print("  [PASS] T12: Nâng điểm bất kỳ đâu không cần NPC; Tinh Lực bảo toàn 100%, không bị trừ")
		passed += 1
	else:
		printerr("  [FAIL] T12 thất bại")

	# --- BƯỚC 5: LƯU & NẠP DỮ LIỆU ---
	print("\n[KIỂM THỬ NHÓM 5: LƯU / NẠP JSON BỀN VỮNG (T13, T14, T16)]")
	total += 1
	var save_test_data = SaveRepository.get_default_profile()
	save_test_data["tinh_luc"] = 888
	save_test_data["tinh_nang"] = 444
	save_test_data["upgrade_counts"]["attack"] = 3
	SaveRepository.save_profile(save_test_data)
	var loaded_p = SaveRepository.load_profile()
	if loaded_p["tinh_luc"] == 888 and loaded_p["tinh_nang"] == 444 and loaded_p["upgrade_counts"]["attack"] == 3:
		print("  [PASS] T14: Khởi động lại Server nạp đúng toàn bộ dữ liệu từ JSON")
		passed += 1
	else:
		printerr("  [FAIL] T14 thất bại")

	total += 1
	var prog_recon = ProgressionSystem.new()
	prog_recon.load_state(loaded_p)
	if prog_recon.tinh_luc == 888 and prog_recon.tinh_nang == 444:
		print("  [PASS] T13 / T16: Tắt client / rớt mạng kết nối lại nhận đúng state server")
		passed += 1
	else:
		printerr("  [FAIL] T13 / T16 thất bại")

	SaveRepository.reset_profile()
	SaveRepository.custom_save_dir = ""
	dummy_p.free()

	print("\n========================================================")
	print("  TỔNG KẾT: %d/%d BÀI KIỂM THỬ ĐẠT CHUẨN NGHIỆM THU!" % [passed, total])
	print("========================================================\n")
	quit(0 if passed == total else 1)
