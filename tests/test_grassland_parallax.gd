extends SceneTree

var passed = 0
var total = 0

func _check(test_name: String, condition: bool):
	total += 1
	if condition:
		passed += 1
		print("[PASS] %s" % test_name)
	else:
		push_error("[FAIL] %s" % test_name)

func _init():
	print("--- BẮT ĐẦU KIỂM THỬ TỰ ĐỘNG BẢN ĐỒ ĐỒNG CỎ & PARALLAX 2D (v0.1.2B-1) ---")
	
	# Test 1: Kiểm tra các asset texture môi trường tồn tại
	var textures = [
		"res://assets/environment/bg_sky.png",
		"res://assets/environment/bg_far_mountains.png",
		"res://assets/environment/bg_mid_hills.png",
		"res://assets/environment/bg_near_trees.png",
		"res://assets/environment/bg_ground_platform.png"
	]
	for path in textures:
		var tex = ResourceLoader.load(path)
		_check("Asset texture tồn tại & nạp thành công: %s" % path, tex != null)
	
	# Test 2: Nạp Scene test_grassland.tscn
	var scene_res = ResourceLoader.load("res://scenes/test_grassland.tscn")
	_check("Nạp scene test_grassland.tscn thành công", scene_res != null)
	var scene = scene_res.instantiate()
	_check("Khởi tạo node scene test_grassland thành công", scene != null)
	
	# Test 3: Kiểm tra các tầng Parallax2D
	var sky = scene.get_node_or_null("ParallaxSky")
	_check("Tầng ParallaxSky tồn tại", sky != null and sky is Parallax2D)
	if sky:
		_check("ParallaxSky repeat_size == Vector2(1920, 0)", sky.repeat_size == Vector2(1920, 0))
		_check("ParallaxSky scroll_scale == Vector2(0, 0)", sky.scroll_scale == Vector2(0, 0))
	
	var mountains = scene.get_node_or_null("ParallaxMountains")
	_check("Tầng ParallaxMountains tồn tại", mountains != null and mountains is Parallax2D)
	if mountains:
		_check("ParallaxMountains repeat_size == Vector2(1920, 0)", mountains.repeat_size == Vector2(1920, 0))
		_check("ParallaxMountains scroll_scale == Vector2(0.15, 0.05)", mountains.scroll_scale == Vector2(0.15, 0.05))
	
	var hills = scene.get_node_or_null("ParallaxHills")
	_check("Tầng ParallaxHills tồn tại", hills != null and hills is Parallax2D)
	if hills:
		_check("ParallaxHills repeat_size == Vector2(1920, 0)", hills.repeat_size == Vector2(1920, 0))
		_check("ParallaxHills scroll_scale == Vector2(0.35, 0.1)", hills.scroll_scale == Vector2(0.35, 0.1))
	
	var trees = scene.get_node_or_null("ParallaxTrees")
	_check("Tầng ParallaxTrees tồn tại", trees != null and trees is Parallax2D)
	if trees:
		_check("ParallaxTrees repeat_size == Vector2(2560, 0)", trees.repeat_size == Vector2(2560, 0))
		_check("ParallaxTrees scroll_scale == Vector2(0.65, 0.2)", trees.scroll_scale == Vector2(0.65, 0.2))
	
	# Test 4: Kiểm tra Mặt đất hiển thị (GroundVisual)
	var ground_vis = scene.get_node_or_null("GroundVisual")
	_check("GroundVisual tồn tại và là Sprite2D", ground_vis != null and ground_vis is Sprite2D)
	if ground_vis:
		_check("GroundVisual position == Vector2(0, 580)", ground_vis.position == Vector2(0, 580))
		_check("GroundVisual texture hợp lệ", ground_vis.texture != null)
	
	# Test 5: Kiểm tra StaticColliders không bị thay đổi logic
	var ground_col = scene.get_node_or_null("StaticColliders/GroundCollision")
	_check("GroundCollision CollisionShape2D tồn tại", ground_col != null and ground_col is CollisionShape2D)
	if ground_col:
		_check("GroundCollision position == Vector2(1280, 650)", ground_col.position == Vector2(1280, 650))
		_check("GroundCollision shape size == Vector2(2560, 140)", ground_col.shape.size == Vector2(2560, 140))
		
	var left_wall = scene.get_node_or_null("StaticColliders/LeftWallCollision")
	_check("LeftWallCollision tồn tại", left_wall != null and left_wall is CollisionShape2D)
	var right_wall = scene.get_node_or_null("StaticColliders/RightWallCollision")
	_check("RightWallCollision tồn tại", right_wall != null and right_wall is CollisionShape2D)
	var ceiling = scene.get_node_or_null("StaticColliders/CeilingCollision")
	_check("CeilingCollision tồn tại", ceiling != null and ceiling is CollisionShape2D)
	
	# Test 6: Kiểm tra SpawnPoint không bị xê dịch
	var spawn = scene.get_node_or_null("SpawnPoint")
	_check("SpawnPoint tồn tại", spawn != null)
	if spawn:
		_check("SpawnPoint position == Vector2(160, 580)", spawn.position == Vector2(160, 580))
		
	# Test 7: Kiểm tra Node Entities
	var entities = scene.get_node_or_null("Entities")
	_check("Entities container tồn tại để chứa Player và Slimes", entities != null)
	
	# Dọn dẹp bộ nhớ
	scene.free()
	
	print("\n--- KẾT QUẢ KIỂM THỬ BẢN ĐỒ & PARALLAX: %d/%d PASS ---" % [passed, total])
	if passed == total:
		print(">> TẤT CẢ CÁC BÀI TEST BẢN ĐỒ & PARALLAX ĐẠT 100%! <<")
	else:
		push_error(">> CÓ BÀI TEST THẤT BẠI! <<")
	
	quit(0 if passed == total else 1)
