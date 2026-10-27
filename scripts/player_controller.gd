extends CharacterBody2D

const GameConfig = preload("res://scripts/game_config.gd")

# PlayerController: Quản lý nhân vật M1 tóc đen
# Tuân thủ chặt chẽ Server Authoritative

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var camera: Camera2D = $Camera2D

var is_server_entity: bool = false
var peer_id: int = 1
var server_world_ref: Node = null

# Vị trí hồi sinh mặc định
var spawn_point: Vector2 = Vector2(160, 580)

# ==========================================
# CHỈ SỐ SERVER AUTHORITATIVE
# ==========================================
var max_hp: int = GameConfig.M1_INIT_HP
var current_hp: int = GameConfig.M1_INIT_HP
var max_ki: int = GameConfig.M1_INIT_KI
var current_ki: int = GameConfig.M1_INIT_KI
var attack: int = GameConfig.M1_INIT_ATTACK
var armor: int = GameConfig.M1_INIT_ARMOR

var upgrade_counts: Dictionary = {"hp": 0, "ki": 0, "attack": 0, "armor": 0}

# Trạng thái Tử vong / Bia mộ / Hồi sinh
var is_dead: bool = false
var death_position: Vector2 = Vector2.ZERO
var processed_respawn_ids: Dictionary = {}

# Hồi chiêu & Hồi năng lượng tự nhiên
var attack_cooldown_timer: float = 0.0
var ki_regen_accumulator: float = 0.0
var processed_attack_ids: Dictionary = {}

# Điều khiển di chuyển
var move_axis: float = 0.0
var jump_requested: bool = false
var last_input_time: float = 0.0
var facing_right: bool = true
var current_anim: String = "idle"

# Phục vụ client
var target_position: Vector2 = Vector2.ZERO
var input_sequence: int = 0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0
var client_attack_cd: float = 0.0
var hurt_anim_timer: float = 0.0

func _ready() -> void:
	target_position = global_position
	if is_server_entity:
		if camera:
			camera.enabled = false
	else:
		if camera:
			camera.enabled = true
			camera.limit_left = 0
			camera.limit_top = 0
			camera.limit_right = 2560
			camera.limit_bottom = 720
			camera.position_smoothing_enabled = true

func _physics_process(delta: float) -> void:
	if is_server_entity:
		_server_physics_process(delta)
	else:
		_client_physics_process(delta)

# ==========================================
# LOGIC QUYỀN LỰC PHÍA SERVER
# ==========================================
func _server_physics_process(delta: float) -> void:
	# Khóa toàn bộ mô phỏng vật lý khi đang ở trạng thái DEAD
	if is_dead:
		velocity = Vector2.ZERO
		return

	# 1. Hồi KI tự nhiên 1 KI / giây (khi còn sống)
	if is_player_alive():
		ki_regen_accumulator += delta
		if ki_regen_accumulator >= 1.0:
			var add_ki = int(ki_regen_accumulator)
			current_ki = mini(current_ki + add_ki, max_ki)
			ki_regen_accumulator -= add_ki

	# 2. Giảm thời gian hồi chiêu Phím 1
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	# 3. Timeout input 300 ms
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_input_time > GameConfig.INPUT_TIMEOUT_SEC:
		move_axis = 0.0

	# 4. Trọng lực & Nhảy
	if not is_on_floor():
		velocity.y += GameConfig.GRAVITY * delta
	else:
		if jump_requested:
			velocity.y = GameConfig.M1_JUMP_VELOCITY
			jump_requested = false

	# 5. Di chuyển ngang
	velocity.x = move_axis * GameConfig.M1_MOVE_SPEED
	if move_axis > 0.01:
		facing_right = true
	elif move_axis < -0.01:
		facing_right = false

	move_and_slide()
	global_position.x = clamp(global_position.x, 20.0, 2540.0)

	# 6. Animation
	if hurt_anim_timer > 0.0:
		hurt_anim_timer -= delta

	if is_attacking:
		current_anim = "attack"
		attack_anim_timer -= delta
		if attack_anim_timer <= 0.0:
			is_attacking = false
	elif hurt_anim_timer > 0.0:
		current_anim = "hurt"
	elif not is_on_floor():
		current_anim = "jump"
	elif abs(velocity.x) > 5.0:
		current_anim = "run"
	else:
		current_anim = "idle"

func is_player_alive() -> bool:
	return current_hp > 0 and not is_dead

