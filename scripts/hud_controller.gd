extends CanvasLayer

# HUDController: Điều khiển giao diện HUD gợi nhớ phong cách NRO
# HP/KI, Tinh Lực/Tinh Năng, Avatar M1, thanh 8 ô kỹ năng (Phím 1 active, 2-8 khóa)

signal open_character_menu_requested

@onready var hp_bar: ProgressBar = $PlayerStatusBox/BarsContainer/HPBar
@onready var hp_label: Label = $PlayerStatusBox/BarsContainer/HPBar/HPLabel
@onready var ki_bar: ProgressBar = $PlayerStatusBox/BarsContainer/KIBar
@onready var ki_label: Label = $PlayerStatusBox/BarsContainer/KIBar/KILabel
@onready var points_label: Label = $PlayerStatusBox/BarsContainer/PointsLabel

@onready var btn_menu_k: Button = $TopRightBox/BtnMenuK
@onready var slot1_cd: Panel = $BottomSkillBar/Slot1/CDOverlay

var cd_timer: float = 0.0

func _ready() -> void:
	btn_menu_k.pressed.connect(func(): open_character_menu_requested.emit())
	slot1_cd.visible = false

func _process(delta: float) -> void:
	if cd_timer > 0.0:
		cd_timer -= delta
		slot1_cd.visible = (cd_timer > 0.0)

func update_status(hp: int, hp_max: int, ki: int, ki_max: int, tl: int, tn: int) -> void:
	hp_bar.max_value = hp_max
	hp_bar.value = hp
	hp_label.text = "HP: %d / %d" % [hp, hp_max]

	ki_bar.max_value = ki_max
	ki_bar.value = ki
	ki_label.text = "KI: %d / %d" % [ki, ki_max]

	points_label.text = "TL: %d  |  TN: %d" % [tl, tn]

func trigger_attack_cd(cd_duration: float = 0.7) -> void:
	cd_timer = cd_duration
	slot1_cd.visible = true

func spawn_point_popup(parent_node: Node2D, pos: Vector2, tl_gain: int, tn_gain: int) -> void:
	if not is_instance_valid(parent_node):
		return
	var label = Label.new()
	label.text = "+%d TL  +%d TN" % [tl_gain, tn_gain]
	label.modulate = Color(1.0, 0.9, 0.2, 1.0)
	label.add_theme_font_size_override("font_size", 14)
	label.position = pos + Vector2(-30, -50)
	parent_node.add_child(label)
	
	var tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30.0, 0.7)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7)
	tween.tween_callback(label.queue_free)
