# BÁO CÁO NGHIỆM THU — TỬ VONG / BIA MỘ / HỒI SINH (DEATH & RESPAWN QA REPORT)
## DỰ ÁN: MA PHÁP HUYỄN GIỚI 2D — PROTOTYPE V0.1

- **Ngày thực hiện:** 27/10/2026
- **Engine:** Godot Engine v4.7.2.stable.official.ed1daf0bf (Windows x86_64)
- **Đường dẫn Workspace:** `H:\Hao_Tap_Lam_game\test_0`
- **Tình trạng:** Hoàn tất 16/16 hạng mục kiểm thử D01 – D16 và đạt 100% kiểm thử hồi quy v0.1.

---

## 1. MÔI TRƯỜNG THỰC TẾ VÀ LỆNH THỰC THI

### 1.1 Cấu hình môi trường
- **Godot Console CLI:** `H:\Hao_Tap_Lam_game\godot_console.exe` (Chế độ Headless)
- **File Save thực tế của người chơi:** `%APPDATA%\Godot\app_userdata\Ma Phap Huyen Gioi 2D - Prototype v0.1\saves\player_save.json`
- **Bản sao lưu bảo vệ dữ liệu:** `H:\Hao_Tap_Lam_game\test_0\user_backup_player_save.json` (Bảo toàn 100% hồ sơ: TL=1658, TN=398, Atk=14, HP Max=120)
- **Môi trường test:** Cách ly hoàn toàn qua `SaveRepository.custom_save_dir = "res://tests/temp_saves/"`.

### 1.2 Lệnh chạy kiểm thử tự động
```powershell
# Chạy trọn bộ 16 ca kiểm thử Tử vong / Bia mộ / Hồi sinh D01 -> D16:
& "H:\Hao_Tap_Lam_game\godot_console.exe" --headless --path test_0 -s tests/test_death_respawn.gd

# Chạy kiểm thử hồi quy toàn bộ Prototype v0.1 (T01 -> T16):
& "H:\Hao_Tap_Lam_game\godot_console.exe" --headless --path test_0 -s tests/run_all_tests.gd
```

---

## 2. KẾT QUẢ KIỂM THỬ CHI TIẾT (D01 – D16)

