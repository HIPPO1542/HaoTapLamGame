extends Node2D

# ServerWorld: Quản lý authoritative thế giới, 8 Slime, combat, Progression và Lưu/Nạp hồ sơ JSON

var grassland_scene = preload("res://scenes/test_grassland.tscn")
var player_scene = preload("res://scenes/player.tscn")
var slime_scene = preload("res://scenes/slime.tscn")

var map_instance: Node2D
var player_entity: CharacterBody2D
var active_peer_id: int = -1

# Danh sách 8 Slime
var slimes: Array[CharacterBody2D] = []

# Hệ thống tiến trình và lưu trữ
var progression: ProgressionSystem = ProgressionSystem.new()
var autosave_timer: float = 0.0
const AUTOSAVE_INTERVAL: float = 5.0 # Tự động lưu mỗi 5 giây

var tick_id: int = 0
var snapshot_timer: float = 0.0
var snapshot_interval: float = 1.0 / GameConfig.NETWORK_SNAPSHOT_RATE

func _ready() -> void:
	# Ẩn render hình ảnh trên Server để Server tập trung mô phỏng vật lý & console
	visible = false

	# 1. Nạp dữ liệu hồ sơ đã lưu trên Server (nếu có)
	_load_persisted_profile()

	# 2. Khởi tạo bản đồ đồng cỏ
	map_instance = grassland_scene.instantiate()
	add_child(map_instance)
	
	# 3. Sinh 8 Slime
	_spawn_all_slimes()
	
	# 4. Đăng ký nhận RPC
	NetworkBridge.server_input_handler = Callable(self, "_on_client_input_received")
	NetworkBridge.server_attack_handler = Callable(self, "_on_client_attack_requested")
	NetworkBridge.server_upgrade_handler = Callable(self, "_on_client_upgrade_requested")
	NetworkBridge.server_respawn_handler = Callable(self, "_on_client_respawn_requested")
	NetworkBridge.peer_connected_event.connect(_on_peer_connected)
	NetworkBridge.peer_disconnected_event.connect(_on_peer_disconnected)
	
	print("[ServerWorld] Server sẵn sàng (Hồ sơ đã nạp: TL=%d, TN=%d)." % [
		progression.tinh_luc, progression.tinh_nang
	])

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_save_persisted_profile()

func _load_persisted_profile() -> void:
	var data = SaveRepository.load_profile()
	progression.load_state(data)
	print("[ServerWorld] Đã nạp thành công dữ liệu lưu từ %s" % SaveRepository.SAVE_PATH)

func _save_persisted_profile() -> void:
	var hp_m = player_entity.max_hp if is_instance_valid(player_entity) else (GameConfig.M1_INIT_HP + progression.upgrade_counts.get("hp", 0) * 20)
	var hp_c = player_entity.current_hp if is_instance_valid(player_entity) else hp_m
	var ki_m = player_entity.max_ki if is_instance_valid(player_entity) else (GameConfig.M1_INIT_KI + progression.upgrade_counts.get("ki", 0) * 20)
	var ki_c = player_entity.current_ki if is_instance_valid(player_entity) else ki_m
	var atk = player_entity.attack if is_instance_valid(player_entity) else (GameConfig.M1_INIT_ATTACK + progression.upgrade_counts.get("attack", 0))
	var arm = player_entity.armor if is_instance_valid(player_entity) else (GameConfig.M1_INIT_ARMOR + progression.upgrade_counts.get("armor", 0))

	var save_data = {
		"schema_version": 1,
		"profile_id": "local_test_player_01",
		"appearance_id": "M1_black_hair",
		"tinh_luc": int(progression.tinh_luc),
		"tinh_nang": int(progression.tinh_nang),
		"hp_max": int(hp_m),
		"hp_current": int(hp_c),
		"ki_max": int(ki_m),
		"ki_current": int(ki_c),
		"attack": int(atk),
		"armor": int(arm),
		"upgrade_counts": {
			"hp": int(progression.upgrade_counts.get("hp", 0)),
			"ki": int(progression.upgrade_counts.get("ki", 0)),
			"attack": int(progression.upgrade_counts.get("attack", 0)),
			"armor": int(progression.upgrade_counts.get("armor", 0))
		},
		"map_id": "test_grassland",
		"zone_id": 1,
		"spawn_position": [160, 580]
	}
	var ok = SaveRepository.save_profile(save_data)
	if ok:
		print("[ServerWorld] [AUTOSAVE] Đã lưu dữ liệu: TL=%d, TN=%d, Counts=%s" % [
			progression.tinh_luc, progression.tinh_nang, str(progression.upgrade_counts)
		])

func _spawn_all_slimes() -> void:
	slimes.clear()
	var entities_node = map_instance.get_node("Entities")
	var start_x = 500.0
	var ground_y = 580.0
	
	for i in range(GameConfig.SLIME_COUNT):
		var spawn_pos = Vector2(start_x + i * GameConfig.SLIME_SPAWN_SPACING, ground_y)
		var slime_inst = slime_scene.instantiate()
		slime_inst.init_slime(i, spawn_pos, true)
		entities_node.add_child(slime_inst)
		slimes.append(slime_inst)

func _on_peer_connected(peer_id: int) -> void:
	active_peer_id = peer_id
	_spawn_player(peer_id)
	_broadcast_progression()

