@tool
extends SceneTree

# Kịch bản sinh tài nguyên đồ họa bản đồ Đồng Cỏ Anime Fantasy (v0.1.2B-1)
# Bám sát phong cách 2D Anime Side-scrolling, mượt mà, chiều sâu Parallax đa tầng

func _init() -> void:
	print("\n========================================================")
	print("  KHỞI TẠO BỘ TÀI NGUYÊN ĐỒ HỌA BẢN ĐỒ ANIME FANTASY")
	print("========================================================\n")

	DirAccess.make_dir_absolute("res://assets/environment")

	# 1. Sinh Layer Trời & Ánh Dương (Sky & Sun Rays): 1920 x 720
	_generate_sky_layer("res://assets/environment/bg_sky.png", 1920, 720)

	# 2. Sinh Layer Núi Xa & Biển Mây (Far Mountains): 1920 x 450
	_generate_far_mountains("res://assets/environment/bg_far_mountains.png", 1920, 450)

	# 3. Sinh Layer Đồi Xanh Trung Cảnh (Mid Hills & Tree Silhouettes): 1920 x 400
	_generate_mid_hills("res://assets/environment/bg_mid_hills.png", 1920, 400)

	# 4. Sinh Layer Cổ Thụ & Tảng Đá Rêu (Near Fantasy Trees & Ruins): 2560 x 480
	_generate_near_trees("res://assets/environment/bg_near_trees.png", 2560, 480)

	# 5. Sinh Layer Mặt Đất & Viền Cỏ Anime Đa Chi Tiết (Ground Platform): 2560 x 140
	_generate_ground_platform("res://assets/environment/bg_ground_platform.png", 2560, 140)

	print("\n[Asset Generator] Hoàn tất toàn bộ 5 tài nguyên môi trường mới!")
	quit(0)

# -----------------------------------------------------------------------------
# 1. Bầu trời Anime rực rỡ + Hào quang mặt trời
# -----------------------------------------------------------------------------
func _generate_sky_layer(path: String, width: int, height: int) -> void:
	print("  -> Đang vẽ bầu trời Anime: %s (%dx%d)..." % [path, width, height])
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)

	var c_top = Color(0.12, 0.45, 0.78, 1.0)     # Xanh sapphire trên cao
	var c_mid = Color(0.35, 0.72, 0.94, 1.0)     # Xanh ngọc thanh khiết
	var c_horizon = Color(0.82, 0.94, 0.98, 1.0) # Vệt sáng chân trời

	var sun_x = width * 0.82
	var sun_y = height * 0.18

	for y in range(height):
		var t = float(y) / float(height)
		var base_col: Color
		if t < 0.5:
			base_col = c_top.lerp(c_mid, t * 2.0)
		else:
			base_col = c_mid.lerp(c_horizon, (t - 0.5) * 2.0)

		for x in range(width):
			# Vầng quang mặt trời & tia sáng góc trên phải
			var dx = x - sun_x
			var dy = y - sun_y
			var dist = sqrt(dx * dx + dy * dy)
			
			var final_col = base_col
			if dist < 450.0:
				var sun_glow = (1.0 - dist / 450.0)
				sun_glow = sun_glow * sun_glow
				final_col = final_col.lerp(Color(1.0, 0.98, 0.85, 1.0), sun_glow * 0.6)
			
			if dist < 70.0:
				var sun_core = 1.0 - dist / 70.0
				final_col = final_col.lerp(Color(1.0, 1.0, 0.95, 1.0), sun_core * 0.9)

			img.set_pixel(x, y, final_col)

	# Vẽ các đám mây anime bồng bềnh ở chân trời
	_draw_soft_cloud(img, width * 0.15, height * 0.52, 140, 45, Color(1, 1, 1, 0.75))
	_draw_soft_cloud(img, width * 0.45, height * 0.48, 180, 55, Color(1, 1, 1, 0.8))
	_draw_soft_cloud(img, width * 0.72, height * 0.55, 160, 50, Color(1, 1, 1, 0.75))
	_draw_soft_cloud(img, width * 0.95, height * 0.50, 130, 40, Color(1, 1, 1, 0.7))

	img.save_png(path)