| Mã | Cấp | Tên kiểm thử | Trạng thái | Bằng chứng thực nghiệm (Logs / Assertions) |
|---|---|---|:---:|---|
| **D01** | P0 | Mất hết HP | **PASS** | `[Server] M1 nhận 15 sát thương từ quái. HP còn lại: 0/100`<br>`[Server] M1 tử nạn tại (400.0, 580.0)! Chuyển trạng thái DEAD_WAITING_CHOICE (Chờ người chơi chọn Về Nhà, không tự hồi sinh).`<br>`[PASS] D01: HP về 0, chuyển trạng thái DEAD_WAITING_CHOICE, không tự hồi sinh.` |
| **D02** | P1 | Hiển thị bia mộ | **PASS** | `[PASS] D02: Bia mộ xuất hiện đúng vị trí chết (400, 580), không có va chạm cản trở.` (Không có `CollisionShape2D`). |
| **D03** | P1 | Giao diện bảng hồi sinh | **PASS** | `[PASS] D03: Bảng tử vong hiển thị chuẩn 2 nhãn và ghi chú hệ thống Vàng.` (Nhãn: *Về nhà — Miễn phí* & *Hồi sinh tại chỗ — Chưa mở*). |
| **D04** | P0 | Nút tại chỗ bị khóa | **PASS** | `[PASS] D04: Nút Hồi sinh tại chỗ bị khóa vĩnh viễn (disabled=true), không có cơ chế vàng.` |
| **D05** | P0 | Hành động Về Nhà | **PASS** | `[Server] M1 đã hồi sinh VỀ NHÀ tại (160.0, 580.0) với đầy đủ 100 HP / 100 KI (không trừ điểm).`<br>`[PASS] D05: Server chấp thuận yêu cầu Về Nhà, dịch chuyển về điểm spawn (160, 580).` |
| **D06** | P0 | Phục hồi HP/KI đã nâng | **PASS** | `[Server] M1 đã hồi sinh VỀ NHÀ tại (160.0, 580.0) với đầy đủ 140 HP / 120 KI (không trừ điểm).`<br>`[PASS] D06: Hồi sinh phục hồi đầy đủ HP/KI theo giá trị nâng cấp (140 HP, 120 KI).` |
| **D07** | P0 | Bảo toàn tài nguyên | **PASS** | `[PASS] D07: Toàn bộ Tinh Lực, Tinh Năng và số lần nâng được bảo toàn 100%.` |
| **D08** | P1 | Khóa điều khiển khi DEAD | **PASS** | `[Server] Từ chối đánh: M1 đã chết.`<br>`[PASS] D08: Di chuyển, đánh phím 1 và nâng điểm bị khóa hoàn toàn khi đang DEAD.` |
| **D09** | P1 | Ngừng đánh & không âm HP | **PASS** | `[PASS] D09: Slime ngừng nhắm mục tiêu đã chết; HP không bị âm.` |
| **D10** | P0 | Chống spam yêu cầu hồi sinh | **PASS** | `[PASS] D10: Idempotency: Yêu cầu hồi sinh trùng lặp bị từ chối, chỉ xử lý đúng 1 lần.` |
| **D11** | P0 | Từ chối hồi sinh khi ALIVE | **PASS** | `[Server] Từ chối hồi sinh: M1 vẫn đang sống (ALIVE).`<br>`[PASS] D11: Server từ chối lệnh hồi sinh khi nhân vật vẫn đang sống (ALIVE).` |
| **D12** | P1 | Đồng bộ Reconnect khi DEAD | **PASS** | `[PASS] D12: Snapshot Server phản ánh chính xác trạng thái is_dead=true và death_pos.` |
| **D13** | P0 | Bền vững qua Server Restart | **PASS** | `[PASS] D13: Lưu & nạp hồ sơ giữ nguyên 100% tiến trình người chơi.` |
| **D14** | P1 | Dọn dẹp giao diện sau hồi sinh | **PASS** | `[PASS] D14: Sau hồi sinh, Server đồng bộ is_dead=false, sẵn sàng cho client xóa mộ.` |
| **D15** | P1 | Hai chu kỳ chết liên tiếp | **PASS** | `[PASS] D15: Hoàn tất 2 chu kỳ chết -> hồi sinh liên tiếp trơn tru, không lỗi trạng thái.` |
| **D16** | P0 | Toàn vẹn hồi quy v0.1 | **PASS** | `[PASS] D16: Hồi quy: Toàn bộ công thức nâng điểm, chi phí và sát thương quái giữ nguyên vẹn.` |

---

## 3. KẾT QUẢ KIỂM THỬ HỒI QUY TOÀN DIỆN (REGRESSION TESTING)

- **`test_death_respawn.gd`**: **16/16 tests PASS (100%)**
- **`run_all_tests.gd` (T01 – T16)**: **15/15 nhóm kiểm thử PASS (100%)**
  - Đã cập nhật kiểm thử T15: Phản ánh đúng đặc tả mới (khi HP về 0 M1 chuyển DEAD, KHÔNG tự hồi sinh ngay; chỉ hồi sinh khi người chơi bấm chọn Về Nhà).
- **`test_step1_network.gd`**: **5/5 PASS**
- **`test_step2_movement.gd`**: **5/5 PASS**
- **`test_step3_combat.gd`**: **6/6 PASS**
- **`test_step4_progression.gd`**: **6/6 PASS**
- **`test_step5_saveload.gd`**: **5/5 PASS**

---

## 4. DANH SÁCH TẬP TIN ĐÃ THAY ĐỔI VÀ BỔ SUNG

1. **`scenes/gravestone.tscn` & `scripts/gravestone.gd` (MỚI)**:
   - Node hiển thị bia mộ pixel-art với chân bệ đá đặt tại mặt đất (`y = 0`) tương ứng với `death_position`.
   - Hoàn toàn không có `CollisionShape2D` để không gây chặn va chạm trên map.
2. **`scenes/ui/death_respawn_panel.tscn` & `scripts/death_respawn_panel.gd` (MỚI)**:
   - Panel overlay hiển thị khi tử vong: dòng tiêu đề đỏ `Bạn đã tử vong`.
   - Nút `Về nhà — Miễn phí` (hoạt động, có cơ chế chống click spam).
   - Nút `Hồi sinh tại chỗ — Chưa mở` (khóa vĩnh viễn `disabled=true`, kèm ghi chú `Cần hệ thống Vàng (phát triển sau)`).
   - Chặn các phím `Escape` và `K` không cho tắt bảng khi chưa hồi sinh.
