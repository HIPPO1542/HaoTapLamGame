extends CanvasLayer
class_name DeathRespawnPanel

# DeathRespawnPanel: Giao diện khi người chơi M1 tử vong (DEAD_WAITING_CHOICE)
# Tuân thủ chặt chẽ đặc tả Prototype v0.1 & v0.1.2A:
# - Nút 1: "Về nhà — Miễn phí" (Hoạt động, hồi sinh tại spawn đầu map)
# - Nút 2: "Hồi sinh tại chỗ — Chưa mở" (Khóa vĩnh viễn, Cần hệ thống Vàng)

signal respawn_home_requested(request_id: String)

@onready var btn_home: Button = $CenterContainer/PanelContainer/VBoxContainer/BtnRespawnHome
@onready var btn_here: Button = $CenterContainer/PanelContainer/VBoxContainer/BtnRespawnHere
@onready var status_lbl: Label = $CenterContainer/PanelContainer/VBoxContainer/StatusLabel

var is_requesting: bool = false

func _ready() -> void:
	visible = false
	if btn_here:
		btn_here.disabled = true
	if btn_home:
		btn_home.pressed.connect(_on_btn_home_pressed)

func open_panel() -> void:
	visible = true
	is_requesting = false
	if btn_home:
		btn_home.disabled = false
	if btn_here:
		btn_here.disabled = true
	if status_lbl:
		status_lbl.text = "Trở về điểm an toàn ở đầu map, phục hồi đầy đủ HP & KI."

func close_panel() -> void:
	visible = false
	is_requesting = false
	if btn_home:
		btn_home.disabled = false

func _on_btn_home_pressed() -> void:
	if is_requesting:
		return
	is_requesting = true
	if btn_home:
		btn_home.disabled = true
	if status_lbl:
		status_lbl.text = "Đang gửi yêu cầu hồi sinh tới máy chủ..."
	
	var req_id = "respawn_%d_%d" % [multiplayer.get_unique_id(), Time.get_ticks_msec()]
	respawn_home_requested.emit(req_id)
	
	var nb = get_node_or_null("/root/NetworkBridge")
	if nb and nb.has_method("request_respawn_home"):
		nb.request_respawn_home.rpc_id(1, req_id)

func _input(event: InputEvent) -> void:
	# Khi bảng tử vong đang mở: Chặn hoàn toàn phím Esc và K, không cho đóng bảng
	if visible:
		if event.is_action_pressed("toggle_character_menu") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
