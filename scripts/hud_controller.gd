extends CanvasLayer

# HUDController: Điều khiển giao diện HUD fantasy phong cách retro/chibi
# HP/KI tiến độ, Tinh Lực/Tinh Năng phân tách rõ, Avatar M1 cận mặt, 8 ô kỹ năng

signal open_character_menu_requested

@onready var hp_bar: ProgressBar = $PlayerStatusBox/BarsContainer/HPBar
@onready var hp_label: Label = $PlayerStatusBox/BarsContainer/HPBar/HPLabel
@onready var ki_bar: ProgressBar = $PlayerStatusBox/BarsContainer/KIBar
@onready var ki_label: Label = $PlayerStatusBox/BarsContainer/KIBar/KILabel

@onready var label_tl: Label = $PlayerStatusBox/BarsContainer/PointsContainer/LabelTL
@onready var label_tn: Label = $PlayerStatusBox/BarsContainer/PointsContainer/LabelTN
@onready var points_label: Label = $PlayerStatusBox/BarsContainer/PointsLabel

@onready var btn_menu_k: Button = $TopRightBox/BtnMenuK

@onready var slot1_panel: Panel = $BottomSkillBar/Slot1
@onready var slot1_icon: TextureRect = $BottomSkillBar/Slot1/Icon
@onready var slot1_cd: Panel = $BottomSkillBar/Slot1/CDOverlay
@onready var slot1_cd_label: Label = $BottomSkillBar/Slot1/CDOverlay/CDLabel

var cd_timer: float = 0.0
var current_ki_val: int = 100

func _ready() -> void:
	btn_menu_k.pressed.connect(func(): open_character_menu_requested.emit())
	if slot1_cd:
		slot1_cd.visible = false

func _process(delta: float) -> void:
	if cd_timer > 0.0:
		cd_timer -= delta
		if cd_timer <= 0.0:
			cd_timer = 0.0
			slot1_cd.visible = false
		else:
			slot1_cd.visible = true
			if slot1_cd_label:
				slot1_cd_label.text = "%.1f" % cd_timer
	
	# Feedback trực quan khi cạn KI (< 1)
	if slot1_icon:
		if current_ki_val < 1:
			slot1_icon.modulate = Color(0.6, 0.6, 0.6, 0.6)
		else:
			slot1_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)

# Định dạng số ngăn cách hàng nghìn (VD: 1,250)
func format_number(val: int) -> String:
	var s = str(absi(val))
	var res = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	if val < 0:
		res = "-" + res
	return res

func update_status(hp: int, hp_max: int, ki: int, ki_max: int, tl: int, tn: int) -> void:
	current_ki_val = ki
	if not is_inside_tree() or hp_bar == null:
		return
	
	hp_bar.max_value = hp_max
	hp_bar.value = hp
	hp_label.text = "HP: %s / %s" % [format_number(hp), format_number(hp_max)]

	ki_bar.max_value = ki_max
	ki_bar.value = ki
	ki_label.text = "KI: %s / %s" % [format_number(ki), format_number(ki_max)]

	if label_tl:
		label_tl.text = "⚡ Tinh Lực: %s" % format_number(tl)
	if label_tn:
		label_tn.text = "✦ Tinh Năng: %s" % format_number(tn)
	if points_label:
		points_label.text = "TL: %s  |  TN: %s" % [format_number(tl), format_number(tn)]

func trigger_attack_cd(cd_duration: float = 0.7) -> void:
	cd_timer = cd_duration
	if slot1_cd:
		slot1_cd.visible = true
		if slot1_cd_label:
			slot1_cd_label.text = "%.1f" % cd_timer

func spawn_point_popup(parent_node: Node2D, pos: Vector2, tl_gain: int, tn_gain: int) -> void:
	if not is_instance_valid(parent_node):
		return
	var label = Label.new()
	label.text = "+%s TL  +%s TN" % [format_number(tl_gain), format_number(tn_gain)]
	label.modulate = Color(1.0, 0.9, 0.2, 1.0)
	label.add_theme_font_size_override("font_size", 14)
	label.position = pos + Vector2(-30, -50)
	parent_node.add_child(label)
	
	var tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30.0, 0.7)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7)
	tween.tween_callback(label.queue_free)
