extends RefCounted
class_name ProgressionSystem

const GameConfig = preload("res://scripts/game_config.gd")

# ProgressionSystem: Quản lý Tinh Lực, Tinh Năng và nâng chỉ số phía Server
# Tuân thủ GDD v2.3 mục 12 và quy chuẩn Server Authoritative

var tinh_luc: int = 0
var tinh_nang: int = 0
var upgrade_counts: Dictionary = {
	"hp": 0,
	"ki": 0,
	"attack": 0,
	"armor": 0
}

# Bộ đệm idempotency chống trùng lặp request_id (T11)
var processed_requests: Dictionary = {}

# Thưởng Tinh Lực & Tinh Năng từ sát thương thực tế (T08, T09)
func record_monster_damage(actual_hp_lost: int) -> Dictionary:
	if actual_hp_lost <= 0:
		return {"tl_gained": 0, "tn_gained": 0}
	
	# Quy tắc 1 HP thực sự bị trừ = 1 Tinh Lực
	# Tinh Năng [TEST] tỉ lệ 1:1 trong v0.1
	tinh_luc += actual_hp_lost
	tinh_nang += actual_hp_lost
	
	return {
		"tl_gained": actual_hp_lost,
		"tn_gained": actual_hp_lost,
		"tinh_luc": tinh_luc,
		"tinh_nang": tinh_nang
	}

# Xử lý yêu cầu nâng chỉ số từ Menu -> Nhân vật (T10, T11, T12)
func process_upgrade(stat_id: String, request_id: String, player_entity: CharacterBody2D) -> Dictionary:
	# 1. Kiểm tra idempotency: Nếu request_id đã từng xử lý, trả về kết quả đã ghi nhận
	if processed_requests.has(request_id):
		print("[Progression] Bỏ qua request_id trùng lặp: %s" % request_id)
		return processed_requests[request_id]

	# 2. Kiểm tra tính hợp lệ của stat_id
	if not upgrade_counts.has(stat_id):
		var err_res = {"success": false, "reason": "Chỉ số không hợp lệ!", "stat_id": stat_id}
		processed_requests[request_id] = err_res
		return err_res

	# 2b. Chặn nâng điểm khi nhân vật đang ở trạng thái DEAD
	if is_instance_valid(player_entity) and player_entity.get("is_dead") == true:
		var err_dead = {"success": false, "reason": "Không thể nâng điểm khi đã tử vong!", "stat_id": stat_id}
		processed_requests[request_id] = err_dead
		return err_dead

	# 3. Tính chi phí Tinh Năng cho lần nâng thứ n
	var current_count: int = upgrade_counts[stat_id]
	var cost: int = GameConfig.get_upgrade_cost(stat_id, current_count)

	# 4. Kiểm tra đủ điểm Tinh Năng (không thể làm âm điểm)
	if tinh_nang < cost:
		var fail_res = {
			"success": false,
			"reason": "Thiếu Tinh Năng (Cần %d, hiện có %d)!" % [cost, tinh_nang],
			"stat_id": stat_id,
			"cost": cost,
			"tinh_nang": tinh_nang
		}
		processed_requests[request_id] = fail_res
		return fail_res

	# 5. Trừ Tinh Năng và tăng chỉ số trong cùng một thao tác nguyên tử
	tinh_nang -= cost
	upgrade_counts[stat_id] += 1
	var increase: int = GameConfig.get_upgrade_increase(stat_id)

	# Áp dụng lên Player
	if is_instance_valid(player_entity):
		match stat_id:
			"hp":
				player_entity.max_hp += increase
				player_entity.current_hp = mini(player_entity.current_hp + increase, player_entity.max_hp)
			"ki":
				player_entity.max_ki += increase
				player_entity.current_ki = mini(player_entity.current_ki + increase, player_entity.max_ki)
			"attack":
				player_entity.attack += increase
			"armor":
				player_entity.armor += increase

	var success_res = {
		"success": true,
		"reason": "Nâng %s thành công (+%d)!" % [stat_id.to_upper(), increase],
		"stat_id": stat_id,
		"cost": cost,
		"increase": increase,
		"tinh_luc": tinh_luc,
		"tinh_nang": tinh_nang,
		"new_count": upgrade_counts[stat_id]
	}
	
	processed_requests[request_id] = success_res
	print("[Progression] Nâng điểm thành công: %s +%d (Tốn %d TN, TN còn lại: %d)" % [
		stat_id, increase, cost, tinh_nang
	])
	return success_res

func get_state() -> Dictionary:
	return {
		"tinh_luc": tinh_luc,
		"tinh_nang": tinh_nang,
		"upgrade_counts": upgrade_counts.duplicate()
	}

func load_state(data: Dictionary) -> void:
	tinh_luc = int(data.get("tinh_luc", 0))
	tinh_nang = int(data.get("tinh_nang", 0))
	if data.has("upgrade_counts"):
		var uc = data["upgrade_counts"]
		upgrade_counts["hp"] = int(uc.get("hp", 0))
		upgrade_counts["ki"] = int(uc.get("ki", 0))
		upgrade_counts["attack"] = int(uc.get("attack", 0))
		upgrade_counts["armor"] = int(uc.get("armor", 0))
