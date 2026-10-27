extends RefCounted
class_name SaveRepository

const GameConfig = preload("res://scripts/game_config.gd")

# SaveRepository: Quản lý ghi và đọc dữ liệu nhân vật bền vững phía Server
# Đường dẫn: user://saves/player_save.json (Ghi nguyên tử temp -> thay thế an toàn)

const SAVE_DIR: String = "user://saves/"
const SAVE_PATH: String = "user://saves/player_save.json"
const TEMP_PATH: String = "user://saves/player_save.json.tmp"
const BACKUP_PATH: String = "user://saves/player_save.json.bak"

static var custom_save_dir: String = ""

static func get_save_dir() -> String:
	return custom_save_dir if not custom_save_dir.is_empty() else SAVE_DIR

static func get_save_path() -> String:
	return get_save_dir() + "player_save.json"

static func get_temp_path() -> String:
	return get_save_dir() + "player_save.json.tmp"

static func get_backup_path() -> String:
	return get_save_dir() + "player_save.json.bak"

# Mẫu hồ sơ mặc định theo Section 7.2 của Implementation Spec
static func get_default_profile() -> Dictionary:
	return {
		"schema_version": 1,
		"profile_id": "local_test_player_01",
		"appearance_id": "M1_black_hair",
		"tinh_luc": 0,
		"tinh_nang": 0,
		"hp_max": GameConfig.M1_INIT_HP,
		"hp_current": GameConfig.M1_INIT_HP,
		"ki_max": GameConfig.M1_INIT_KI,
		"ki_current": GameConfig.M1_INIT_KI,
		"attack": GameConfig.M1_INIT_ATTACK,
		"armor": GameConfig.M1_INIT_ARMOR,
		"upgrade_counts": {
			"hp": 0,
			"ki": 0,
			"attack": 0,
			"armor": 0
		},
		"map_id": "test_grassland",
		"zone_id": 1,
		"spawn_position": [160, 580]
	}

# Lưu dữ liệu an toàn (ghi temp -> sao lưu backup -> thay thế file chính)
static func save_profile(data: Dictionary) -> bool:
	var target_dir = get_save_dir()
	var target_save = get_save_path()
	var target_temp = get_temp_path()
	var target_bak = get_backup_path()

	# Đảm bảo thư mục lưu tồn tại
	if not DirAccess.dir_exists_absolute(target_dir):
		var err = DirAccess.make_dir_recursive_absolute(target_dir)
		if err != OK:
			printerr("[SaveRepository] Không thể tạo thư mục lưu: ", target_dir)
			return false

	var json_str = JSON.stringify(data, "\t")
	
	# 1. Ghi vào file tạm .tmp
	var tmp_file = FileAccess.open(target_temp, FileAccess.WRITE)
	if not tmp_file:
		printerr("[SaveRepository] Không thể mở file tạm để ghi: ", target_temp)
		return false
	tmp_file.store_string(json_str)
	tmp_file.close()

	# 2. Tạo backup file hiện tại nếu có
	if FileAccess.file_exists(target_save):
		# Copy thành .bak
		var dir = DirAccess.open(target_dir)
		if dir:
			dir.copy(target_save, target_bak)

	# 3. Di chuyển/ghi đè file tạm vào file chính
	var dir_acc = DirAccess.open(target_dir)
	if dir_acc:
		var copy_err = dir_acc.copy(target_temp, target_save)
		dir_acc.remove(target_temp)
		if copy_err == OK:
			return true

	printerr("[SaveRepository] Ghi đè file chính thất bại!")
	return false

# Nạp dữ liệu hồ sơ (Ưu tiên file chính, nếu lỗi/hỏng tự động phục hồi từ backup .bak)
static func load_profile() -> Dictionary:
	var target_save = get_save_path()
	var target_bak = get_backup_path()

	if FileAccess.file_exists(target_save):
		var res = _try_read_json(target_save)
		if not res.is_empty():
			return res
		printerr("[SaveRepository] File save chính bị lỗi cú pháp hoặc rỗng! Đang khôi phục từ file backup...")

	if FileAccess.file_exists(target_bak):
		var res_bak = _try_read_json(target_bak)
		if not res_bak.is_empty():
			print("[SaveRepository] Khôi phục thành công từ file backup .bak!")
			return res_bak

	print("[SaveRepository] Chưa có file save hợp lệ. Khởi tạo hồ sơ mặc định ban đầu.")
	return get_default_profile()

static func _try_read_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var json_text = file.get_as_text()
	file.close()
	if json_text.strip_edges().is_empty():
		return {}
	var json = JSON.new()
	var parse_err = json.parse(json_text)
	if parse_err != OK:
		return {}
	if typeof(json.data) == TYPE_DICTIONARY:
		return json.data
	return {}

# Reset dữ liệu save phục vụ mục đích kiểm thử có chủ đích
static func reset_profile() -> void:
	var target_save = get_save_path()
	var target_bak = get_backup_path()
	var target_temp = get_temp_path()

	if FileAccess.file_exists(target_save):
		DirAccess.remove_absolute(target_save)
	if FileAccess.file_exists(target_bak):
		DirAccess.remove_absolute(target_bak)
	if FileAccess.file_exists(target_temp):
		DirAccess.remove_absolute(target_temp)
	print("[SaveRepository] Đã reset toàn bộ dữ liệu save.")
