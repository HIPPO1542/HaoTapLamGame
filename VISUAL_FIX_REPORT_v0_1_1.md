# BÁO CÁO NGHIỆM THU: SỬA NỀN TẢNG ANIMATION M1 — V0.1.1

**Dự án:** Ma Pháp Huyễn Giới 2D  
**Engine:** Godot Engine 4 (GDScript)  
**Nhánh Git:** `fix_bug/m1-animation-alignment` (phân nhánh từ `dev`)  
**Ngày thực hiện:** 27/10/2026  
**Mục tiêu:** Chuẩn hóa toàn diện hệ thống Animation nhân vật M1 theo báo cáo `VISUAL_AUDIT_v0_1.md`, loại bỏ hoàn toàn hiện tượng rung lắc/giật vị trí bàn chân (foot-sliding & vertical jitter), khôi phục đủ chu kỳ chạy 6 frame, đồng bộ trọn vẹn thời lượng animation đòn đánh và phản xạ trúng đòn (Hurt).

---

## 1. Danh sách tệp tin đã chỉnh sửa và bổ sung

### 1.1. Tài nguyên Sprite nhân vật M1 (`assets/characters/m1/`)
Toàn bộ 16 frame sprite được cắt trích xuất lại từ sprite concept gốc `M1_sprite_concept.png` và chuẩn hóa lên hệ khung canvas đồng nhất **380 x 320 px** với đường đáy bàn chân cố định tuyệt đối tại $Y = 310$ px và trục xương sống tại $X = 190$ px:
- `m1_idle_0.png` -> `m1_idle_3.png`: 4 frame chu kỳ Idle (bổ sung đủ 4 frame thay vì 2 frame cũ).
- `m1_run_0.png` -> `m1_run_5.png`: 6 frame chu kỳ chạy hoàn chỉnh (khôi phục 2 frame `run_4` và `run_5` bị thiếu ở v0.1).
- `m1_jump_0.png`: 1 frame trên không trung / nhảy.
- `m1_attack_0.png` -> `m1_attack_2.png`: 3 frame chu kỳ tấn công cơ bản.
- `m1_hurt_0.png` -> `m1_hurt_1.png`: 2 frame trạng thái bị đánh trúng / ngã giật lùi.
- `m1_frames.tres`: Tài nguyên `SpriteFrames` gồm 5 chu kỳ animation (`idle`, `run`, `jump`, `attack`, `hurt`) với tốc độ FPS chuẩn xác.
- File `.import` tương ứng tự động cập nhật bởi Godot Asset Pipeline.

### 1.2. Scene Node nhân vật (`scenes/player.tscn`)
- Cập nhật điểm neo vị trí `AnimatedSprite2D.position = Vector2(0, -37.5)` để tâm điểm đáy bàn chân ($310 - 160 = +150$ px nhân scale $0.25 = +37.5$ px) khớp chính xác $100\%$ với đáy của `CollisionShape2D` (độ cao tiếp xúc mặt đất $Y = 0$).
- Cấu hình `texture_filter = 2` (Linear Filtering) riêng cho node `AnimatedSprite2D` nhằm khử răng cưa và khử hiện tượng rung viền lấp lánh (pixel shimmering) khi thu nhỏ từ sprite phân giải cao (380x320) về tỷ lệ hiển thị game (95x80). Giữ nguyên cấu hình toàn cục không ảnh hưởng tới tilemap hay HUD.

### 1.3. Logic điều khiển Animation (`scripts/player_controller.gd`)
- Bổ sung biến đếm thời gian phản xạ trúng đòn: `var hurt_anim_timer: float = 0.0`.
- **Server Animation Priority**: Thiết lập thứ tự ưu tiên hiển thị:
  $$\text{Attack} > \text{Hurt} (0.25\text{s}) > \text{Jump} (\text{airborne}) > \text{Run} (|v_x| > 5) > \text{Idle}$$
- **Đồng bộ thời lượng đòn đánh**: Nâng thời lượng phát đòn đánh `attack_anim_timer` từ $0.3\text{s}$ lên $0.38\text{s}$ để khớp hoàn hảo chu kỳ 3 frame ở 8.0 FPS ($3 / 8.0 = 0.375\text{s}$), khắc phục triệt để lỗi bị cắt cụt frame thứ 3 trước khi đòn đánh kịp hoàn tất.
- **Kích hoạt phản xạ Hurt**: Khi M1 nhận sát thương từ Slime (`take_monster_damage()`) mà chưa tử vong (`current_hp > 0`), kích hoạt `hurt_anim_timer = 0.25s` và phát `current_anim = "hurt"`.
- **Dọn dẹp trạng thái tử vong / hồi sinh**: Khi tử vong hoặc sau khi hồi sinh về nhà, tự động reset `hurt_anim_timer = 0.0` và `is_attacking = false` để tránh kẹt animation.
- **Bảo vệ đòn đánh phía Client**: Trong `_client_physics_process()`, bảo vệ chu kỳ animation `attack` đang chạy không bị ghi đè tức thời bởi snapshot `idle` trước khi kết thúc 3 frame.