func _draw_soft_cloud(img: Image, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	var x_start = maxi(0, int(cx - rx))
	var x_end = mini(img.get_width(), int(cx + rx))
	var y_start = maxi(0, int(cy - ry))
	var y_end = mini(img.get_height(), int(cy + ry))

	for y in range(y_start, y_end):
		for x in range(x_start, x_end):
			var nx = (x - cx) / rx
			var ny = (y - cy) / ry
			var d = nx * nx + ny * ny
			if d <= 1.0:
				var alpha = (1.0 - d) * col.a
				var cur = img.get_pixel(x, y)
				img.set_pixel(x, y, cur.lerp(Color(col.r, col.g, col.b, 1.0), alpha))

# -----------------------------------------------------------------------------
# 2. Núi xa phủ sương & thung lũng Anime (Far Mountains)
# -----------------------------------------------------------------------------
func _generate_far_mountains(path: String, width: int, height: int) -> void:
	print("  -> Đang vẽ dãy núi xa mờ sương: %s (%dx%d)..." % [path, width, height])
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0)) # Nền trong suốt

	var c_peak = Color(0.42, 0.68, 0.75, 0.95)   # Đỉnh núi xanh băng lam
	var c_base = Color(0.68, 0.85, 0.88, 0.4)    # Chân núi mờ hơi sương
	var c_shade = Color(0.32, 0.55, 0.65, 0.95)  # Bóng sườn núi

	# Dựng các dãy núi trùng điệp
	var peak_x = [0.0, 160.0, 380.0, 620.0, 850.0, 1100.0, 1340.0, 1580.0, 1800.0, 1920.0]
	var peak_y = [180.0, 90.0, 140.0, 80.0, 130.0, 70.0, 120.0, 95.0, 140.0, 180.0]

	for x in range(width):
		# Tìm điểm đỉnh tương ứng
		var t_pos = float(x) / float(width) * 9.0
		var idx = int(t_pos)
		var frac = t_pos - idx
		var y_top = lerp(peak_y[idx], peak_y[mini(idx + 1, 9)], frac)
		# Thêm biến thiên tự nhiên
		y_top += sin(x * 0.04) * 8.0 + cos(x * 0.015) * 14.0

		for y in range(int(y_top), height):
			var v_t = float(y - y_top) / float(height - y_top)
			var base = c_peak.lerp(c_base, v_t)
			
			# Tạo sườn núi sáng / tối theo ánh nắng (chiếu từ phải qua trái)
			var is_shadow = (sin(x * 0.03 + y * 0.01) > 0.1)
			if is_shadow:
				base = base.lerp(c_shade, 0.35)
			
			# Độ mờ tan dần ở chân núi
			base.a = clamp(1.0 - v_t * 0.4, 0.0, 0.95)
			img.set_pixel(x, y, base)

	img.save_png(path)

# -----------------------------------------------------------------------------
# 3. Đồi xanh trung cảnh & cây mờ (Mid Hills)
# -----------------------------------------------------------------------------
func _generate_mid_hills(path: String, width: int, height: int) -> void:
	print("  -> Đang vẽ đồi xanh trung cảnh: %s (%dx%d)..." % [path, width, height])
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var c_hill_top = Color(0.38, 0.74, 0.42, 1.0) # Xanh non tràn đầy sức sống
	var c_hill_bot = Color(0.24, 0.52, 0.30, 0.9) # Xanh lục đậm dưới thung lũng
	var c_rock = Color(0.55, 0.62, 0.58, 1.0)

	for x in range(width):
		# Đường cong đồi thoai thoải anime
		var hill_y = 120.0 + sin(x * 0.006) * 55.0 + cos(x * 0.018) * 25.0 + sin(x * 0.035) * 8.0
		
		for y in range(int(hill_y), height):
			var vt = float(y - hill_y) / float(height - hill_y)
			var col = c_hill_top.lerp(c_hill_bot, vt)

			# Điểm xuyết vạt đồi cỏ sáng rọi
			if sin(x * 0.02 + y * 0.03) > 0.4:
				col = col.lerp(Color(0.52, 0.85, 0.48, 1.0), 0.25)

			img.set_pixel(x, y, col)

	# Vẽ thêm các lùm cây và phiến đá cổ rải rác trên đồi
	for i in range(12):
		var tx = int(i * 160 + 60)
		var ty = int(120.0 + sin(tx * 0.006) * 55.0 + cos(tx * 0.018) * 25.0)
		_draw_anime_tree_cluster(img, tx, ty - 15, 30, 24, Color(0.2, 0.58, 0.28, 0.95))

	img.save_png(path)

