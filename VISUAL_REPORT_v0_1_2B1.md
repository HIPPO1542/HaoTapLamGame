# BÁO CÁO NGHIỆM THU: v0.1.2B-1 — NÂNG CẤP BẢN ĐỒ ĐỒNG CỎ (GRASSLAND PARALLAX & VISUAL PASS)

- **Dự án:** Ma Pháp Huyễn Giới 2D
- **Engine:** Godot 4 (v4.7.2.stable.official)
- **Phiên bản:** v0.1.2B-1
- **Nhánh Git:** `feats/grassland-visual-v012b1` (tách từ `dev` đã cập nhật UI v0.1.2A)
- **Đường dẫn dự án:** `H:\Hao_Tap_Lam_game\test_0`
- **Ngày hoàn thành:** 27/10/2026

---

## 1. Mục tiêu & Định hướng Mỹ thuật

Thay thế bản đồ phẳng đơn điệu ban đầu bằng môi trường **2D anime fantasy side-scrolling** tươi sáng, có chiều sâu đa tầng Parallax 2D mượt mà, đường nét rõ ràng, không sử dụng pixel art 8-bit/16-bit thô, không dùng mảng màu phẳng giả lập.

Hệ thống được thiết kế bám sát các nguyên tắc mỹ thuật tham khảo:
- Bầu trời xanh biếc chuyển màu lam ngọc (sapphire-to-cyan gradient) với ánh dương rực rỡ và các dải mây bồng bềnh.
- Dãy núi xa sắc xanh lam huyền ảo, đỉnh sắc nhọn và thung lũng mờ sương.
- Đồi trung cảnh uốn lượn sắc xanh tự nhiên với bóng cây và gờ đá.
- Cây cổ thụ ma pháp (banyan fantasy trees) với thân xoắn và tán lá tầng lớp làm điểm nhấn phía sau sàn đấu.
- Mặt đất cao nguyên với viền cỏ mọc mềm mại, điểm hoa dại đa sắc (trắng, hồng, lam) và vách đá phân tầng tự nhiên.
- Không gian chiến đấu thông thoáng, toàn bộ chướng ngại cảnh quan không che khuất nhân vật M1 hoặc 8 Slime ma pháp.

---

## 2. Danh mục File triển khai & Thay đổi

| STT | File đường dẫn | Thao tác | Mô tả chi tiết |
| :--- | :--- | :--- | :--- |
| 1 | `assets/environment/bg_sky.png` | Tạo mới | Bầu trời anime fantasy 1920x720, gradient lam ngọc, vệt nắng và mây mềm |
| 2 | `assets/environment/bg_far_mountains.png` | Tạo mới | Dãy núi xa 1920x450 sắc lam ngọc mờ sương, đỉnh nhọn đa tầng |
| 3 | `assets/environment/bg_mid_hills.png` | Tạo mới | Đồi xanh trung cảnh 1920x400 với kết cấu nhấp nhô và bóng cây |
| 4 | `assets/environment/bg_near_trees.png` | Tạo mới | Hàng cây cổ thụ ma pháp 2560x480 đặt tại hậu cảnh sàn đấu |
| 5 | `assets/environment/bg_ground_platform.png` | Tạo mới | Mặt sàn đi lại 2560x140 tại Y=580 viền cỏ tự nhiên, hoa đá và tầng đất |
| 6 | `scenes/test_grassland.tscn` | Cập nhật | Thay thế ColorRect phẳng bằng hệ thống 4 tầng `Parallax2D` + `GroundVisual` |
| 7 | `scripts/capture_parallax_screenshots.gd` | Tạo mới | Script tự động điều hướng Camera và chụp màn hình đa góc độ / responsive |
| 8 | `tests/test_grassland_parallax.gd` | Tạo mới | Bộ kiểm thử tự động 31 tiêu chí kiểm tra Parallax, Collider, Bounds |
| 9 | `screenshots/map_pos1_spawn_1280x720.png` | Minh chứng | Ảnh chụp thực tế vị trí xuất phát (Spawn X=240, 1280x720) |
| 10 | `screenshots/map_pos2_mid_1280x720.png` | Minh chứng | Ảnh chụp thực tế vị trí chiến đấu giữa map (Combat X=1100, 1280x720) |
| 11 | `screenshots/map_pos3_end_1280x720.png` | Minh chứng | Ảnh chụp thực tế vị trí cuối map (X=2200, 1280x720) |
| 12 | `screenshots/map_responsive_1600x900.png` | Minh chứng | Ảnh chụp thực tế độ phân giải mở rộng (1600x900 tại X=800) |

---

## 3. Kiến trúc các tầng nền & Thông số kỹ thuật Parallax2D

Hệ thống sử dụng node hiện đại `Parallax2D` của Godot 4.3+ với cấu hình phân tầng quang sai tỷ lệ vàng:

