extends SceneTree

const GameConfig = preload("res://scripts/game_config.gd")
const ProgressionSystem = preload("res://scripts/progression_system.gd")
const PlayerController = preload("res://scripts/player_controller.gd")

# Test tự động hóa kiểm tra Tinh Lực, Tinh Năng, nâng chỉ số, idempotency (Bước 4)
func _init() -> void:
	print("========================================")
	print("CHẠY KIỂM THỬ BƯỚC 4: TINH LỰC, TINH NĂNG & NÂNG CHỈ SỐ")
	print("========================================")
	
	var pass_count = 0
	var total_count = 0
	
	var prog = ProgressionSystem.new()
	
	# Test 1 (T08): Mob còn 1 HP, trúng 10 damage -> Chỉ +1 Tinh Lực và +1 Tinh Năng
	total_count += 1
	var mob_hp = 1
	var computed_damage = 10
	var actual_lost = mini(maxi(0, computed_damage), mob_hp) # actual_lost = 1
	var reward_t08 = prog.record_monster_damage(actual_lost)
	if reward_t08["tl_gained"] == 1 and reward_t08["tn_gained"] == 1 and prog.tinh_luc == 1 and prog.tinh_nang == 1:
		print("[PASS] Test 1 (T08): Mob còn 1 HP nhận 10 dmg -> Chỉ nhận đúng 1 Tinh Lực và 1 Tinh Năng.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 1: T08 thất bại: TL=%d, TN=%d" % [prog.tinh_luc, prog.tinh_nang])

	# Test 2 (T09): Hạ hết 100 HP Slime từ đầu -> Tổng điểm nhận đúng 100 TL và 100 TN
	total_count += 1
	var fresh_prog = ProgressionSystem.new()
	var slime_hp = 100
	var hit_count = 10 # Mỗi hit 10 damage
	for i in range(hit_count):
		var hit_lost = mini(10, slime_hp)
		slime_hp -= hit_lost
		fresh_prog.record_monster_damage(hit_lost)
		
	if fresh_prog.tinh_luc == 100 and fresh_prog.tinh_nang == 100 and slime_hp == 0:
		print("[PASS] Test 2 (T09): Hạ gục Slime 100 HP nhận chính xác 100 Tinh Lực và 100 Tinh Năng.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 2: T09 thất bại: TL=%d, TN=%d, SlimeHP=%d" % [fresh_prog.tinh_luc, fresh_prog.tinh_nang, slime_hp])

	# Test 3 (T10): Nâng chỉ số HP (giá 100), KI (giá 100), Công Lực (giá 200), Giáp (giá 500)
	total_count += 1
	var dummy_player = CharacterBody2D.new()
	dummy_player.set_script(PlayerController)
	dummy_player.max_hp = 100
	dummy_player.current_hp = 100
	dummy_player.max_ki = 100
	dummy_player.current_ki = 100
	dummy_player.attack = 10
	dummy_player.armor = 0
	
	# Cấp 1000 Tinh Năng để test nâng
	fresh_prog.tinh_nang = 1000
	var res_hp = fresh_prog.process_upgrade("hp", "req_hp_1", dummy_player)
	var cost_hp2 = GameConfig.get_upgrade_cost("hp", fresh_prog.upgrade_counts["hp"])
	
	if res_hp["success"] and fresh_prog.tinh_nang == 900 and dummy_player.max_hp == 120 and cost_hp2 == 108:
		print("[PASS] Test 3 (T10): Nâng HP thành công: Máu 100 -> 120, TN còn 900, giá lần sau tăng lên 108.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 3: T10 nâng HP sai!")

	# Test 4 (T10 tiếp theo - Chặn âm điểm khi thiếu Tinh Năng):
	total_count += 1
	fresh_prog.tinh_nang = 50 # Thiếu so với giá Giáp (500)
	var res_arm_fail = fresh_prog.process_upgrade("armor", "req_arm_fail", dummy_player)
	if not res_arm_fail["success"] and fresh_prog.tinh_nang == 50 and dummy_player.armor == 0:
		print("[PASS] Test 4 (T10): Thiếu Tinh Năng -> Từ chối nâng, không thay đổi chỉ số, không âm điểm.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 4: Không chặn được khi thiếu Tinh Năng!")

	# Test 5 (T11): Gửi 2 lần cùng một request_id nâng điểm -> Chỉ trừ 1 lần duy nhất
	total_count += 1
	fresh_prog.tinh_nang = 300
	var dup_req_id = "req_dup_001"
	var res_atk_1 = fresh_prog.process_upgrade("attack", dup_req_id, dummy_player) # Giá 200, còn 100
	var res_atk_2 = fresh_prog.process_upgrade("attack", dup_req_id, dummy_player) # Gửi trùng!
	if res_atk_1["success"] and fresh_prog.tinh_nang == 100 and fresh_prog.upgrade_counts["attack"] == 1:
		print("[PASS] Test 5 (T11): Idempotency: Gửi 2 lần cùng request_id chỉ xử lý 1 lần, không bị trừ 2 lần.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 5: Idempotency thất bại: TN=%d, count=%d" % [fresh_prog.tinh_nang, fresh_prog.upgrade_counts["attack"]])

	# Test 6 (T12): Tinh Lực không bao giờ bị trừ khi nâng chỉ số
	total_count += 1
	if fresh_prog.tinh_luc == 100:
		print("[PASS] Test 6 (T12): Tinh Lực được bảo toàn nguyên vẹn (100 TL), không bị trừ khi nâng cấp.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 6: Tinh Lực bị trừ sai quy tắc!")

	print("========================================")
	print("KẾT QUẢ BƯỚC 4: %d/%d tests ĐẠT." % [pass_count, total_count])
	print("========================================")
	dummy_player.free()
	quit(0 if pass_count == total_count else 1)