# Nhận sát thương từ quái
func take_monster_damage(dmg: int) -> void:
	if not is_player_alive():
		return
	current_hp = maxi(0, current_hp - dmg)
	print("[Server] M1 nhận %d sát thương từ quái. HP còn lại: %d/%d" % [dmg, current_hp, max_hp])
	if current_hp <= 0:
		_on_player_died_on_server()
	else:
		hurt_anim_timer = 0.25
		current_anim = "hurt"

# Chuyển trạng thái DEAD_WAITING_CHOICE trên Server (không tự hồi sinh)
func _on_player_died_on_server() -> void:
	if is_dead:
		return
	is_dead = true
	death_position = global_position
	velocity = Vector2.ZERO
	is_attacking = false
	attack_cooldown_timer = 0.0
	hurt_anim_timer = 0.0
	current_anim = "idle"
	print("[Server] M1 tử nạn tại %s! Chuyển trạng thái DEAD_WAITING_CHOICE (Chờ người chơi chọn Về Nhà, không tự hồi sinh)." % str(death_position))

# Xử lý yêu cầu Hồi sinh Về Nhà từ Client
func handle_respawn_home_request(request_id: String) -> Dictionary:
	# 1. Kiểm tra trạng thái: chỉ cho phép khi đang DEAD
	if not is_dead:
		print("[Server] Từ chối hồi sinh: M1 vẫn đang sống (ALIVE).")
		return {"success": false, "reason": "Người chơi chưa chết!", "is_dead": is_dead}

	# 2. Chống xử lý trùng request_id (Idempotency)
	if not request_id.is_empty():
		if processed_respawn_ids.has(request_id):
			print("[Server] Bỏ qua request hồi sinh trùng lặp: %s" % request_id)
			return {"success": false, "reason": "Yêu cầu đã được xử lý", "is_dead": is_dead}
		processed_respawn_ids[request_id] = true
		if processed_respawn_ids.size() > 100:
			processed_respawn_ids.clear()

	# 3. Thực hiện hồi sinh về điểm spawn an toàn ở đầu map
	global_position = spawn_point
	velocity = Vector2.ZERO
	current_hp = max_hp  # Sử dụng max_hp đã nâng hiện tại!
	current_ki = max_ki  # Sử dụng max_ki đã nâng hiện tại!
	is_dead = false
	death_position = Vector2.ZERO
	attack_cooldown_timer = 0.0
	is_attacking = false
	hurt_anim_timer = 0.0
	current_anim = "idle"
	
	print("[Server] M1 đã hồi sinh VỀ NHÀ tại %s với đầy đủ %d HP / %d KI (không trừ điểm)." % [str(spawn_point), max_hp, max_ki])
	return {
		"success": true,
		"reason": "Hồi sinh thành công",
		"is_dead": false,
		"hp": current_hp,
		"hp_max": max_hp,
		"ki": current_ki,
		"ki_max": max_ki,
		"pos": [global_position.x, global_position.y]
	}

# Xử lý lệnh tấn công Phím 1 từ Client
func handle_attack_request(request_id: String, mobs: Array) -> void:
	if not is_player_alive():
		print("[Server] Từ chối đánh: M1 đã chết.")
		return
	
	if not request_id.is_empty():
		if processed_attack_ids.has(request_id):
			print("[Server] Bỏ qua request_id đánh trùng lặp: %s" % request_id)
			return
		processed_attack_ids[request_id] = true
		if processed_attack_ids.size() > 200:
			processed_attack_ids.clear()
	
	if attack_cooldown_timer > 0.0:
		print("[Server] Từ chối đánh: Đang hồi chiêu Phím 1 (còn %.2fs)." % attack_cooldown_timer)
		return
		
	if current_ki < GameConfig.SKILL_1_KI_COST:
		print("[Server] Từ chối đánh: Cạn KI (cần %d, hiện có %d)." % [GameConfig.SKILL_1_KI_COST, current_ki])
		return

	# Trừ 1 KI một lần duy nhất
	current_ki -= GameConfig.SKILL_1_KI_COST
	attack_cooldown_timer = GameConfig.SKILL_1_COOLDOWN
	is_attacking = true
	attack_anim_timer = 0.38

	# Tìm Slime sống trong tầm phía trước mặt (48 px)
	var hit_mob = null
	var min_dist = 999999.0
	
	for mob in mobs:
		if not is_instance_valid(mob) or not mob.is_alive:
			continue
		var dx = mob.global_position.x - global_position.x
		var dy = abs(mob.global_position.y - global_position.y)
		
		# Kiểm tra đúng hướng mặt và trong tầm 1.5 đơn vị (48 px)
		var in_front = false
		if facing_right and dx >= 0.0 and dx <= GameConfig.SKILL_1_RANGE:
			in_front = true
		elif not facing_right and dx <= 0.0 and abs(dx) <= GameConfig.SKILL_1_RANGE:
			in_front = true
			
		if in_front and dy <= 40.0:
			var d = abs(dx)
			if d < min_dist:
				min_dist = d
				hit_mob = mob

	if hit_mob != null:
		var actual_hp_lost = hit_mob.take_damage_from_player(attack)
		print("[Server] M1 chém trúng Slime #%d! Gây %d HP sát thương thực tế." % [hit_mob.mob_id, actual_hp_lost])
		var nb = get_node_or_null("/root/NetworkBridge")
		if nb:
			nb.combat_result.rpc(request_id, hit_mob.mob_id, actual_hp_lost)
		if is_instance_valid(server_world_ref) and server_world_ref.has_method("on_player_dealt_damage"):
			server_world_ref.on_player_dealt_damage(actual_hp_lost, hit_mob.mob_id, request_id)
	else:
		print("[Server] M1 đánh chém gió (không có quái trong tầm 48 px phía trước mặt).")

