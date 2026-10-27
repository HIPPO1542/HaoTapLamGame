extends Node

# NetworkBridge: Cầu nối mạng sử dụng ENetMultiplayerPeer
# NodePath cố định /root/NetworkBridge cho cả Server và Client

signal server_started(port: int)
signal server_failed(port: int)
signal client_connected_to_server
signal client_connection_failed
signal client_server_disconnected
signal peer_connected_event(peer_id: int)
signal peer_disconnected_event(peer_id: int)

signal snapshot_received(tick_id: int, player_state: Dictionary, mobs_state: Array)
signal combat_result_received(event_id: String, mob_id: int, actual_hp_lost: int)
signal progression_received(tinh_luc: int, tinh_nang: int, stats: Dictionary, upgrade_counts: Dictionary)
signal upgrade_result_received(request_id: String, success: bool, reason: String, state: Dictionary)
signal respawn_result_received(success: bool, reason: String, player_state: Dictionary)

# Delegates cho server logic đăng ký nhận input
var server_input_handler: Callable
var server_attack_handler: Callable
var server_upgrade_handler: Callable
var server_respawn_handler: Callable

var peer: ENetMultiplayerPeer
var is_server_mode: bool = false
var is_client_mode: bool = false

func _ready() -> void:
	pass

# Khởi tạo Server Headless
func start_server(port: int = GameConfig.SERVER_PORT, max_clients: int = GameConfig.MAX_CLIENTS) -> bool:
	peer = ENetMultiplayerPeer.new()
	# Bind localhost 127.0.0.1
	var bind_ip: String = GameConfig.SERVER_IP
	peer.set_bind_ip(bind_ip)
	var err = peer.create_server(port, max_clients)
	if err != OK:
		print("[Server] Khong the mo server tai %s:%d, ma loi: %d" % [bind_ip, port, err])
		server_failed.emit(port)
		return false
	
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	is_server_mode = true
	is_client_mode = false
	print("[Server] Da khoi dong thanh cong tren %s:%d (Max clients: %d)" % [bind_ip, port, max_clients])
	server_started.emit(port)
	return true

# Khởi tạo Client
func start_client(ip: String = GameConfig.SERVER_IP, port: int = GameConfig.SERVER_PORT) -> bool:
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	if err != OK:
		print("[Client] Khong the tao client ket noi toi %s:%d, ma loi: %d" % [ip, port, err])
		client_connection_failed.emit()
		return false
	
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	is_server_mode = false
	is_client_mode = true
	print("[Client] Dang ket noi toi server %s:%d..." % [ip, port])
	return true

func stop_network() -> void:
	if peer:
		peer.close()
		multiplayer.multiplayer_peer = null
		peer = null
	is_server_mode = false
	is_client_mode = false

# Signal callbacks
func _on_peer_connected(id: int) -> void:
	print("[Server] Client da ket noi! Peer ID: %d" % id)
	peer_connected_event.emit(id)

func _on_peer_disconnected(id: int) -> void:
	print("[Server] Client da ngat ket noi! Peer ID: %d" % id)
	peer_disconnected_event.emit(id)

func _on_connected_to_server() -> void:
	var my_id: int = multiplayer.get_unique_id()
	print("[Client] Da ket noi toi server thanh cong! Peer ID cua toi: %d" % my_id)
	client_connected_to_server.emit()

func _on_connection_failed() -> void:
	print("[Client] Ket noi toi server that bai (Server chua mo hoac day)!")
	client_connection_failed.emit()

func _on_server_disconnected() -> void:
	print("[Client] Mat ket noi toi server!")
	client_server_disconnected.emit()

# ==========================================
# RPC GIAO TIẾP CLIENT -> SERVER
# ==========================================

@rpc("any_peer", "call_remote", "unreliable_ordered")
func submit_input(sequence: int, axis: float, jump: bool) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if server_input_handler.is_valid():
		server_input_handler.call(sender_id, sequence, axis, jump)

@rpc("any_peer", "call_remote", "reliable")
func request_basic_attack(request_id: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if server_attack_handler.is_valid():
		server_attack_handler.call(sender_id, request_id)

@rpc("any_peer", "call_remote", "reliable")
func request_upgrade(stat_id: String, request_id: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if server_upgrade_handler.is_valid():
		server_upgrade_handler.call(sender_id, stat_id, request_id)

@rpc("any_peer", "call_remote", "reliable")
func request_respawn_home(request_id: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if server_respawn_handler.is_valid():
		server_respawn_handler.call(sender_id, request_id)

# ==========================================
# RPC GIAO TIẾP SERVER -> CLIENT
# ==========================================

@rpc("authority", "call_remote", "unreliable_ordered")
func state_snapshot(tick_id: int, player_state: Dictionary, mobs_state: Array) -> void:
	if multiplayer.is_server():
		return
	snapshot_received.emit(tick_id, player_state, mobs_state)

@rpc("authority", "call_remote", "reliable")
func combat_result(event_id: String, mob_id: int, actual_hp_lost: int) -> void:
	if multiplayer.is_server():
		return
	combat_result_received.emit(event_id, mob_id, actual_hp_lost)

@rpc("authority", "call_remote", "reliable")
func progression_state(tinh_luc: int, tinh_nang: int, stats: Dictionary, upgrade_counts: Dictionary) -> void:
	if multiplayer.is_server():
		return
	progression_received.emit(tinh_luc, tinh_nang, stats, upgrade_counts)

@rpc("authority", "call_remote", "reliable")
func upgrade_result(request_id: String, success: bool, reason: String, state: Dictionary) -> void:
	if multiplayer.is_server():
		return
	upgrade_result_received.emit(request_id, success, reason, state)

@rpc("authority", "call_remote", "reliable")
func respawn_result(success: bool, reason: String, player_state: Dictionary) -> void:
	if multiplayer.is_server():
		return
	respawn_result_received.emit(success, reason, player_state)
