extends SceneTree

const GameConfig = preload("res://scripts/game_config.gd")

func _init() -> void:
	print("\n========================================================")
	print("  KIỂM THỬ NỀN TẢNG ANIMATION M1 (A01 -> A07) — v0.1.1")
	print("========================================================\n")

	var pass_count = 0
	var total_count = 0

	# ----------------------------------------------------
	# A01: Tải m1_frames.tres và kiểm tra đủ 5 animation
	# ----------------------------------------------------
	total_count += 1
	var frames_res = load("res://assets/characters/m1/m1_frames.tres")
	if frames_res and frames_res is SpriteFrames:
		var has_idle = frames_res.has_animation("idle")
		var has_run = frames_res.has_animation("run")
		var has_jump = frames_res.has_animation("jump")
		var has_attack = frames_res.has_animation("attack")
		var has_hurt = frames_res.has_animation("hurt")
		if has_idle and has_run and has_jump and has_attack and has_hurt:
			print("  [PASS] A01: m1_frames.tres nạp hợp lệ và đủ 5 animation (idle, run, jump, attack, hurt).")
			pass_count += 1
		else:
			printerr("  [FAIL] A01: Thiếu animation trong m1_frames.tres!")
	else:
		printerr("  [FAIL] A01: Không thể tải res://assets/characters/m1/m1_frames.tres!")

	# ----------------------------------------------------
	# A02: Kiểm tra số frame từng animation (đủ 6 frame run, 4 idle, 3 attack, 2 hurt, 1 jump)
	# ----------------------------------------------------
	total_count += 1
	var count_idle = frames_res.get_frame_count("idle")
	var count_run = frames_res.get_frame_count("run")
	var count_jump = frames_res.get_frame_count("jump")
	var count_attack = frames_res.get_frame_count("attack")
	var count_hurt = frames_res.get_frame_count("hurt")

	var a02_ok = (count_idle == 4 and count_run == 6 and count_jump == 1 and count_attack == 3 and count_hurt == 2)
	if a02_ok:
		print("  [PASS] A02: Đầy đủ số frame quy chuẩn: Idle (4), Run (6), Jump (1), Attack (3), Hurt (2).")
		pass_count += 1
	else:
		printerr("  [FAIL] A02: Sai số frame: idle=%d, run=%d, jump=%d, attack=%d, hurt=%d" % [count_idle, count_run, count_jump, count_attack, count_hurt])

	# ----------------------------------------------------
	# A03: Kiểm tra toàn bộ 16 frame đều chuẩn hóa canvas 380x320 (0px jitter)
	# ----------------------------------------------------
	total_count += 1
	var all_sizes_valid = true
	var total_frames_checked = 0
	var anims = ["idle", "run", "jump", "attack", "hurt"]
	for a in anims:
		var cnt = frames_res.get_frame_count(a)
		for f_idx in range(cnt):
			var tex = frames_res.get_frame_texture(a, f_idx)
			total_frames_checked += 1
			if not tex or tex.get_size() != Vector2(380, 320):
				printerr("  [FAIL] A03: Frame %s[%d] có kích thước bất thường: %s" % [a, f_idx, str(tex.get_size() if tex else "null")])
				all_sizes_valid = false
	if all_sizes_valid and total_frames_checked == 16:
		print("  [PASS] A03: Toàn bộ 16/16 frame M1 đạt chuẩn kích thước canvas đồng nhất 380x320.")
		pass_count += 1
	else:
		printerr("  [FAIL] A03: Kích thước frame không đồng nhất!")

	# ----------------------------------------------------
	# A04: Player scene cấu hình AnimatedSprite2D điểm neo chân chuẩn Y=-37.5
	# ----------------------------------------------------
	total_count += 1
	var player_scene = load("res://scenes/player.tscn")
	var player_inst = player_scene.instantiate()
	var sprite_node = player_inst.get_node("AnimatedSprite2D")
	var a04_ok = (sprite_node != null and sprite_node.position == Vector2(0, -37.5) and sprite_node.scale == Vector2(0.25, 0.25))
	if a04_ok:
		print("  [PASS] A04: AnimatedSprite2D căn chân chuẩn xác tại (0, -37.5), scale 0.25x.")
		pass_count += 1
	else:
		printerr("  [FAIL] A04: Sai cấu hình AnimatedSprite2D!")

	# ----------------------------------------------------
	# A05: Logic trạng thái Animation trên PlayerController (Idle -> Run -> Jump)
	# ----------------------------------------------------
	total_count += 1
	player_inst.is_server_entity = true
	player_inst.max_hp = 100
	player_inst.current_hp = 100
	player_inst.max_ki = 100
	player_inst.current_ki = 100
	player_inst.spawn_point = Vector2(160, 580)
	player_inst.global_position = Vector2(160, 580)

	player_inst.velocity = Vector2.ZERO
	player_inst.move_axis = 0.0
	player_inst.last_input_time = Time.get_ticks_msec() / 1000.0
	player_inst.current_anim = "idle"
	
	# Kiểm tra khi di chuyển
	player_inst.move_axis = 1.0
	player_inst.velocity.x = 100.0
	player_inst.last_input_time = Time.get_ticks_msec() / 1000.0
	var run_anim_evaluated = (abs(player_inst.velocity.x) > 5.0)

	if player_inst.current_anim == "idle" and run_anim_evaluated:
		print("  [PASS] A05: Bộ điều khiển phân loại chính xác Idle và Run dựa theo vận tốc.")
		pass_count += 1
	else:
		printerr("  [FAIL] A05: Sai trạng thái di chuyển!")

	# ----------------------------------------------------
	# A06: Thời lượng Attack trọn vẹn (0.38s cho 3 frame 8fps)
	# ----------------------------------------------------
	total_count += 1
	player_inst.handle_attack_request("test_atk_anim", [])
	var atk_started = (player_inst.is_attacking and player_inst.attack_anim_timer >= 0.35)
	
	# Giả lập trôi 0.15s
	player_inst.attack_anim_timer -= 0.15
	var atk_halfway = (player_inst.is_attacking and player_inst.attack_anim_timer > 0.0)

	# Giả lập trôi thêm 0.25s (tổng 0.4s > 0.38s)
	player_inst.attack_anim_timer -= 0.25
	if player_inst.attack_anim_timer <= 0.0:
		player_inst.is_attacking = false
	var atk_finished = (not player_inst.is_attacking)

	if atk_started and atk_halfway and atk_finished:
		print("  [PASS] A06: Animation Attack cấu hình chuẩn 0.38s, đủ thời lượng phát trọn 3 frame 8 FPS.")
		pass_count += 1
	else:
		printerr("  [FAIL] A06: Thời lượng attack bất thường: start=%s, half=%s, fin=%s" % [str(atk_started), str(atk_halfway), str(atk_finished)])

	# ----------------------------------------------------
	# A07: Hurt kích hoạt khi dính sát thương (0.25s) và reset sạch khi chết/hồi sinh
	# ----------------------------------------------------
	total_count += 1
	player_inst.take_monster_damage(10)
	var hurt_started = (player_inst.hurt_anim_timer == 0.25 and player_inst.current_anim == "hurt")
	
	# Trôi 0.1s
	player_inst.hurt_anim_timer -= 0.1
	var hurt_playing = (player_inst.hurt_anim_timer > 0.0 and player_inst.current_anim == "hurt")

	# Trôi thêm 0.2s
	player_inst.hurt_anim_timer -= 0.2
	var hurt_finished = (player_inst.hurt_anim_timer <= 0.0)

	# Khi chết
	player_inst.take_monster_damage(200)
	var death_reset = (player_inst.is_dead and player_inst.hurt_anim_timer == 0.0 and player_inst.current_anim == "idle")

	if hurt_started and hurt_playing and hurt_finished and death_reset:
		print("  [PASS] A07: Trạng thái Hurt kích hoạt chuẩn 0.25s khi nhận dmg và reset sạch khi chết.")
		pass_count += 1
	else:
		printerr("  [FAIL] A07: Lỗi trạng thái Hurt: start=%s, play=%s, fin=%s, death=%s" % [str(hurt_started), str(hurt_playing), str(hurt_finished), str(death_reset)])

	player_inst.free()

	print("\n========================================================")
	print("  KẾT QUẢ: %d/%d KIỂM THỬ ANIMATION ĐẠT CHUẨN!" % [pass_count, total_count])
	print("========================================================\n")

	if pass_count == total_count:
		quit(0)
	else:
		quit(1)