func _draw_anime_tree_cluster(img: Image, cx: int, cy: int, rx: int, ry: int, col: Color) -> void:
	for y in range(cy - ry, cy + ry):
		for x in range(cx - rx, cx + rx):
			if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
				var dx = float(x - cx) / float(rx)
				var dy = float(y - cy) / float(ry)
				if dx * dx + dy * dy <= 1.0:
					# Tán lá có bóng sáng tối
					var leaf_col = col
					if dy < -0.2:
						leaf_col = leaf_col.lerp(Color(0.45, 0.82, 0.4, 1.0), 0.4)
					img.set_pixel(x, y, leaf_col)

# -----------------------------------------------------------------------------
# 4. Cổ thụ Anime & Cột đá rêu phong (Near Fantasy Trees & Ruins)
# -----------------------------------------------------------------------------
func _generate_near_trees(path: String, width: int, height: int) -> void:
	print("  -> Đang vẽ cổ thụ thần tiên và tảng đá rêu: %s (%dx%d)..." % [path, width, height])
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Phân bổ 7 cây đại thụ thần kỳ dọc theo chiều dài map 2560 px
	var tree_x_positions = [180, 540, 920, 1320, 1700, 2100, 2450]
	
	for tx in tree_x_positions:
		_draw_fantasy_ancient_tree(img, tx, height)

	img.save_png(path)

func _draw_fantasy_ancient_tree(img: Image, base_x: int, ground_y: int) -> void:
	var trunk_col = Color(0.44, 0.34, 0.26, 1.0)
	var trunk_dark = Color(0.30, 0.22, 0.16, 1.0)
	var trunk_moss = Color(0.35, 0.55, 0.30, 1.0)

	var trunk_height = 280
	var canopy_center_y = ground_y - trunk_height

	# 1. Vẽ thân cây vặn xoắn cổ kính (Twisted anime banyan trunk)
	for y in range(canopy_center_y + 40, ground_y):
		var progress = float(ground_y - y) / float(trunk_height)
		var center_offset = sin(progress * 3.14) * 22.0
		var current_cx = base_x + int(center_offset)
		var trunk_radius = int(lerp(28.0, 16.0, progress)) # Thân to ở gốc, thon ở trên

		for x in range(current_cx - trunk_radius, current_cx + trunk_radius):
			if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
				var edge_dist = abs(float(x - current_cx) / float(trunk_radius))
				var pix_col = trunk_col
				if edge_dist > 0.7:
					pix_col = trunk_dark
				elif y > ground_y - 60:
					pix_col = pix_col.lerp(trunk_moss, 0.5) # Rêu ở gốc cây
				img.set_pixel(x, y, pix_col)

	# 2. Vẽ tán lá Anime đa tầng bồng bềnh (Lush layered canopy)
	var leaf_c_base = Color(0.18, 0.58, 0.24, 0.98)
	var leaf_c_light = Color(0.42, 0.82, 0.35, 1.0)
	var leaf_c_dark = Color(0.12, 0.40, 0.16, 1.0)

	# 5 cụm lá tạo hình tán cây rộng lớn (đường kính ~220px)
	var clumps = [
		Vector2i(base_x - 45, canopy_center_y + 10),
		Vector2i(base_x + 45, canopy_center_y + 10),
		Vector2i(base_x - 30, canopy_center_y - 35),
		Vector2i(base_x + 30, canopy_center_y - 35),
		Vector2i(base_x, canopy_center_y - 65)
	]

	for clump in clumps:
		var cr_x = 75
		var cr_y = 55
		for y in range(clump.y - cr_y, clump.y + cr_y):
			for x in range(clump.x - cr_x, clump.x + cr_x):
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					var dx = float(x - clump.x) / float(cr_x)
					var dy = float(y - clump.y) / float(cr_y)
					var d = dx * dx + dy * dy
					if d <= 1.0:
						var leaf_col = leaf_c_base
						if dy < -0.2:
							leaf_col = leaf_col.lerp(leaf_c_light, 0.65) # Ánh nắng chiếu đỉnh lá
						elif dy > 0.3:
							leaf_col = leaf_col.lerp(leaf_c_dark, 0.6)  # Bóng tối dưới đáy cụm
						img.set_pixel(x, y, leaf_col)

