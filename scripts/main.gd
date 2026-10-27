extends Control

@onready var world_view: Node2D = $WorldView
@onready var ui_container: Control = $UI
@onready var status_label: Label = $UI/CenterContainer/VBoxContainer/StatusLabel
@onready var info_label: Label = $UI/CenterContainer/VBoxContainer/InfoLabel
@onready var log_box: RichTextLabel = $UI/CenterContainer/VBoxContainer/LogBox
@onready var btn_play_all: Button = $UI/CenterContainer/VBoxContainer/HBoxContainer/BtnPlayAll
@onready var btn_server: Button = $UI/CenterContainer/VBoxContainer/HBoxContainer/BtnServer
@onready var btn_client: Button = $UI/CenterContainer/VBoxContainer/HBoxContainer/BtnClient
@onready var btn_reset_save: Button = $UI/CenterContainer/VBoxContainer/HBoxContainer/BtnResetSave

@onready var hud: CanvasLayer = $HUD
@onready var char_stats_panel: Control = $CharacterStatsPanel
@onready var death_panel: Control = $DeathRespawnPanel
@onready var disconnect_modal: Control = $DisconnectModal
@onready var btn_dismiss_modal: Button = $DisconnectModal/Center/Box/VBox/BtnDismiss

var server_world_script = preload("res://scripts/server_world.gd")
var grassland_scene = preload("res://scenes/test_grassland.tscn")
var player_scene = preload("res://scenes/player.tscn")
var slime_scene = preload("res://scenes/slime.tscn")
var gravestone_scene = preload("res://scenes/gravestone.tscn")

var server_world_node: Node2D = null
var client_map_instance: Node2D = null
var client_player_entity: CharacterBody2D = null
var client_slimes: Array[CharacterBody2D] = []
var current_gravestone: Node2D = null

# Lưu giữ dữ liệu tiến trình mới nhất
var latest_tl: int = 0
var latest_tn: int = 0
var latest_stats: Dictionary = {"hp_current": 100, "hp_max": 100, "ki_current": 100, "ki_max": 100}

func _ready() -> void:
	hud.visible = false
	char_stats_panel.visible = false
	death_panel.visible = false
	disconnect_modal.visible = false
	
	# Kết nối signal từ NetworkBridge
	NetworkBridge.server_started.connect(_on_server_started)
	NetworkBridge.server_failed.connect(_on_server_failed)
	NetworkBridge.peer_connected_event.connect(_on_peer_connected)
	NetworkBridge.peer_disconnected_event.connect(_on_peer_disconnected)
	NetworkBridge.client_connected_to_server.connect(_on_connected)
	NetworkBridge.client_connection_failed.connect(_on_connection_failed)
	NetworkBridge.client_server_disconnected.connect(_on_server_disconnected)
	NetworkBridge.snapshot_received.connect(_on_snapshot_received)
	NetworkBridge.combat_result_received.connect(_on_combat_result)
	NetworkBridge.progression_received.connect(_on_progression_received)
	NetworkBridge.respawn_result_received.connect(_on_respawn_result)
	
	btn_play_all.pressed.connect(_on_btn_play_all_pressed)
	btn_server.pressed.connect(_on_btn_server_pressed)
	btn_client.pressed.connect(_on_btn_client_pressed)
	btn_reset_save.pressed.connect(_on_btn_reset_save_pressed)
	btn_dismiss_modal.pressed.connect(_on_btn_dismiss_modal_pressed)
	
	hud.open_character_menu_requested.connect(func(): char_stats_panel.toggle_panel())
	
	# Xử lý cờ CLI
	var args: PackedStringArray = OS.get_cmdline_args()
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	var all_args: Array = []
	all_args.append_array(args)
	all_args.append_array(user_args)
	
	_log("Khởi động Ma Pháp Huyễn Giới 2D - Prototype v0.1 hoàn chỉnh")
	
	var run_as_server: bool = false
	var run_as_client: bool = false
	
	for arg in all_args:
		if arg == "--server":
			run_as_server = true
		elif arg == "--client":
			run_as_client = true
			
	if run_as_server:
		_log("Phát hiện cờ --server. Chạy Server Headless...")
		_start_server()
	elif run_as_client:
		_log("Phát hiện cờ --client. Bắt đầu Client kết nối...")
		_start_client()
	else:
		_log("Chế độ Editor / UI: Chọn Server hoặc Client bên dưới.")
		_update_status("Sẵn sàng. Hãy chọn chạy Server hoặc Client.", Color.WHITE)

func _input(event: InputEvent) -> void:
	# Khóa mở Menu K khi đang ở trạng thái tử vong
	if death_panel.visible:
		return
	if hud.visible:
		if event.is_action_pressed("toggle_character_menu"):
			char_stats_panel.toggle_panel()
			get_viewport().set_input_as_handled()