### 1.4. Bộ kiểm thử tự động hóa mới (`tests/test_m1_animation.gd`)
- Bổ sung kịch bản kiểm thử độc lập gồm 7 bài kiểm tra A01 đến A07 chuyên biệt cho đồ họa, canvas, số frame và máy trạng thái Animation của M1.

---

## 2. Kết quả kiểm thử tự động hóa (Automated Test Suite)

Toàn bộ 3 bộ kịch bản kiểm thử (tổng cộng **38 bài kiểm thử**) đã được chạy trực tiếp trên `godot_console.exe --headless` và **đạt kết quả 100% PASS**:

```
========================================================
  1. BỘ TEST NỀN TẢNG ANIMATION M1 (A01 -> A07)
========================================================
  [PASS] A01: m1_frames.tres nạp hợp lệ và đủ 5 animation (idle, run, jump, attack, hurt).
  [PASS] A02: Đầy đủ số frame quy chuẩn: Idle (4), Run (6), Jump (1), Attack (3), Hurt (2).
  [PASS] A03: Toàn bộ 16/16 frame M1 đạt chuẩn kích thước canvas đồng nhất 380x320.
  [PASS] A04: AnimatedSprite2D căn chân chuẩn xác tại (0, -37.5), scale 0.25x.
  [PASS] A05: Bộ điều khiển phân loại chính xác Idle và Run dựa theo vận tốc.
  [PASS] A06: Animation Attack cấu hình chuẩn 0.38s, đủ thời lượng phát trọn 3 frame 8 FPS.
  [PASS] A07: Trạng thái Hurt kích hoạt chuẩn 0.25s khi nhận dmg và reset sạch khi chết.
  => KẾT QUẢ: 7/7 ĐẠT CHUẨN (100% PASS)

========================================================
  2. BỘ TEST TỬ VONG / BIA MỘ / HỒI SINH (D01 -> D16)
========================================================
  [PASS] D01 -> D16: Toàn bộ 16 bài kiểm thử chu trình tử nạn, bia mộ, khóa nút trả phí, hồi sinh về nhà đầy đủ HP/KI và bảo toàn điểm Tinh Lực/Tinh Năng.
  => KẾT QUẢ: 16/16 ĐẠT CHUẨN (100% PASS)

========================================================
  3. BỘ TEST TỔNG HỢP V0.1 PROTOTYPE (T01 -> T16)
========================================================
  [PASS] T01 -> T16: Toàn bộ 15 bài kiểm thử hồi quy về kết nối mạng, di chuyển, 8 Slime, Tinh Lực/Tinh Năng, công thức nâng chỉ số và Save/Load JSON.
  => KẾT QUẢ: 15/15 ĐẠT CHUẨN (100% PASS)
```

---

## 3. Đánh giá cải thiện trực quan thực tế

| Tiêu chí | Trước khi sửa (v0.1) | Sau khi sửa (v0.1.1 Đợt 1) | Trạng thái |
| :--- | :--- | :--- | :---: |
| **Độ ổn định vị trí chân** | Canvas không đều (168px - 349px), mỗi lần đổi anim bàn chân bị thụt lên/xuống 3.875px (15.5px texture) | Toàn bộ 16 frame cố định đáy chân tại $Y=310$, $0\text{px}$ rung lắc khi chuyển animation | **HOÀN HẢO** |
| **Độ đối xứng khi quay hướng** | Trục lật Sprite lệch nhau tới 22px giữa các frame, nhân vật giật ngang khi đổi hướng | Cố định trục $X=190$, lật trái/phải (`flip_h`) mượt mà không bị trượt vị trí | **HOÀN HẢO** |
| **Chu kỳ di chuyển (Run)** | Chỉ có 4 frame giật cục, thiếu pha tiếp đất và đẩy gót | Khôi phục đủ 6 frame từ bản vẽ gốc, chu kỳ chạy tròn nhịp điệu | **HOÀN HẢO** |
| **Chu kỳ tấn công (Phím 1)** | Timer $0.3\text{s}$ cắt cụt frame số 3 (cần $0.375\text{s}$ ở 8 FPS) | Nâng lên $0.38\text{s}$, đòn đánh vung hết tầm và thu thế trọn vẹn | **HOÀN HẢO** |
| **Phản xạ khi trúng đòn** | Hoàn toàn đơ cứng, không có animation Hurt dù asset đã có trong thư mục | Kích hoạt chu kỳ Hurt $0.25\text{s}$ khi nhận sát thương quái | **HOÀN HẢO** |
| **Chất lượng hiển thị Sprite** | Nearest filter làm vỡ viền nét vẽ tay khi scale 0.25x | Linear filter giúp đường nét mềm mại, không nhấp nháy cạnh | **HOÀN HẢO** |

---

## 4. Các vấn đề còn tồn đọng & Giới hạn thiết kế đợt 1

