extends Node2D
class_name Gravestone

# Gravestone: Biểu tượng bia mộ pixel-art hiển thị tại vị trí M1 tử vong
# Đặt chân bia mộ trên mặt đất, không có CollisionShape2D làm chặn map

func _ready() -> void:
	z_index = 5
	queue_redraw()

func _draw() -> void:
	# Bệ đá chân bia mộ đặt sát mặt đất (y = 0)
	draw_rect(Rect2(-16, -6, 32, 6), Color(0.18, 0.18, 0.22, 1.0))
	draw_rect(Rect2(-15, -5, 30, 4), Color(0.32, 0.33, 0.38, 1.0))
	
	# Thân bia mộ hình vòm cổ kính
	draw_rect(Rect2(-12, -34, 24, 28), Color(0.20, 0.20, 0.25, 1.0))
	draw_rect(Rect2(-10, -32, 20, 26), Color(0.46, 0.48, 0.54, 1.0))
	draw_rect(Rect2(-10, -32, 4, 26), Color(0.58, 0.60, 0.68, 1.0))
	
	# Đỉnh vòm cong bia mộ
	draw_circle(Vector2(0, -32), 10.0, Color(0.46, 0.48, 0.54, 1.0))
	draw_arc(Vector2(0, -32), 10.0, PI, 2 * PI, 16, Color(0.20, 0.20, 0.25, 1.0), 2.0)
	
	# Khắc chạm họa tiết chữ thập trên đá
	draw_rect(Rect2(-2, -30, 4, 16), Color(0.18, 0.18, 0.22, 1.0))
	draw_rect(Rect2(-6, -26, 12, 4), Color(0.18, 0.18, 0.22, 1.0))