# -----------------------------------------------------------------------------
# 5. Mặt đất Anime & Viền cỏ sống động (Ground Platform: 2560 x 140)
# -----------------------------------------------------------------------------
func _generate_ground_platform(path: String, width: int, height: int) -> void:
	print("  -> Đang vẽ mặt đất và viền cỏ chi tiết: %s (%dx%d)..." % [path, width, height])
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)

	var c_grass_top = Color(0.45, 0.82, 0.35, 1.0) # Cỏ xanh nõn bề mặt
	var c_grass_mid = Color(0.24, 0.62, 0.22, 1.0) # Lớp cỏ dày
	var c_dirt_top = Color(0.55, 0.40, 0.28, 1.0)  # Lớp đất mùn trên
	var c_dirt_mid = Color(0.42, 0.30, 0.20, 1.0)  # Lớp đất sét ấm
	var c_rock_strata = Color(0.32, 0.25, 0.18, 1.0)# Tầng đá sâu

	# Chiều cao mặt đất: Y=0 trong asset ứng với Y=580 trong map
	# Lớp viền cỏ: Y=0..20 px
	# Lớp đất đá: Y=20..140 px

	for x in range(width):
		# Biến thiên viền cỏ tự nhiên
		var grass_depth = 16.0 + sin(x * 0.12) * 3.5 + cos(x * 0.05) * 2.0

		for y in range(height):
			var col: Color
			if y < grass_depth:
				# Vùng cỏ
				var gt = float(y) / grass_depth
				col = c_grass_top.lerp(c_grass_mid, gt)
				# Từng sợi cỏ đan xen
				if (x + y * 2) % 4 == 0:
					col = col.lerp(Color(0.6, 0.9, 0.4, 1.0), 0.3)
			elif y < grass_depth + 35.0:
				# Tầng đất mùn
				var dt = float(y - grass_depth) / 35.0
				col = c_dirt_top.lerp(c_dirt_mid, dt)
				# Hạt sỏi / đất lấm tấm
				if (x * 7 + y * 13) % 17 == 0:
					col = col.lerp(Color(0.65, 0.55, 0.45, 1.0), 0.4)
			else:
				# Tầng đá sâu
				var st = float(y - grass_depth - 35.0) / float(height - grass_depth - 35.0)
				col = c_dirt_mid.lerp(c_rock_strata, st)
				# Đường rãnh nứt phiến đá
				if sin(x * 0.04 + y * 0.08) > 0.85:
					col = col.lerp(Color(0.2, 0.15, 0.1, 1.0), 0.45)

			img.set_pixel(x, y, col)

	# Điểm xuyết hoa dại trắng/hồng và cỏ đâm chồi nhô lên mặt đất
	for i in range(120):
		var fx = int(i * 21.3) % width
		_draw_wild_flower(img, fx, 3)

	img.save_png(path)

func _draw_wild_flower(img: Image, x: int, y: int) -> void:
	var flower_col = Color(1.0, 0.95, 0.8, 1.0) # Hoa trắng nhụy vàng
	if x % 3 == 0:
		flower_col = Color(1.0, 0.75, 0.85, 1.0) # Hoa cánh hồng
	elif x % 5 == 0:
		flower_col = Color(0.75, 0.9, 1.0, 1.0)  # Hoa xanh ma pháp

	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var px = x + dx
			var py = y + dy
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				if abs(dx) + abs(dy) <= 2:
					img.set_pixel(px, py, flower_col)
	if y >= 0 and y < img.get_height() and x >= 0 and x < img.get_width():
		img.set_pixel(x, y, Color(1.0, 0.85, 0.2, 1.0)) # Nhụy vàng