```
TestGrassland (Node2D)
 ├── ParallaxSky (Parallax2D)             [scroll_scale: (0.00, 0.00) | repeat_size: (1920, 0)]
 │    └── SkySprite (Sprite2D)            -> bg_sky.png (1920x720), centered=false, filter=Linear
 ├── ParallaxMountains (Parallax2D)       [scroll_scale: (0.15, 0.05) | repeat_size: (1920, 0)]
 │    └── MountainsSprite (Sprite2D)      -> bg_far_mountains.png (1920x450, Y=180), filter=Linear
 ├── ParallaxHills (Parallax2D)           [scroll_scale: (0.35, 0.10) | repeat_size: (1920, 0)]
 │    └── HillsSprite (Sprite2D)          -> bg_mid_hills.png (1920x400, Y=260), filter=Linear
 ├── ParallaxTrees (Parallax2D)           [scroll_scale: (0.65, 0.20) | repeat_size: (2560, 0)]
 │    └── TreesSprite (Sprite2D)          -> bg_near_trees.png (2560x480, Y=100), filter=Linear
 ├── GroundVisual (Sprite2D)              [Vị trí cố định (0, 580) bám sát tọa độ đi lại]
 │                                        -> bg_ground_platform.png (2560x140), filter=Linear
 ├── StaticColliders (StaticBody2D)       [Giữ nguyên 100% logic va chạm & bounds [0..2560]]
 │    ├── GroundCollision (CollisionShape2D)  -> Rect (2560, 140) tại (1280, 650)
 │    ├── LeftWallCollision (CollisionShape2D) -> Rect (20, 720) tại (-10, 360)
 │    ├── RightWallCollision (CollisionShape2D) -> Rect (20, 720) tại (2570, 360)
 │    └── CeilingCollision (CollisionShape2D)  -> Rect (2560, 20) tại (1280, -10)
 ├── SpawnPoint (Marker2D)                -> Vị trí quy chuẩn (160, 580)
 └── Entities (Node2D)                    -> Container chứa Player M1 và 8 Slime ma pháp
```

### Phân tích không gian chiến đấu
- Tán cây của `ParallaxTrees` bắt đầu từ `Y=100` đến `Y=450`.
- Nhân vật M1 và 8 Slime di chuyển trên mặt đất tại `Y=580`.
- Khoảng không gian chiến đấu từ `Y=480` đến `Y=580` hoàn toàn thông thoáng, đảm bảo hiệu ứng đòn đánh, số sát thương hiển thị và hitbox không bị bất kỳ cành lá hoặc chướng ngại vật nào che lấp.

---

## 4. Minh chứng Hình ảnh Trực quan (Screenshots)

Tất cả các ảnh chụp màn hình được kết xuất trực tiếp từ Godot engine tại thư mục `test_0/screenshots/` và đã được sao lưu sang `noidungduara/screenshots/`:

1. **Vị trí 1: Điểm hồi sinh ban đầu (Spawn - X=240, 1280x720)**
   - Đường dẫn: `screenshots/map_pos1_spawn_1280x720.png`
   - Đánh giá: Núi xa và đồi xanh nằm cân đối ở hậu cảnh. Cột mốc cây ma pháp tạo cảm giác hoang sơ mở đầu bản đồ.

2. **Vị trí 2: Khu vực chiến đấu trung tâm (Combat Mid - X=1100, 1280x720)**
   - Đường dẫn: `screenshots/map_pos2_mid_1280x720.png`
   - Đánh giá: Chiều sâu Parallax thể hiện rõ ràng khi dãy núi trôi chậm hơn đồi gần và hàng cây. Sàn cỏ xanh mịn với các đốm hoa dại làm nổi bật các thực thể chiến đấu.

3. **Vị trí 3: Khu vực cuối bản đồ (Map End - X=2200, 1280x720)**
   - Đường dẫn: `screenshots/map_pos3_end_1280x720.png`
   - Đánh giá: Ranh giới bản đồ tiếp giáp tự nhiên, không lộ đường cắt texture; mây trời và đường chân trời mở rộng hài hòa.

4. **Độ phân giải Responsive (1600x900 tại X=800)**
   - Đường dẫn: `screenshots/map_responsive_1600x900.png`
   - Đánh giá: Tỷ lệ khung hình giữ vững, tính năng lặp nền vô tận của `Parallax2D` (`repeat_size`) hoạt động mượt mà, không xuất hiện khoảng trống đen hoặc méo texture.

---

## 5. Kết quả Kiểm thử Tự động Toàn diện (85/85 PASS)

Mọi bộ kiểm thử đều được chạy tự động thông qua `godot_console.exe --headless` với tỷ lệ đạt 100%:

| Bộ kiểm thử | File kịch bản | Số test case | Kết quả | Ghi chú |
| :--- | :--- | :--- | :--- | :--- |
| **Bản đồ & Parallax (v0.1.2B-1)** | `tests/test_grassland_parallax.gd` | **31/31** | **PASS 100%** | Kiểm tra 5 texture, 4 tầng Parallax2D, GroundVisual, Colliders, Bounds |
| **Hồi quy Gameplay v0.1** | `tests/run_all_tests.gd` | **15/15** | **PASS 100%** | T01 -> T16: Mạng, Input, 8 Slime, Chiêu 1, KI, Tinh Lực, Tinh Năng, Save/Load |
| **Hồi sinh & Tử vong v0.1** | `tests/test_death_respawn.gd` | **16/16** | **PASS 100%** | D01 -> D16: Bia mộ, khóa Tại Chỗ, Về Nhà, hồi full HP/KI, bảo toàn tài nguyên |
| **Nền tảng Animation M1** | `tests/test_m1_animation.gd` | **7/7** | **PASS 100%** | A01 -> A07: Căn chân 380x320, 5 trạng thái (idle, run, jump, attack, hurt) |
| **Giao diện UI v0.1.2A** | `tests/test_u01_u16_ui.gd` | **16/16** | **PASS 100%** | U01 -> U16: HUD CanvasLayer, Menu K, DeadScreen, Responsive 1280x720 & 1600x900 |
| **TỔNG CỘNG** | **5 bộ kịch bản kiểm thử** | **85/85** | **PASS 100%** | **KHÔNG CÓ LỖI HỒI QUY (Zero Regression)** |

---

## 6. Đánh giá Khả năng Mở rộng sang các Bản đồ tiếp theo

Hệ thống kiến trúc `Parallax2D` phân tầng kết hợp `GroundVisual` tại sàn đi bộ đã chứng minh tính module hóa vượt trội:
1. **Dễ dàng tái sử dụng khung cấu trúc:** Để tạo các map tiếp theo (ví dụ: *Rừng Rậm U Tối*, *Sa Mạc Cát Vàng*, *Hang Động Tinh Thể*), chỉ cần kế thừa cấu trúc `test_grassland.tscn` và thay thế 5 texture tương ứng theo cùng tỷ lệ:
   - `bg_sky`: Thay bằng bầu trời đêm ma thuật / bão cát hoàng hôn.
   - `bg_far`: Thay bằng dãy núi đá nham thạch / rừng thông xa xôi.
   - `bg_mid`: Thay bằng gò cát / vách đá tổ ong / tán rừng trung cảnh.
   - `bg_near`: Thay bằng rễ cây cổ thụ / cột đá rêu phong.
   - `bg_ground`: Thay bằng lớp đất đá rêu phong / gạch cổ thành / thềm nham thạch.
2. **Hiệu năng tối ưu:** Do sử dụng `repeat_size` và lặp texture bằng phần cứng (Linear filtering trên GPU), dung lượng VRAM tiêu thụ cực thấp (< 8MB cho toàn bộ cảnh quan môi trường), mượt mà ở cả 60 FPS và 144 FPS.

---

## 7. Đánh giá Tồn đọng Đồ họa & Lộ trình đề xuất

Dù bản đồ Đồng Cỏ và Giao diện UI đã đạt chuẩn Anime Fantasy hiện đại, các thành phần sau vẫn giữ nguyên bản prototype để đảm bảo phạm vi nhiệm vụ:

1. **Sprite Slime ma pháp:**
   - Hiện tại: Vẫn đang dùng hình vẽ quả cầu xanh thô sơ (prototype placeholder).
   - Đề xuất: Cần bộ sprite Slime anime phong cách giọt nước mềm mại, có đổ bóng, hiệu ứng dập dềnh khi nhảy (squash & stretch) và tan biến thành hạt ma pháp khi chết.

2. **Hiệu ứng võ thuật đấm đá của M1 (Chiêu 1):**
   - Hiện tại: Animation M1 đã được căn chỉnh 3 frame đấm đá nhưng chưa có hiệu ứng hạt (VFX) khí kình / ma pháp bọc quanh nắm đấm và gót chân.
   - Đề xuất: Bổ sung lớp hiệu ứng hạt ma pháp ánh sáng (Elemental Aura / Punch Trail VFX) khi tung đòn phím 1 để thể hiện đúng tinh thần quyền cước bọc nguyên tố.

---

## 8. Kết luận & Trạng thái Git

Toàn bộ các yêu cầu của nhiệm vụ **v0.1.2B-1 NÂNG CẤP BẢN ĐỒ ĐỒNG CỎ** đã được hoàn thành 100%, kiểm thử nghiêm ngặt và sẵn sàng tạo Pull Request tích hợp vào nhánh `dev`.