func _on_peer_disconnected(peer_id: int) -> void:
	if active_peer_id == peer_id:
		print("[ServerWorld] Người chơi %d thoát. Lưu tiến trình ngay lập tức." % peer_id)
		_save_persisted_profile()
		if is_instance_valid(player_entity):
			player_entity.queue_free()
			player_entity = null
		active_peer_id = -1

func _spawn_player(peer_id: int) -> void:
	if is_instance_valid(player_entity):
		player_entity.queue_free()
	
	player_entity = player_scene.instantiate()
	player_entity.is_server_entity = true
	player_entity.peer_id = peer_id
	
	_apply_progression_to_player()
	
	var spawn_pos = Vector2(160, 580)
	if map_instance.has_node("SpawnPoint"):
		spawn_pos = map_instance.get_node("SpawnPoint").global_position
		
	player_entity.global_position = spawn_pos
	player_entity.spawn_point = spawn_pos
	player_entity.server_world_ref = self
	map_instance.get_node("Entities").add_child(player_entity)
	
	for s in slimes:
		if is_instance_valid(s):
			s.target_player = player_entity
			
	print("[ServerWorld] Đã tạo Player M1 (Peer %d) tại %s." % [peer_id, str(spawn_pos)])

func _apply_progression_to_player() -> void:
	if not is_instance_valid(player_entity):
		return
	var hp_up = progression.upgrade_counts.get("hp", 0)
	var ki_up = progression.upgrade_counts.get("ki", 0)
	var atk_up = progression.upgrade_counts.get("attack", 0)
	var arm_up = progression.upgrade_counts.get("armor", 0)
	
	player_entity.max_hp = GameConfig.M1_INIT_HP + hp_up * 20
	player_entity.current_hp = player_entity.max_hp
	player_entity.max_ki = GameConfig.M1_INIT_KI + ki_up * 20
	player_entity.current_ki = player_entity.max_ki
	player_entity.attack = GameConfig.M1_INIT_ATTACK + atk_up * 1
	player_entity.armor = GameConfig.M1_INIT_ARMOR + arm_up * 1

func _on_client_input_received(sender_id: int, sequence: int, axis: float, jump: bool) -> void:
	if not is_instance_valid(player_entity) or sender_id != active_peer_id:
		return
	player_entity.set_client_input(sequence, axis, jump)

func _on_client_attack_requested(sender_id: int, request_id: String) -> void:
	if not is_instance_valid(player_entity) or sender_id != active_peer_id:
		return
	player_entity.handle_attack_request(request_id, slimes)

func on_player_dealt_damage(actual_lost: int, _mob_id: int, _request_id: String) -> void:
	var reward = progression.record_monster_damage(actual_lost)
	print("[Server] Sát thương: %d -> +%d TL (Tổng: %d), +%d TN (Tổng: %d)" % [
		actual_lost, reward["tl_gained"], reward["tinh_luc"], reward["tn_gained"], reward["tinh_nang"]
	])
	_broadcast_progression()

func _on_client_upgrade_requested(sender_id: int, stat_id: String, request_id: String) -> void:
	if not is_instance_valid(player_entity) or sender_id != active_peer_id:
		return
		
	# Chặn nâng điểm khi nhân vật đang ở trạng thái DEAD
	if player_entity.is_dead:
		print("[Server] Từ chối nâng điểm: Nhân vật đang ở trạng thái DEAD.")
		NetworkBridge.upgrade_result.rpc_id(sender_id, request_id, false, "Không thể nâng điểm khi đã tử vong!", {})
		return

	var result = progression.process_upgrade(stat_id, request_id, player_entity)
	NetworkBridge.upgrade_result.rpc_id(sender_id, request_id, result["success"], result["reason"], result)
	
	if result["success"]:
		_save_persisted_profile()
		_broadcast_progression()

func _on_client_respawn_requested(sender_id: int, request_id: String) -> void:
	if not is_instance_valid(player_entity) or sender_id != active_peer_id:
		return
		
	var result = player_entity.handle_respawn_home_request(request_id)
	NetworkBridge.respawn_result.rpc_id(sender_id, result["success"], result["reason"], result)
	
	if result["success"]:
		_broadcast_snapshot()
		_broadcast_progression()

func _broadcast_progression() -> void:
	if not is_instance_valid(player_entity):
		return
	var stats = {
		"hp_current": player_entity.current_hp,
		"hp_max": player_entity.max_hp,
		"ki_current": player_entity.current_ki,
		"ki_max": player_entity.max_ki,
		"attack": player_entity.attack,
		"armor": player_entity.armor
	}
	NetworkBridge.progression_state.rpc(
		progression.tinh_luc,
		progression.tinh_nang,
		stats,
		progression.upgrade_counts
	)

func _physics_process(delta: float) -> void:
	# Lưu tự động định kỳ
	autosave_timer += delta
	if autosave_timer >= AUTOSAVE_INTERVAL:
		autosave_timer = 0.0
		_save_persisted_profile()

	if not is_instance_valid(player_entity):
		return
		
	snapshot_timer += delta
	if snapshot_timer >= snapshot_interval:
		snapshot_timer = 0.0
		tick_id += 1
		_broadcast_snapshot()

func _broadcast_snapshot() -> void:
	var player_state: Dictionary = player_entity.get_state_snapshot()
	var mobs_state: Array = []
	for s in slimes:
		if is_instance_valid(s):
			mobs_state.append(s.get_state_snapshot())
			
	NetworkBridge.state_snapshot.rpc(tick_id, player_state, mobs_state)
