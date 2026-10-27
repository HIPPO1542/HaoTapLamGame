extends CharacterBody2D

const GameConfig = preload("res://scripts/game_config.gd")

# SlimeAI: Quái Slime ma pháp tuân thủ Server Authoritative
# HP 100, Dame 5, Tầm đuổi 128px, Tầm đánh 32px, CD 1.5s, Hồi sinh 3-5s

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_server_entity: bool = false
var mob_id: int = 0
var spawn_position: Vector2 = Vector2.ZERO

# Chỉ số Server
var max_hp: int = GameConfig.SLIME_INIT_HP
var current_hp: int = GameConfig.SLIME_INIT_HP
var attack_damage: int = GameConfig.SLIME_ATTACK_DAMAGE
var is_alive: bool = true
var respawn_timer: float = 0.0
var attack_timer: float = 0.0
var move_speed: float = 50.0

# Trạng thái hiển thị
var facing_right: bool = true
var current_anim: String = "idle"
var target_position: Vector2 = Vector2.ZERO
var hurt_anim_timer: float = 0.0

var target_player: CharacterBody2D = null

func _ready() -> void:
	target_position = global_position
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_bar.visible = true
	visible = is_alive

func init_slime(id: int, spawn_pos: Vector2, on_server: bool) -> void:
	mob_id = id
	spawn_position = spawn_pos
	global_position = spawn_pos
	target_position = spawn_pos
	is_server_entity = on_server

func _physics_process(delta: float) -> void:
	if is_server_entity:
		_server_process(delta)
	else:
		_client_process(delta)

# ==========================================
# SERVER LOGIC QUYỀN LỰC
# ==========================================
func _server_process(delta: float) -> void:
	if not is_alive:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			_respawn_on_server()
		return

	if not is_on_floor():
		velocity.y += GameConfig.GRAVITY * delta

	if attack_timer > 0.0:
		attack_timer -= delta

	if is_instance_valid(target_player) and target_player.has_method("is_player_alive") and target_player.is_player_alive():
		var dist_to_player = global_position.distance_to(target_player.global_position)
		var dir_x = target_player.global_position.x - global_position.x
		facing_right = (dir_x >= 0)
		
		if dist_to_player <= GameConfig.SLIME_ATTACK_RANGE:
			velocity.x = 0.0
			current_anim = "idle"
			if attack_timer <= 0.0:
				_perform_slime_attack()
		elif dist_to_player <= GameConfig.SLIME_CHASE_RANGE:
			velocity.x = sign(dir_x) * move_speed
			current_anim = "move"
		else:
			_idle_or_return_home()
	else:
		_idle_or_return_home()

	move_and_slide()

func _idle_or_return_home() -> void:
	var dist_to_spawn = abs(global_position.x - spawn_position.x)
	if dist_to_spawn > 10.0:
		velocity.x = sign(spawn_position.x - global_position.x) * (move_speed * 0.5)
		facing_right = (velocity.x >= 0)
		current_anim = "move"
	else:
		velocity.x = 0.0
		current_anim = "idle"

func _perform_slime_attack() -> void:
	attack_timer = GameConfig.SLIME_ATTACK_COOLDOWN
	current_anim = "attack"
	if is_instance_valid(target_player) and target_player.has_method("take_monster_damage"):
		var dmg = GameConfig.compute_monster_damage_to_player(attack_damage, target_player.armor)
		target_player.take_monster_damage(dmg)

func take_damage_from_player(damage: int) -> int:
	if not is_alive:
		return 0
	var actual_lost = mini(maxi(0, damage), current_hp)
	current_hp -= actual_lost
	hp_bar.value = current_hp
	hurt_anim_timer = 0.3
	current_anim = "hurt"
	_spawn_damage_number(actual_lost)
	
	if current_hp <= 0:
		current_hp = 0
		is_alive = false
		visible = false
		collision_shape.set_deferred("disabled", true)
		respawn_timer = randf_range(GameConfig.SLIME_RESPAWN_MIN_TIME, GameConfig.SLIME_RESPAWN_MAX_TIME)
		print("[Server] Slime #%d chết! Sẽ hồi sinh sau %.1f giây tại %s." % [mob_id, respawn_timer, str(spawn_position)])
		
	return actual_lost

func _respawn_on_server() -> void:
	is_alive = true
	visible = true
	collision_shape.set_deferred("disabled", false)
	current_hp = max_hp
	hp_bar.value = current_hp
	global_position = spawn_position
	velocity = Vector2.ZERO
	current_anim = "idle"
	attack_timer = 0.0
	print("[Server] Slime #%d đã hồi sinh tại %s với %d HP." % [mob_id, str(spawn_position), current_hp])

func get_state_snapshot() -> Dictionary:
	return {
		"id": mob_id,
		"pos": [global_position.x, global_position.y],
		"hp": current_hp,
		"alive": is_alive,
		"facing": facing_right,
		"anim": current_anim
	}

# ==========================================
# CLIENT LOGIC HIỂN THỊ
# ==========================================
func _client_process(delta: float) -> void:
	visible = is_alive
	collision_shape.disabled = not is_alive
	hp_bar.visible = is_alive
	
	if not is_alive:
		return

	if global_position.distance_to(target_position) > 60.0:
		global_position = target_position
	else:
		global_position = global_position.lerp(target_position, 15.0 * delta)

	if sprite:
		sprite.flip_h = not facing_right
		if hurt_anim_timer > 0.0:
			hurt_anim_timer -= delta
			if sprite.animation != "hurt":
				sprite.play("hurt")
		else:
			if sprite.animation != current_anim:
				sprite.play(current_anim)

func apply_server_snapshot(data: Dictionary) -> void:
	if data.has("pos"):
		target_position = Vector2(data["pos"][0], data["pos"][1])
	if data.has("hp"):
		current_hp = data["hp"]
		hp_bar.value = current_hp
	if data.has("alive"):
		is_alive = data["alive"]
		visible = is_alive
		collision_shape.disabled = not is_alive
	if data.has("facing"):
		facing_right = data["facing"]
	if data.has("anim") and hurt_anim_timer <= 0.0:
		current_anim = data["anim"]

func trigger_hurt_effect(damage_amount: int) -> void:
	hurt_anim_timer = 0.3
	_spawn_damage_number(damage_amount)

func _spawn_damage_number(amount: int) -> void:
	var label = Label.new()
	label.text = "-%d" % amount
	label.modulate = Color(1.0, 0.25, 0.25, 1.0)
	label.add_theme_font_size_override("font_size", 14)
	label.position = Vector2(-15, -45)
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", -70.0, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)