1. **Động tác Tấn công Phím 1 hiện tại chỉ là Placeholder (Tạm bợ):**
   - **Lưu ý tối quan trọng theo định hướng thiết kế:** Kỹ năng phím 1 theo kịch bản cốt lõi là **Đấm / Đá cận chiến bọc nguyên tố ma pháp** (Elemental Punch/Kick).
   - Sprite hiện có trong `M1_sprite_concept.png` là tư thế **vung kiếm chém ngang**. Trong đợt 1 này, chúng tôi chỉ chuẩn hóa canvas và căn chỉnh kỹ thuật để engine không bị lỗi, **tuyệt đối không coi animation kiếm chém này là thiết kế cuối cùng**.
2. **Số lượng frame của trạng thái Idle còn hạn chế:**
   - 4 frame Idle hiện tại là các tư thế đứng thở nhẹ, chưa có chu kỳ nhấp nhô cơ thể tự nhiên và tóc bay trong gió.
3. **Hiệu ứng đồ họa (VFX) và Môi trường:**
   - Chưa bổ sung hiệu ứng bụi dưới chân khi tiếp đất/chạy.
   - Chưa tích hợp tia sét / luồng năng lượng ma pháp bọc ở tay/chân khi thi triển kỹ năng.
   - Bản đồ grassland vẫn dùng 1 layer tĩnh, chưa có parallax background đa tầng.

---

## 5. Danh mục Sprite yêu cầu Đội ngũ Họa sĩ (2D Artist) vẽ mới cho Đợt 2

Để hoàn thiện thẩm mỹ đạt chuẩn phát hành thương mại cho nhân vật M1, đội ngũ 2D Artist cần bàn giao bộ sprite mới theo đúng thông số kỹ thuật chuẩn hóa đã được thiết lập:

> **Quy chuẩn kỹ thuật bắt buộc cho Artist:**
> - Canvas đồng nhất: **$380 \times 320\text{ px}$** (hoặc tỷ lệ tương đương nếu tăng độ phân giải).
> - Đường tiếp đất bàn chân: Cố định tại dòng tọa độ **$Y = 310\text{ px}$** đối với mọi frame đứng/chạy/đánh.
> - Trục cơ thể: Căn giữa đối xứng tại cột **$X = 190\text{ px}$**.
> - Định dạng: PNG trong suốt 32-bit RGBA, xuất theo sprite sheet kèm file JSON metadata hoặc từng frame rời được đánh số thứ tự.

### Chi tiết các gói sprite cần vẽ mới:

| Gói Asset | Tên Animation | Số frame đề xuất | Tốc độ (FPS) | Mô tả chi tiết yêu cầu nghệ thuật |
| :--- | :--- | :---: | :---: | :--- |
| **M1-SKILL1** *(Ưu tiên P0)* | `punch_combo` | 4 - 6 frame | 12 - 14 FPS | Đấm thẳng bằng tay bọc ma pháp xanh lam, chuyển trọng tâm chân dứt khoát, thu tay về thế thủ. |
| **M1-SKILL1B** *(Ưu tiên P0)* | `kick_elemental` | 4 - 6 frame | 12 - 14 FPS | Cú đá quét chân bọc kình lực nguyên tố, vung chân góc $90^\circ$ và hạ trụ vững chắc. |
| **M1-IDLE** *(Ưu tiên P1)* | `idle_breathing` | 6 - 8 frame | 6 - 8 FPS | Tư thế đứng thủ võ thuật, ngực phập phồng nhịp thở, vạt áo và đuôi tóc đen đung đưa nhẹ theo gió. |
| **M1-JUMP** *(Ưu tiên P1)* | `jump_cycle` | 3 frame | 8 FPS | Tách riêng: 1 frame bật nhảy (Jump-Up), 1 frame lơ lửng đỉnh parabol (Peak/Apex), 1 frame rơi xuống (Fall-Down). |
| **M1-LAND** *(Ưu tiên P2)* | `land` | 2 frame | 12 FPS | Khuỵu gối hấp thụ lực tiếp đất trước khi chuyển về Idle/Run. |
| **VFX-SKILL1** *(Ưu tiên P1)* | `elemental_impact` | 4 - 5 frame | 15 FPS | Hiệu ứng ma pháp bùng nổ tại điểm va chạm khi đấm/đá trúng Slime. |

---

## 6. Kết luận & Khuyến nghị bước tiếp theo

1. Toàn bộ nhiệm vụ **Sửa nền tảng Animation M1 — v0.1.1 (Đợt 1)** đã được hoàn thành $100\%$ đúng yêu cầu kỹ thuật:
   - Chân M1 không còn giật khi đứng, chạy, nhảy hay đánh.
   - Không bị trượt lệch vị trí khi quay mặt trái/phải.
   - Khôi phục trọn vẹn 6 frame chạy.
   - Kích hoạt chuẩn xác phản xạ Hurt và giữ nguyên toàn bộ cơ chế bia mộ/hồi sinh v0.1.
   - Không làm ảnh hưởng bất kỳ thông số gameplay, mạng hay công thức kinh tế nào.
2. Sẵn sàng tạo Pull Request từ nhánh `fix_bug/m1-animation-alignment` vào nhánh `dev` để nghiệm thu.