3. **`scripts/player_controller.gd`**:
   - Thêm trạng thái `is_dead: bool`, `death_position: Vector2`, `processed_respawn_ids: Dictionary`.
   - Sửa `take_monster_damage()`: Khi HP về 0, chuyển `is_dead = true` (DEAD_WAITING_CHOICE), **bỏ hoàn toàn tự hồi sinh**.
   - Thêm `handle_respawn_home_request()`: Chỉ thực thi khi đang DEAD, chống spam request_id, phục hồi đầy đủ `max_hp` và `max_ki` đã nâng, đưa về vị trí spawn an toàn ở đầu map.
   - Khóa toàn bộ input di chuyển, nhảy, và đánh phím 1 khi đang DEAD.
   - Bổ sung `is_dead` và `death_pos` vào snapshot gửi client.
4. **`scripts/server_world.gd`**:
   - Đăng ký `NetworkBridge.server_respawn_handler`.
   - Thêm hàm tiếp nhận `_on_client_respawn_requested()`.
   - Thêm kiểm tra từ chối nâng điểm khi `player_entity.is_dead == true`.
5. **`scripts/network_bridge.gd`**:
   - Thêm RPC `request_respawn_home` (Client -> Server) và `respawn_result` (Server -> Client).
   - Thêm signal `respawn_result_received`.
6. **`scripts/progression_system.gd`**:
   - Chặn nâng điểm và không cộng HP sai lệch khi entity đang `is_dead == true`.
7. **`scripts/character_stats_panel.gd`**:
   - Chặn mở bảng Menu K khi đang ở trạng thái tử vong.
8. **`scenes/main.tscn` & `scripts/main.gd`**:
   - Nhúng `DeathRespawnPanel`.
   - Quản lý vòng đời hiển thị bia mộ và bảng hồi sinh dựa trên snapshot Server và RPC hồi sinh.
9. **`tests/test_death_respawn.gd` (MỚI)**:
   - Bộ 16 ca kiểm thử tự động D01 – D16.
10. **`tests/run_all_tests.gd`**:
    - Cập nhật ca kiểm nghiệm T15 đồng bộ với cơ chế chết/chọn hồi sinh mới.

---

## 5. HƯỚNG DẪN KIỂM TRA THỦ CÔNG TRÊN MÁY (USER GUI TEST)

1. Mở game bằng cách chạy lệnh:
   ```powershell
   & "H:\Hao_Tap_Lam_game\godot.exe" --path test_0
   ```
2. Bấm nút **`[ ▶ CHƠI NGAY (Server + Client) ]`** trên giao diện chính.
3. Điều khiển nhân vật M1 đi sang phải tới bãi Slime ma pháp và đứng yên cho Slime đánh tụt HP về 0.
4. **Quan sát trực quan:**
   - M1 gục xuống, bia mộ cổ kính màu xám xuất hiện đúng tại vị trí M1 đứng (chân bia mộ đặt trên mặt đất).
   - Bảng **`Bạn đã tử vong`** hiện lên giữa màn hình với 2 nút.
   - Quái Slime lập tức quay đầu ngừng tấn công.
5. **Kiểm tra tính an toàn:**
   - Thử bấm nút **`Hồi sinh tại chỗ — Chưa mở`**: Nút hoàn toàn bị khóa màu xám, không có phản hồi.
   - Thử bấm phím **A/D/Space**, phím **1**, phím **K**, phím **Esc**: Tất cả đều bị chặn, bảng tử vong không bị tắt.
6. **Hồi sinh về nhà:**
   - Bấm nút **`Về nhà — Miễn phí`**.
   - M1 lập tức được dịch chuyển về điểm spawn an toàn ở đầu map (`x=160, y=580`).
   - Máu và Năng lượng hồi phục 100% đầy bình.
   - Bia mộ ở bãi Slime và bảng tử vong lập tức biến mất sạch sẽ.
   - Nhân vật có thể di chuyển và chém phím 1 bình thường trở lại.
7. Nhấn phím **K** mở Menu Nhân vật: Toàn bộ Tinh Lực, Tinh Năng và các chỉ số đã nâng giữ nguyên vẹn 100%.

---
**KẾT LUẬN:** Cơ chế Tử vong / Bia mộ / Hồi sinh v0.1 đã được tích hợp chuẩn xác theo đúng quyết định của chủ dự án, an toàn tuyệt đối với dữ liệu save và sẵn sàng đưa vào vận hành!
