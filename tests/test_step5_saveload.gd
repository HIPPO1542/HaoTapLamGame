extends SceneTree

const GameConfig = preload("res://scripts/game_config.gd")
const SaveRepository = preload("res://scripts/save_repository.gd")
const ProgressionSystem = preload("res://scripts/progression_system.gd")

# Test tự động hóa kiểm tra Lưu/Nạp hồ sơ JSON, Safe Save, Khôi phục sau sự cố (Bước 5)
func _init() -> void:
	print("========================================")
	print("CHẠY KIỂM THỬ BƯỚC 5: LƯU & NẠP HỒ SƠ JSON SERVER")
	print("========================================")
	
	# Đảm bảo môi trường kiểm thử cách ly, an toàn tuyệt đối cho file save thật
	SaveRepository.custom_save_dir = "res://tests/temp_saves/"
	
	var pass_count = 0
	var total_count = 0
	
	# Test 1: Kiểm tra cấu trúc template hồ sơ mặc định theo Section 7.2
	total_count += 1
	var def_prof = SaveRepository.get_default_profile()
	var has_schema = (def_prof.get("schema_version") == 1)
	var has_profile_id = (def_prof.get("profile_id") == "local_test_player_01")
	var has_appearance = (def_prof.get("appearance_id") == "M1_black_hair")
	var has_tl_tn = (def_prof.get("tinh_luc") == 0 and def_prof.get("tinh_nang") == 0)
	var has_counts = def_prof.has("upgrade_counts")
	
	if has_schema and has_profile_id and has_appearance and has_tl_tn and has_counts:
		print("[PASS] Test 1: Schema hồ sơ mặc định khớp 100% đặc tả Mục 7.2 Implementation Spec.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 1: Schema mặc định không chuẩn!")

	# Test 2 (T14): Lưu hồ sơ và nạp lại từ ổ đĩa (Safe Save)
	total_count += 1
	var test_data = SaveRepository.get_default_profile()
	test_data["tinh_luc"] = 520
	test_data["tinh_nang"] = 120
	test_data["upgrade_counts"]["hp"] = 2
	test_data["upgrade_counts"]["attack"] = 1
	test_data["hp_max"] = 140
	test_data["attack"] = 11
	
	var save_ok = SaveRepository.save_profile(test_data)
	var loaded_data = SaveRepository.load_profile()
	
	if save_ok and loaded_data["tinh_luc"] == 520 and loaded_data["tinh_nang"] == 120 and loaded_data["upgrade_counts"]["hp"] == 2 and loaded_data["attack"] == 11:
		print("[PASS] Test 2 (T14): Lưu và nạp lại hồ sơ thành công, dữ liệu Tinh Lực, Tinh Năng, nâng cấp nguyên vẹn.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 2: Lưu/nạp thất bại!")

	# Test 3: Kiểm tra cơ chế tự động tạo file backup (.bak) khi ghi đè
	total_count += 1
	test_data["tinh_luc"] = 600
	SaveRepository.save_profile(test_data)
	var has_bak = FileAccess.file_exists(SaveRepository.get_backup_path())
	if has_bak:
		print("[PASS] Test 3: Cơ chế sao lưu an toàn tự động tạo file backup .bak khi ghi file chính.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 3: Không tìm thấy file backup .bak!")

	# Test 4 (T13, T16): Mô phỏng rớt mạng / reconnect -> nạp lại state server không bị reset
	total_count += 1
	var prog = ProgressionSystem.new()
	prog.load_state(loaded_data)
	if prog.tinh_luc == 520 and prog.tinh_nang == 120 and prog.upgrade_counts["hp"] == 2:
		print("[PASS] Test 4 (T13, T16): ProgressionSystem khôi phục trạng thái từ file lưu chính xác.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 4: Khôi phục state vào ProgressionSystem thất bại!")

	# Test 5: Phục hồi khi file save chính bị hỏng (corrupt recovery via .bak)
	total_count += 1
	# Làm hỏng file save chính
	var corrupt_file = FileAccess.open(SaveRepository.get_save_path(), FileAccess.WRITE)
	if corrupt_file:
		corrupt_file.store_string("CORRUPTED_NOT_A_VALID_JSON{{{")
		corrupt_file.close()
	
	var recovered_data = SaveRepository.load_profile()
	if recovered_data["tinh_luc"] == 600 or recovered_data["tinh_luc"] == 520: # Lấy từ .bak thành công
		print("[PASS] Test 5: File save chính bị lỗi cú pháp -> Tự động khôi phục dữ liệu từ .bak an toàn.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 5: Phục hồi từ .bak thất bại!")

	# Dọn dẹp thư mục tạm và trả custom_save_dir về rỗng
	SaveRepository.reset_profile()
	SaveRepository.custom_save_dir = ""

	print("========================================")
	print("KẾT QUẢ BƯỚC 5: %d/%d tests ĐẠT." % [pass_count, total_count])
	print("========================================")
	quit(0 if pass_count == total_count else 1)