func set_client_input(sequence: int, axis: float, jump: bool) -> void:
	if not is_player_alive():
		return
	input_sequence = sequence
	move_axis = clamp(axis, -1.0, 1.0)
	if jump and is_on_floor():
		jump_requested = true
	last_input_time = Time.get_ticks_msec() / 1000.0

func get_state_snapshot() -> Dictionary:
	return {
		"pos": [global_position.x, global_position.y],
		"vel": [velocity.x, velocity.y],
		"facing_right": facing_right,
		"anim": current_anim,
		"on_floor": is_on_floor(),
		"hp": current_hp,
		"hp_max": max_hp,
		"ki": current_ki,
		"ki_max": max_ki,
		"is_dead": is_dead,
		"death_pos": [death_position.x, death_position.y]
	}

# ==========================================
# CLIENT LOGIC HIỂN THỊ
# ==========================================
func _client_physics_process(delta: float) -> void:
	# Khóa toàn bộ input và hành động khi client đang ở trạng thái DEAD
	if is_dead:
		velocity = Vector2.ZERO
		return

	# 1. Đọc phím điều khiển (Hỗ trợ cả ADWS và 4 phím Mũi tên)
	var axis = Input.get_axis("move_left", "move_right")
	var jump = Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("move_up")
	
	input_sequence += 1
	var nb = get_node_or_null("/root/NetworkBridge")
	if nb:
		nb.submit_input.rpc_id(1, input_sequence, axis, jump)

	# 2. Đọc phím 1 đánh thường
	if client_attack_cd > 0.0:
		client_attack_cd -= delta

	if Input.is_action_just_pressed("attack_1"):
		if client_attack_cd <= 0.0 and current_ki >= GameConfig.SKILL_1_KI_COST:
			client_attack_cd = GameConfig.SKILL_1_COOLDOWN
			var req_id = "atk_%d_%d" % [multiplayer.get_unique_id(), Time.get_ticks_msec()]
			if nb:
				nb.request_basic_attack.rpc_id(1, req_id)
			if sprite:
				sprite.play("attack")

	# 3. Nội suy vị trí theo snapshot server
	if global_position.distance_to(target_position) > 120.0:
		global_position = target_position
	else:
		global_position = global_position.lerp(target_position, 20.0 * delta)

	# 4. Cập nhật sprite & hướng
	if sprite:
		sprite.flip_h = not facing_right
		if current_anim == "hurt":
			if sprite.animation != "hurt":
				sprite.play("hurt")
		elif current_anim == "attack":
			if sprite.animation != "attack":
				sprite.play("attack")
		elif sprite.animation == "attack" and sprite.is_playing():
			pass
		else:
			if sprite.animation != current_anim:
				sprite.play(current_anim)

func apply_server_snapshot(data: Dictionary) -> void:
	if data.has("pos"):
		target_position = Vector2(data["pos"][0], data["pos"][1])
	if data.has("vel"):
		velocity = Vector2(data["vel"][0], data["vel"][1])
	if data.has("facing_right"):
		facing_right = data["facing_right"]
	if data.has("anim"):
		current_anim = data["anim"]
	if data.has("hp"):
		current_hp = data["hp"]
	if data.has("hp_max"):
		max_hp = data["hp_max"]
	if data.has("ki"):
		current_ki = data["ki"]
	if data.has("ki_max"):
		max_ki = data["ki_max"]
	if data.has("is_dead"):
		is_dead = data["is_dead"]
	if data.has("death_pos"):
		death_position = Vector2(data["death_pos"][0], data["death_pos"][1])
	
	if sprite:
		sprite.visible = not is_dead
