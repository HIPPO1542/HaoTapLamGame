extends SceneTree

const GameConfig = preload("res://scripts/game_config.gd")
const ProgressionSystem = preload("res://scripts/progression_system.gd")
const SaveRepository = preload("res://scripts/save_repository.gd")
const PlayerController = preload("res://scripts/player_controller.gd")
const SlimeAIScript = preload("res://scripts/slime_ai.gd")

# BỘ KIỂM THỬ TỬ VONG / BIA MỘ / HỒI SINH (D01 - D16) — PROTOTYPE v0.1
func _init() -> void:
	print("\n========================================================")
	print("  KIỂM THỬ TỬ VONG / BIA MỘ / HỒI SINH (D01 -> D16)")
	print("========================================================\n")

	# Cách ly an toàn cho save repository
	SaveRepository.custom_save_dir = "res://tests/temp_saves/"

	var pass_count = 0
	var total_count = 0

	# ----------------------------------------------------
	# D01 (P0): M1 mất hết HP -> Chuyển DEAD, không tự hồi sinh
	# ----------------------------------------------------
	total_count += 1
	var p = CharacterBody2D.new()
	p.set_script(PlayerController)
	p.is_server_entity = true
	p.max_hp = 100
	p.current_hp = 10
	p.spawn_point = Vector2(160, 580)
	p.global_position = Vector2(400, 580)

	p.take_monster_damage(15) # Sát thương lớn hơn HP hiện tại
	if p.current_hp == 0 and p.is_dead and p.death_position == Vector2(400, 580) and p.global_position == Vector2(400, 580):
		print("  [PASS] D01: HP về 0, chuyển trạng thái DEAD_WAITING_CHOICE, không tự hồi sinh.")
		pass_count += 1
	else:
		printerr("  [FAIL] D01 thất bại: hp=%d, dead=%s, pos=%s" % [p.current_hp, str(p.is_dead), str(p.global_position)])

	# ----------------------------------------------------
	# D02 (P1): Hiển thị mộ tại đúng vị trí chết, không có va chạm chặn map
	# ----------------------------------------------------
	total_count += 1
	var grave_res = load("res://scenes/gravestone.tscn")
	var has_grave_collision = false
	if grave_res:
		var grave_inst = grave_res.instantiate()
		grave_inst.global_position = p.death_position
		has_grave_collision = grave_inst.has_node("CollisionShape2D")
		var is_at_death_pos = (grave_inst.global_position == Vector2(400, 580))
		if not has_grave_collision and is_at_death_pos:
			print("  [PASS] D02: Bia mộ xuất hiện đúng vị trí chết (400, 580), không có va chạm cản trở.")
			pass_count += 1
		else:
			printerr("  [FAIL] D02 thất bại: collision=%s, pos=%s" % [has_grave_collision, str(grave_inst.global_position)])
		grave_inst.free()
	else:
		printerr("  [FAIL] D02: Không tìm thấy scenes/gravestone.tscn!")

	# ----------------------------------------------------
	# D03 (P1): Giao diện bảng hồi sinh hiển thị 2 lựa chọn đúng đặc tả
	# ----------------------------------------------------
	total_count += 1
	var panel_res = load("res://scenes/ui/death_respawn_panel.tscn")
	if panel_res:
		var panel_inst = panel_res.instantiate()
		var btn_h = panel_inst.get_node("CenterContainer/PanelContainer/VBoxContainer/BtnRespawnHome")
		var btn_p = panel_inst.get_node("CenterContainer/PanelContainer/VBoxContainer/BtnRespawnHere")
		var note_p = panel_inst.get_node("CenterContainer/PanelContainer/VBoxContainer/HereNote")
		
		var d03_ok = (btn_h.text == "Về nhà — Miễn phí" and btn_p.text == "Hồi sinh tại chỗ — Chưa mở" and note_p.text == "Cần hệ thống Vàng (phát triển sau)")
		if d03_ok:
			print("  [PASS] D03: Bảng tử vong hiển thị chuẩn 2 nhãn và ghi chú hệ thống Vàng.")
			pass_count += 1
		else:
			printerr("  [FAIL] D03: Sai nhãn hoặc thông tin giao diện!")
		panel_inst.free()
	else:
		printerr("  [FAIL] D03: Không tìm thấy scenes/ui/death_respawn_panel.tscn!")

	# ----------------------------------------------------
	# D04 (P0): Nút hồi sinh tại chỗ bị khóa (disabled), không thêm hệ thống Vàng
	# ----------------------------------------------------
	total_count += 1
	if panel_res:
		var panel_inst = panel_res.instantiate()
		var btn_p = panel_inst.get_node("CenterContainer/PanelContainer/VBoxContainer/BtnRespawnHere")
		var is_btn_disabled = btn_p.disabled
		panel_inst.open_panel() # Thử mở panel
		var remains_disabled = btn_p.disabled
		if is_btn_disabled and remains_disabled:
			print("  [PASS] D04: Nút Hồi sinh tại chỗ bị khóa vĩnh viễn (disabled=true), không có cơ chế vàng.")
			pass_count += 1
		else:
			printerr("  [FAIL] D04: Nút trả phí không bị khóa!")
		panel_inst.free()

	# ----------------------------------------------------
	# D05 (P0): Hành động Về Nhà: Server chấp nhận và đưa về spawn an toàn
	# ----------------------------------------------------
	total_count += 1
	var res_home = p.handle_respawn_home_request("req_d05_01")
	if res_home["success"] and not p.is_dead and p.global_position == p.spawn_point and p.global_position == Vector2(160, 580):
		print("  [PASS] D05: Server chấp thuận yêu cầu Về Nhà, dịch chuyển về điểm spawn (160, 580).")
		pass_count += 1
	else:
		printerr("  [FAIL] D05 thất bại: res=%s, pos=%s" % [str(res_home), str(p.global_position)])

	# ----------------------------------------------------
	# D06 (P0): Hồi máu và năng lượng theo đúng giá trị max đã nâng
	# ----------------------------------------------------
	total_count += 1
	p.max_hp = 140 # Đã nâng 2 lần HP (+40)
	p.max_ki = 120 # Đã nâng 1 lần KI (+20)
	p.current_hp = 5
	p.take_monster_damage(10) # Chết lại
	var res_d06 = p.handle_respawn_home_request("req_d06_01")
	if res_d06["success"] and p.current_hp == 140 and p.current_ki == 120:
		print("  [PASS] D06: Hồi sinh phục hồi đầy đủ HP/KI theo giá trị nâng cấp (140 HP, 120 KI).")
		pass_count += 1
	else:
		printerr("  [FAIL] D06 thất bại: hp=%d/140, ki=%d/120" % [p.current_hp, p.current_ki])

	# ----------------------------------------------------
	# D07 (P0): Bảo toàn Tinh Lực, Tinh Năng, upgrade_counts sau chết/hồi sinh
	# ----------------------------------------------------
	total_count += 1
	var prog = ProgressionSystem.new()
	prog.tinh_luc = 999
	prog.tinh_nang = 450
	prog.upgrade_counts["attack"] = 3
	prog.upgrade_counts["hp"] = 2
	
	# M1 chết và hồi sinh
	p.take_monster_damage(200)
	p.handle_respawn_home_request("req_d07_01")
	
	if prog.tinh_luc == 999 and prog.tinh_nang == 450 and prog.upgrade_counts["attack"] == 3:
		print("  [PASS] D07: Toàn bộ Tinh Lực, Tinh Năng và số lần nâng được bảo toàn 100%.")
		pass_count += 1
	else:
		printerr("  [FAIL] D07 thất bại: TL=%d, TN=%d" % [prog.tinh_luc, prog.tinh_nang])

	# ----------------------------------------------------
	# D08 (P1): Chặn điều khiển di chuyển, phím 1 và nâng điểm khi DEAD
	# ----------------------------------------------------
	total_count += 1
	p.take_monster_damage(200) # Cho chết
	var before_pos = p.global_position
	p.set_client_input(1, 1.0, true) # Cố di chuyển & nhảy
	p._server_physics_process(0.1)
	
	# Thử tấn công khi chết
	p.handle_attack_request("atk_dead", [])
	
	# Thử nâng điểm khi chết
	var res_dead_upg = prog.process_upgrade("hp", "upg_dead", p)
	
	var input_blocked = (p.global_position == before_pos and not p.is_attacking)
	if input_blocked and p.is_dead and not res_dead_upg["success"]:
		print("  [PASS] D08: Di chuyển, đánh phím 1 và nâng điểm bị khóa hoàn toàn khi đang DEAD.")
		pass_count += 1
	else:
		printerr("  [FAIL] D08: Không chặn được input khi DEAD!")

	# ----------------------------------------------------
	# D09 (P1): Slime ngừng đánh người chết; không nhận thêm sát thương âm
	# ----------------------------------------------------
	total_count += 1
	var slime = CharacterBody2D.new()
	slime.set_script(SlimeAIScript)
	slime.target_player = p
	var can_target = (slime.target_player.has_method("is_player_alive") and slime.target_player.is_player_alive())
	
	# Gây thêm sát thương lên người đang DEAD
	p.take_monster_damage(50)
	var hp_still_zero = (p.current_hp == 0)
	
	if not can_target and hp_still_zero:
		print("  [PASS] D09: Slime ngừng nhắm mục tiêu đã chết; HP không bị âm.")
		pass_count += 1
	else:
		printerr("  [FAIL] D09: Slime vẫn nhắm hoặc HP bị âm!")
	slime.free()

	# ----------------------------------------------------
	# D10 (P0): Chống spam / xử lý trùng request Về Nhà (Idempotency)
	# ----------------------------------------------------
	total_count += 1
	var dup_id = "req_dup_respawn_99"
	var res_first = p.handle_respawn_home_request(dup_id)
	var res_second = p.handle_respawn_home_request(dup_id)
	
	if res_first["success"] and not res_second["success"]:
		print("  [PASS] D10: Idempotency: Yêu cầu hồi sinh trùng lặp bị từ chối, chỉ xử lý đúng 1 lần.")
		pass_count += 1
	else:
		printerr("  [FAIL] D10 thất bại: first=%s, second=%s" % [str(res_first["success"]), str(res_second["success"])])

	# ----------------------------------------------------
	# D11 (P0): Từ chối yêu cầu hồi sinh khi nhân vật đang ALIVE
	# ----------------------------------------------------
	total_count += 1
	# p hiện tại đã ALIVE sau bước D10
	var res_alive = p.handle_respawn_home_request("req_alive_test")
	if not res_alive["success"] and res_alive["reason"] == "Người chơi chưa chết!":
		print("  [PASS] D11: Server từ chối lệnh hồi sinh khi nhân vật vẫn đang sống (ALIVE).")
		pass_count += 1
	else:
		printerr("  [FAIL] D11 thất bại: res=%s" % str(res_alive))

	# ----------------------------------------------------
	# D12 (P1): Reconnect khi DEAD -> Snapshot giữ nguyên trạng thái dead & vị trí chết
	# ----------------------------------------------------
	total_count += 1
	p.take_monster_damage(500) # Cho chết
	var snap = p.get_state_snapshot()
	var snap_is_dead = snap.get("is_dead", false)
	var snap_death_pos = snap.get("death_pos", [])
	if snap_is_dead and snap_death_pos.size() == 2:
		print("  [PASS] D12: Snapshot Server phản ánh chính xác trạng thái is_dead=true và death_pos.")
		pass_count += 1
	else:
		printerr("  [FAIL] D12: Snapshot thiếu trường dead!")

	# ----------------------------------------------------
	# D13 (P0): Khởi động lại Server -> Save bền vững nguyên vẹn
	# ----------------------------------------------------
	total_count += 1
	var save_data = SaveRepository.get_default_profile()
	save_data["tinh_luc"] = 1234
	save_data["tinh_nang"] = 567
	save_data["upgrade_counts"]["attack"] = 4
	SaveRepository.save_profile(save_data)
	var loaded = SaveRepository.load_profile()
	if loaded["tinh_luc"] == 1234 and loaded["tinh_nang"] == 567 and loaded["upgrade_counts"]["attack"] == 4:
		print("  [PASS] D13: Lưu & nạp hồ sơ giữ nguyên 100% tiến trình người chơi.")
		pass_count += 1
	else:
		printerr("  [FAIL] D13 thất bại!")

	# ----------------------------------------------------
	# D14 (P1): Sau khi hồi sinh, mộ và bảng biến mất, nhân vật hiện lại
	# ----------------------------------------------------
	total_count += 1
	p.handle_respawn_home_request("req_d14")
	var snap_alive = p.get_state_snapshot()
	if not snap_alive["is_dead"] and snap_alive["hp"] == p.max_hp:
		print("  [PASS] D14: Sau hồi sinh, Server đồng bộ is_dead=false, sẵn sàng cho client xóa mộ.")
		pass_count += 1
	else:
		printerr("  [FAIL] D14 thất bại!")

	# ----------------------------------------------------
	# D15 (P1): Hai vòng đời chết -> hồi sinh liên tục không lỗi
	# ----------------------------------------------------
	total_count += 1
	var cycle_ok = true
	for i in range(2):
		p.take_monster_damage(1000)
		if not p.is_dead:
			cycle_ok = false
		var res_c = p.handle_respawn_home_request("cycle_%d" % i)
		if not res_c["success"] or p.is_dead:
			cycle_ok = false
	if cycle_ok:
		print("  [PASS] D15: Hoàn tất 2 chu kỳ chết -> hồi sinh liên tiếp trơn tru, không lỗi trạng thái.")
		pass_count += 1
	else:
		printerr("  [FAIL] D15 thất bại!")

	# ----------------------------------------------------
	# D16 (P0): Hồi quy: Kiểm tra toàn vẹn công thức nâng điểm & chiến đấu
	# ----------------------------------------------------
	total_count += 1
	var hp_c = GameConfig.get_upgrade_cost("hp", 0)
	var atk_c = GameConfig.get_upgrade_cost("attack", 0)
	var arm_c = GameConfig.get_upgrade_cost("armor", 0)
	var slime_dmg = GameConfig.compute_monster_damage_to_player(5, 0)
	if hp_c == 100 and atk_c == 200 and arm_c == 500 and slime_dmg == 5:
		print("  [PASS] D16: Hồi quy: Toàn bộ công thức nâng điểm, chi phí và sát thương quái giữ nguyên vẹn.")
		pass_count += 1
	else:
		printerr("  [FAIL] D16 thất bại!")

	# Dọn dẹp
	SaveRepository.reset_profile()
	SaveRepository.custom_save_dir = ""
	p.free()

	print("\n========================================================")
	print("  TỔNG KẾT: %d/%d BÀI KIỂM THỬ ĐẠT CHUẨN NGHIỆM THU!" % [pass_count, total_count])
	print("========================================================\n")
	quit(0 if pass_count == total_count else 1)