func _on_btn_play_all_pressed() -> void:
	_log("Khởi động chế độ Chơi Ngay: Mở Server nội bộ và bật Client...")
	_start_server()
	# Tự động khởi chạy tiến trình Client
	var exe_path = OS.get_executable_path()
	var project_path = ProjectSettings.globalize_path("res://")
	var pid = OS.create_process(exe_path, ["--path", project_path, "--client"])
	if pid > 0:
		_log("Đã bật cửa sổ Client (PID: %d). Game đang kết nối!" % pid)
	else:
		_log("Cảnh báo: Không thể tự bật Client. Vui lòng mở thêm 1 cửa sổ và bấm 'Chạy Client'!")

func _start_server() -> void:
	_update_status("Đang mở Server 127.0.0.1:%d..." % GameConfig.SERVER_PORT, Color.YELLOW)
	btn_play_all.disabled = true
	btn_server.disabled = true
	btn_client.disabled = true
	
	if not is_instance_valid(server_world_node):
		server_world_node = Node2D.new()
		server_world_node.name = "ServerWorld"
		server_world_node.set_script(server_world_script)
		add_child(server_world_node)
		
	var ok: bool = NetworkBridge.start_server(GameConfig.SERVER_PORT, GameConfig.MAX_CLIENTS)
	if not ok:
		_update_status("Khởi động Server THẤT BẠI!", Color.RED)
		btn_play_all.disabled = false
		btn_server.disabled = false
		btn_client.disabled = false

func _start_client() -> void:
	_update_status("Đang kết nối tới 127.0.0.1:%d..." % GameConfig.SERVER_PORT, Color.YELLOW)
	btn_play_all.disabled = true
	btn_server.disabled = true
	btn_client.disabled = true
	var ok: bool = NetworkBridge.start_client(GameConfig.SERVER_IP, GameConfig.SERVER_PORT)
	if not ok:
		_update_status("Không thể tạo kết nối Client!", Color.RED)
		btn_play_all.disabled = false
		btn_server.disabled = false
		btn_client.disabled = false

func _on_btn_server_pressed() -> void:
	_start_server()

func _on_btn_client_pressed() -> void:
	_start_client()

func _on_btn_reset_save_pressed() -> void:
	SaveRepository.reset_profile()
	_log("Đã reset file save user://saves/player_save.json về mặc định.")
	_update_status("Đã reset dữ liệu save.", Color.WHITE)

func _on_btn_dismiss_modal_pressed() -> void:
	disconnect_modal.visible = false
	_cleanup_world()
	ui_container.visible = true
	btn_play_all.disabled = false
	btn_server.disabled = false
	btn_client.disabled = false
	_update_status("Sẵn sàng.", Color.WHITE)

func _cleanup_world() -> void:
	for s in client_slimes:
		if is_instance_valid(s):
			s.queue_free()
	client_slimes.clear()
	
	if is_instance_valid(client_player_entity):
		client_player_entity.queue_free()
		client_player_entity = null
	if is_instance_valid(client_map_instance):
		client_map_instance.queue_free()
		client_map_instance = null
	if is_instance_valid(server_world_node):
		server_world_node.queue_free()
		server_world_node = null

# Network signals
func _on_server_started(port: int) -> void:
	_update_status("SERVER ĐANG CHẠY (127.0.0.1:%d) - 8 Slime đã sinh" % port, Color.GREEN)
	_log("Server đã mở cổng %d thành công." % port)

func _on_server_failed(port: int) -> void:
	_update_status("LỖI: Server không thể mở cổng %d!" % port, Color.RED)

func _on_peer_connected(id: int) -> void:
	_update_status("SERVER: Client đã kết nối! (Peer ID: %d)" % id, Color.GREEN)
	_log("Client Peer %d đã vào thế giới." % id)

func _on_peer_disconnected(id: int) -> void:
	_update_status("SERVER: Client đã ngắt kết nối! (Peer ID: %d)" % id, Color.ORANGE)
	_log("Client Peer %d đã thoát. Dữ liệu đã được lưu bền vững." % id)

func _on_connected() -> void:
	_update_status("CLIENT: ĐÃ KẾT NỐI THÀNH CÔNG!", Color.GREEN)
	_log("Vào map đồng cỏ thành công! Thiết lập HUD và 8 Slime...")
	_setup_client_world()

func _on_connection_failed() -> void:
	_update_status("CLIENT: KẾT NỐI THẤT BẠI! (Server chưa bật hoặc từ chối)", Color.RED)
	_log("Không thể kết nối Server 127.0.0.1:24567.")
	btn_play_all.disabled = false
	btn_server.disabled = false
	btn_client.disabled = false

func _on_server_disconnected() -> void:
	_log("MẤT KẾT NỐI VỚI SERVER! Dừng điều khiển.")
	hud.visible = false
	char_stats_panel.visible = false
	death_panel.visible = false
	disconnect_modal.visible = true

