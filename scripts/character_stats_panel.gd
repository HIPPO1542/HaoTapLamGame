extends Control

# CharacterStatsPanel: Bảng Menu -> Nhân vật (phím K)
# Nâng 4 chỉ số trực tiếp bằng Tinh Năng, không cần NPC Đạo Sư

@onready var btn_close: Button = $Panel/VBox/Header/BtnClose

@onready var label_tl: Label = $Panel/VBox/ResourceBox/ResGrid/LabelTLValue
@onready var label_tn: Label = $Panel/VBox/ResourceBox/ResGrid/LabelTNValue

@onready var label_hp_name: Label = $Panel/VBox/StatsContainer/HPSection/HBox/VBox/StatName
@onready var label_hp_cost: Label = $Panel/VBox/StatsContainer/HPSection/HBox/VBox/StatCost
@onready var btn_up_hp: Button = $Panel/VBox/StatsContainer/HPSection/HBox/BtnUpHP

@onready var label_ki_name: Label = $Panel/VBox/StatsContainer/KISection/HBox/VBox/StatName
@onready var label_ki_cost: Label = $Panel/VBox/StatsContainer/KISection/HBox/VBox/StatCost
@onready var btn_up_ki: Button = $Panel/VBox/StatsContainer/KISection/HBox/BtnUpKI

@onready var label_atk_name: Label = $Panel/VBox/StatsContainer/AtkSection/HBox/VBox/StatName
@onready var label_atk_cost: Label = $Panel/VBox/StatsContainer/AtkSection/HBox/VBox/StatCost
@onready var btn_up_atk: Button = $Panel/VBox/StatsContainer/AtkSection/HBox/BtnUpAtk

@onready var label_arm_name: Label = $Panel/VBox/StatsContainer/ArmSection/HBox/VBox/StatName
@onready var label_arm_cost: Label = $Panel/VBox/StatsContainer/ArmSection/HBox/VBox/StatCost
@onready var btn_up_arm: Button = $Panel/VBox/StatsContainer/ArmSection/HBox/BtnUpArm

@onready var status_msg: Label = $Panel/VBox/StatusMsg

var current_tl: int = 0
var current_tn: int = 0
var current_stats: Dictionary = {
	"hp_current": 100,
	"hp_max": 100,
	"ki_current": 100,
	"ki_max": 100,
	"attack": 10,
	"armor": 0
}
var current_counts: Dictionary = {
	"hp": 0,
	"ki": 0,
	"attack": 0,
	"armor": 0
}

func _ready() -> void:
	btn_close.pressed.connect(_close_panel)
	btn_up_hp.pressed.connect(func(): _request_upgrade("hp"))
	btn_up_ki.pressed.connect(func(): _request_upgrade("ki"))
	btn_up_atk.pressed.connect(func(): _request_upgrade("attack"))
	btn_up_arm.pressed.connect(func(): _request_upgrade("armor"))

	NetworkBridge.progression_received.connect(_on_progression_received)
	NetworkBridge.upgrade_result_received.connect(_on_upgrade_result)
	
	_update_ui()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("toggle_character_menu") or event.is_action_pressed("ui_cancel"):
		_close_panel()
		get_viewport().set_input_as_handled()

func _close_panel() -> void:
	visible = false

func toggle_panel() -> void:
	# Chặn mở bảng Menu K khi người chơi đang ở trạng thái DEAD
	var main_node = get_parent()
	if main_node and main_node.has_node("DeathRespawnPanel"):
		var dp = main_node.get_node("DeathRespawnPanel")
		if dp and dp.visible:
			visible = false
			return

	visible = not visible
	if visible:
		_update_ui()

func _request_upgrade(stat_id: String) -> void:
	var main_node = get_parent()
	if main_node and main_node.has_node("DeathRespawnPanel"):
		var dp = main_node.get_node("DeathRespawnPanel")
		if dp and dp.visible:
			status_msg.text = "Không thể nâng điểm khi đã tử vong!"
			status_msg.modulate = Color(1.0, 0.4, 0.4, 1.0)
			return

	var req_id = "upg_%s_%d_%d" % [stat_id, multiplayer.get_unique_id(), Time.get_ticks_msec()]
	status_msg.text = "Đang gửi yêu cầu nâng %s lên Server..." % stat_id.to_upper()
	status_msg.modulate = Color.YELLOW
	NetworkBridge.request_upgrade.rpc_id(1, stat_id, req_id)

func _on_progression_received(tinh_luc: int, tinh_nang: int, stats: Dictionary, upgrade_counts: Dictionary) -> void:
	current_tl = tinh_luc
	current_tn = tinh_nang
	current_stats = stats
	current_counts = upgrade_counts
	_update_ui()

func _on_upgrade_result(_req_id: String, success: bool, reason: String, _state: Dictionary) -> void:
	status_msg.text = reason
	status_msg.modulate = Color.GREEN if success else Color(1.0, 0.4, 0.4, 1.0)

func _update_ui() -> void:
	if not is_inside_tree():
		return
	label_tl.text = str(current_tl)
	label_tn.text = str(current_tn)

	# 1. HP
	var hp_max = current_stats.get("hp_max", 100)
	var hp_count = current_counts.get("hp", 0)
	var hp_cost = GameConfig.get_upgrade_cost("hp", hp_count)
	label_hp_name.text = "Máu tối đa (HP): %d  (+20)" % hp_max
	label_hp_cost.text = "Giá: %d Tinh Năng  (Lần %d)" % [hp_cost, hp_count + 1]
	btn_up_hp.disabled = (current_tn < hp_cost)

	# 2. KI
	var ki_max = current_stats.get("ki_max", 100)
	var ki_count = current_counts.get("ki", 0)
	var ki_cost = GameConfig.get_upgrade_cost("ki", ki_count)
	label_ki_name.text = "Năng lượng (KI): %d  (+20)" % ki_max
	label_ki_cost.text = "Giá: %d Tinh Năng  (Lần %d)" % [ki_cost, ki_count + 1]
	btn_up_ki.disabled = (current_tn < ki_cost)

	# 3. Công Lực
	var atk = current_stats.get("attack", 10)
	var atk_count = current_counts.get("attack", 0)
	var atk_cost = GameConfig.get_upgrade_cost("attack", atk_count)
	label_atk_name.text = "Công Lực: %d  (+1)" % atk
	label_atk_cost.text = "Giá: %d Tinh Năng  (Lần %d)" % [atk_cost, atk_count + 1]
	btn_up_atk.disabled = (current_tn < atk_cost)

	# 4. Giáp
	var arm = current_stats.get("armor", 0)
	var arm_count = current_counts.get("armor", 0)
	var arm_cost = GameConfig.get_upgrade_cost("armor", arm_count)
	label_arm_name.text = "Giáp: %d  (+1)" % arm
	label_arm_cost.text = "Giá: %d Tinh Năng  (Lần %d)" % [arm_cost, arm_count + 1]
	btn_up_arm.disabled = (current_tn < arm_cost)