# Dựng thế giới trên Client
func _setup_client_world() -> void:
	ui_container.visible = false
	hud.visible = true
	char_stats_panel.visible = false
	death_panel.visible = false
	disconnect_modal.visible = false
	
	if current_gravestone != null:
		current_gravestone.queue_free()
		current_gravestone = null
	
	client_map_instance = grassland_scene.instantiate()
	world_view.add_child(client_map_instance)
	
	# Tạo M1
	client_player_entity = player_scene.instantiate()
	client_player_entity.is_server_entity = false
	
	var spawn_pos = Vector2(160, 580)
	if client_map_instance.has_node("SpawnPoint"):
		spawn_pos = client_map_instance.get_node("SpawnPoint").global_position
		
	client_player_entity.global_position = spawn_pos
	client_player_entity.target_position = spawn_pos
	client_map_instance.get_node("Entities").add_child(client_player_entity)
	
	# Tạo 8 Slime
	client_slimes.clear()
	var entities_node = client_map_instance.get_node("Entities")
	var start_x = 500.0
	var ground_y = 580.0
	for i in range(GameConfig.SLIME_COUNT):
		var pos = Vector2(start_x + i * GameConfig.SLIME_SPAWN_SPACING, ground_y)
		var slime_inst = slime_scene.instantiate()
		slime_inst.init_slime(i, pos, false)
		entities_node.add_child(slime_inst)
		client_slimes.append(slime_inst)

# Nhận snapshot từ Server
func _on_snapshot_received(_tick: int, player_state: Dictionary, mobs_state: Array) -> void:
	if is_instance_valid(client_player_entity):
		client_player_entity.apply_server_snapshot(player_state)
		
		# Cập nhật thanh máu & KI trên HUD
		var hp = player_state.get("hp", latest_stats.get("hp_current", 100))
		var hp_m = player_state.get("hp_max", latest_stats.get("hp_max", 100))
		var ki = player_state.get("ki", latest_stats.get("ki_current", 100))
		var ki_m = player_state.get("ki_max", latest_stats.get("ki_max", 100))
		hud.update_status(hp, hp_m, ki, ki_m, latest_tl, latest_tn)

		# Đồng bộ trạng thái Tử vong & Bia mộ
		var is_dead = player_state.get("is_dead", false)
		if is_dead:
			var death_pos_arr = player_state.get("death_pos", [160, 580])
			var death_pos = Vector2(death_pos_arr[0], death_pos_arr[1])
			if current_gravestone == null and is_instance_valid(client_map_instance):
				current_gravestone = gravestone_scene.instantiate()
				current_gravestone.global_position = death_pos
				client_map_instance.get_node("Entities").add_child(current_gravestone)
			if not death_panel.visible:
				death_panel.open_panel()
				char_stats_panel.visible = false
		else:
			if current_gravestone != null:
				current_gravestone.queue_free()
				current_gravestone = null
			if death_panel.visible:
				death_panel.close_panel()

	for m_data in mobs_state:
		var m_id = m_data.get("id", -1)
		if m_id >= 0 and m_id < client_slimes.size():
			client_slimes[m_id].apply_server_snapshot(m_data)

func _on_respawn_result(success: bool, reason: String, _player_state: Dictionary) -> void:
	if success:
		_log("Máy chủ đã xác nhận hồi sinh M1 về điểm an toàn.")
		if current_gravestone != null:
			current_gravestone.queue_free()
			current_gravestone = null
		if death_panel.visible:
			death_panel.close_panel()
	else:
		_log("Hồi sinh thất bại: " + reason)

# Nhận kết quả sát thương & popup điểm
func _on_combat_result(_event_id: String, mob_id: int, actual_hp_lost: int) -> void:
	if mob_id >= 0 and mob_id < client_slimes.size():
		client_slimes[mob_id].trigger_hurt_effect(actual_hp_lost)
	
	hud.trigger_attack_cd(GameConfig.SKILL_1_COOLDOWN)
	
	if is_instance_valid(client_map_instance) and is_instance_valid(client_player_entity):
		var entities_node = client_map_instance.get_node("Entities")
		hud.spawn_point_popup(entities_node, client_player_entity.global_position, actual_hp_lost, actual_hp_lost)

# Nhận tiến trình điểm và chỉ số từ Server
func _on_progression_received(tinh_luc: int, tinh_nang: int, stats: Dictionary, _upgrade_counts: Dictionary) -> void:
	latest_tl = tinh_luc
	latest_tn = tinh_nang
	latest_stats = stats
	hud.update_status(
		stats.get("hp_current", 100),
		stats.get("hp_max", 100),
		stats.get("ki_current", 100),
		stats.get("ki_max", 100),
		tinh_luc,
		tinh_nang
	)

func _update_status(text: String, color: Color = Color.WHITE) -> void:
	if status_label:
		status_label.text = text
		status_label.modulate = color

func _log(msg: String) -> void:
	print(msg)
	if log_box:
		log_box.append_text(msg + "\n")
