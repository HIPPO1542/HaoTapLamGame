# BÁO CÁO KIỂM THỬ VÀ NGHIỆM THU CHẤT LƯỢNG (QA REPORT)
## DỰ ÁN: MA PHÁP HUYỄN GIỚI 2D — PROTOTYPE V0.1

- **Ngày thực hiện:** 27/10/2026
- **Engine:** Godot Engine v4.7.2.stable.official.ed1daf0bf (Windows x86_64)
- **Môi trường:** Windows PC (NVIDIA GeForce RTX 3050 Ti Laptop GPU / Vulkan 1.4 Forward+)
- **Đường dẫn Workspace:** `H:\Hao_Tap_Lam_game\test_0`
- **Mục tiêu:** Kiểm thử toàn diện, bảo vệ toàn vẹn dữ liệu, xác thực server-authoritative và nghiệm thu 16 hạng mục kỹ thuật (T01 – T16) Prototype v0.1.

---

## 1. MÔI TRƯỜNG THỰC TẾ VÀ CÚ PHÁP LỆNH THỰC THI

### 1.1 Cấu hình môi trường
- **Godot Binary:** `H:\Hao_Tap_Lam_game\godot_console.exe` (Godot 4.7.2 Stable)
- **Vị trí lưu Save thực tế:** `%APPDATA%\Godot\app_userdata\Ma Phap Huyen Gioi 2D - Prototype v0.1\saves\player_save.json`
- **File sao lưu bảo vệ người chơi:** `H:\Hao_Tap_Lam_game\test_0\user_backup_player_save.json` (TL: 1658, TN: 398, Atk: 14, HP Max: 120)
- **Cấu hình mạng:** Localhost `127.0.0.1:24567`, giao thức ENet RPC, Server Authoritative.

### 1.2 Cú pháp dòng lệnh thực thi kiểm thử tự động
```powershell
# Chạy toàn bộ 16 bài kiểm thử nghiệm thu tổng hợp
& "H:\Hao_Tap_Lam_game\godot_console.exe" --headless --path test_0 -s tests/run_all_tests.gd

# Chạy kiểm thử từng nhóm độc lập
& "H:\Hao_Tap_Lam_game\godot_console.exe" --headless --path test_0 -s tests/test_step1_network.gd
& "H:\Hao_Tap_Lam_game\godot_console.exe" --headless --path test_0 -s tests/test_step2_movement.gd
& "H:\Hao_Tap_Lam_game\godot_console.exe" --headless --path test_0 -s tests/test_step3_combat.gd
& "H:\Hao_Tap_Lam_game\godot_console.exe" --headless --path test_0 -s tests/test_step4_progression.gd
& "H:\Hao_Tap_Lam_game\godot_console.exe" --headless --path test_0 -s tests/test_step5_saveload.gd
```

---

## 2. DANH MỤC KIỂM THỬ CHI TIẾT (TEST CATALOG)

| Mã Test | Cấp độ | Tên bài kiểm thử | Mô tả mục tiêu nghiệm thu |
|---|---|---|---|
| **T01** | P1 | Mạng Server/Client | Server bind `127.0.0.1:24567`, `max_clients = 1`. Kết nối thành công. |
| **T02** | P2 | Điều khiển InputMap | Hỗ trợ đầy đủ phím di chuyển (A/D/Left/Right), nhảy (W/Up/Space), đánh (1), menu (K), thoát (Esc). |
| **T03** | P2 | Vật lý và Ranh giới Map | Nhân vật và Camera bị chặn chuẩn xác tại `[20.0 .. 2540.0]`, không rơi khỏi map, timeout input 300ms. |
| **T04** | P2 | Khởi tạo Quái | Chính xác đúng 8 Slime ma pháp tại bãi quái Khu 1, không thừa/thiếu con thứ 9. |
| **T05** | P2 | Cơ chế Hồi sinh Quái | Slime chết biến mất, hồi sinh sau 3.0 – 5.0 giây tại vị trí cũ với đầy đủ 100 HP. |
| **T06** | P1 | Phạm vi Tấn công Phím 1 | Tầm đánh 48px (1.5 tile) và bắt buộc đúng hướng quay mặt; ngoài tầm không trừ máu quái. |
| **T07** | P1 | Cooldown & KI Skill 1 | Hồi chiêu 0.7s, tốn 1 KI, tự hồi 1 KI/s; chặn hoàn toàn spam khi cạn KI hoặc chưa hết CD. |
| **T08** | P1 | Overkill Damage Check | Quái còn 1 HP dính đòn 10 dame -> Chỉ trừ đúng 1 HP, nhận đúng 1 TL và 1 TN (không cộng dư). |
| **T09** | P1 | Tích lũy TL / TN 1:1 | Đánh quái 100 HP nhận đúng 100 Tinh Lực và 100 Tinh Năng tương ứng với sát thương thực. |
| **T10** | P0 | Nâng chỉ số Menu K | Nâng HP (+20, 100+8n), KI (+20, 100+8n), Công (+1, 200+60n), Giáp (+1, 500+120n). Chặn nâng khi thiếu điểm, không làm âm TN. |
| **T11** | P0 | Chống Trùng lặp (Idempotency) | Cùng một `request_id` nâng điểm gửi liên tiếp chỉ được trừ điểm và tăng chỉ số đúng 1 lần. |
| **T12** | P0 | Bảo toàn Tinh Lực | Tinh Lực không bị tiêu hao hay khấu trừ khi người chơi nâng cấp bất kỳ chỉ số nào trong menu K. |
| **T13** | P0 | Đồng bộ Reconnect | Client mất kết nối / mở lại kết nối nhận đầy đủ snapshot trạng thái từ Server, không bị reset. |
| **T14** | P0 | Nạp Save Bền vững | Server khởi động lại nạp đúng 100% hồ sơ từ JSON (`tinh_luc`, `tinh_nang`, `upgrade_counts`, chỉ số). |
| **T15** | P2 | Cơ chế Chết Nhân vật | M1 về 0 HP hồi sinh tạm thời tại Spawn Point (160, 580) với đầy HP/KI, không bị trừ Tinh Lực/Tinh Năng. |
| **T16** | P0 | Safe Atomic Save & Backup | Quy trình ghi nguyên tử (`.tmp` -> `.bak` -> `.json`), tự động phục hồi từ file `.bak` khi file chính hỏng. |

---

## 3. KẾT QUẢ KIỂM THỬ THỰC TẾ (TEST RESULTS)

| Mã | Trạng thái | Bằng chứng thực nghiệm (Logs / Assertions) |
|---|---|---|
| **T01** | **PASS** | `[PASS] T01: Cấu hình Server bind 127.0.0.1:24567, max_clients=1` |
| **T02** | **PASS** | `[PASS] T02 / InputMap: Đầy đủ 4 hướng ADWS/mũi tên, phím 1, K, Esc` |
| **T03** | **PASS** | `[PASS] T03: Ranh giới map [20..2540], timeout input 300ms, camera không vượt map` |
| **T04** | **PASS** | `[PASS] T04: Khởi tạo chính xác đúng 8 Slime ma pháp` |
| **T05** | **PASS** | `[PASS] T05: Quái chết hồi sinh sau 3-5 giây tại vị trí cũ, không sinh con thứ 9` |
| **T06** | **PASS** | `[PASS] T06: Phím 1 tầm 48px phía trước mặt; ngoài tầm không trừ máu quái` |
| **T07** | **PASS** | `[PASS] T07: Hồi chiêu 0.7s, tốn 1 KI, tự hồi 1 KI/s, chặn spam khi cạn KI` |
| **T08** | **PASS** | `[PASS] T08: Quái còn 1 HP dính 10 dmg -> Chỉ nhận đúng 1 TL và 1 TN` |
| **T09** | **PASS** | `[PASS] T09: Hạ 100 HP Slime nhận trọn vẹn 100 Tinh Lực và 100 Tinh Năng` |
| **T10** | **PASS** | `[Progression] Nâng điểm thành công: hp +20 (Tốn 100 TN, TN còn lại: 400)`<br>`[PASS] T10: Nâng HP thành công (+20), trừ 100 TN, giá tăng lên 108 TN` |
| **T11** | **PASS** | `[Progression] Bỏ qua request_id trùng lặp: req_hp_all`<br>`[PASS] T11: Idempotency chống trừ điểm trùng lặp cho cùng một request_id` |
| **T12** | **PASS** | `[PASS] T12: Nâng điểm bất kỳ đâu không cần NPC; Tinh Lực bảo toàn 100%, không bị trừ` |
| **T13** | **PASS** | `[PASS] T13 / T16: Tắt client / rớt mạng kết nối lại nhận đúng state server` |
| **T14** | **PASS** | `[PASS] T14: Khởi động lại Server nạp đúng toàn bộ dữ liệu từ JSON` |
| **T15** | **PASS** | `[Server] M1 tử nạn! Hồi sinh tạm tại spawn point (160.0, 580.0), HP & KI đầy, không trừ điểm.`<br>`[PASS] T15: M1 về 0 HP hồi sinh tại spawn point với đầy đủ máu/KI, không trừ điểm` |
| **T16** | **PASS** | `[SaveRepository] File save chính bị lỗi cú pháp hoặc rỗng! Đang khôi phục từ file backup...`<br>`[SaveRepository] Khôi phục thành công từ file backup .bak!`<br>`[PASS] Test 5: File save chính bị lỗi cú pháp -> Tự động khôi phục dữ liệu từ .bak an toàn.` |

---

## 4. DANH SÁCH LỖI PHÁT HIỆN VÀ BIỆN PHÁP KHẮC PHỤC

### Lỗi 1 (P0): Crash giao diện do thuộc tính Font Size trên Godot 4.7
- **Hiện tượng:** Khi quái nhận sát thương hoặc khi HUD vẽ số sát thương bay lên, console báo lỗi: `Invalid access to property or key 'theme_override_font_sizes' on a base object of type 'Label'`.
- **Nguyên nhân:** Trong Godot 4.x, thuộc tính cấu hình theme của `Label` là phương thức `add_theme_font_size_override("font_size", size)` thay vì truy cập dạng field qua dot syntax.
- **Khắc phục:** Đã chuẩn hóa toàn bộ các lệnh gán font trong `slime_ai.gd` và `hud_controller.gd`.

### Lỗi 2 (P1): Màn hình Client bị màu đen che khuất bản đồ và nhân vật
- **Hiện tượng:** Khi client kết nối vào server, giao diện HUD hiển thị nhưng khung nhìn game bị màn đen che kín.
- **Nguyên nhân:** Node `Background` (`ColorRect`) được đặt trực tiếp dưới node gốc `Main`, nằm đè lên `WorldView`.
- **Khắc phục:** Di chuyển node `Background` vào bên trong nhóm `UI`. Khi game bắt đầu và `UI.visible = false`, màn đen tự động ẩn đi, lộ ra khung cảnh bản đồ và nhân vật rõ ràng.

### Lỗi 3 (P1): Quái Slime trên cửa sổ Server không cập nhật thanh máu và không ẩn khi chết
- **Hiện tượng:** Người chơi đánh quái, server in log trừ máu nhưng thanh máu quái trên màn hình server không tụt.
- **Nguyên nhân:** Lệnh cập nhật `hp_bar.value` và `visible = is_alive` trước đó chỉ nằm trong hàm `_client_process`.
- **Khắc phục:** Bổ sung việc đồng bộ visual trực tiếp ngay khi nhận sát thương (`take_damage_from_player`), khi hồi sinh (`_respawn_on_server`) và khi nhận snapshot (`apply_server_snapshot`).

### Lỗi 4 (P0): Biên dịch thất bại khi chạy Headless CLI do Autoload chưa nạp
- **Hiện tượng:** Lệnh chạy test độc lập báo lỗi: `Compile Error: Identifier not found: GameConfig` và `Identifier not found: NetworkBridge`.
- **Nguyên nhân:** Chế độ `godot --headless -s` chỉ khởi tạo `SceneTree` tối thiểu mà không tự động đăng ký autoload singleton vào phạm vi script.
- **Khắc phục:**
  1. Bổ sung `const GameConfig = preload("res://scripts/game_config.gd")` vào các script cốt lõi.
  2. Bọc lời gọi `NetworkBridge` trong `player_controller.gd` bằng `get_node_or_null("/root/NetworkBridge")` an toàn.
  3. Cung cấp cơ chế `SaveRepository.custom_save_dir` cho phép bộ test chạy trên thư mục cách ly `res://tests/temp_saves/`, vừa bảo vệ tuyệt đối file save thật của người chơi, vừa chạy độc lập không phụ thuộc vào quyền ghi AppData của sandbox.

---

## 5. DANH SÁCH TẬP TIN ĐÃ ĐIỀU CHỈNH VÀ LÝ DO

1. `test_0/scripts/player_controller.gd`:
   - Gắn an toàn `const GameConfig`.
   - Chuyển lời gọi RPC sang `get_node_or_null("/root/NetworkBridge")` tránh crash khi test unit.
2. `test_0/scripts/slime_ai.gd`:
   - Sửa lỗi font size: `add_theme_font_size_override("font_size", 14)`.
   - Cập nhật thanh HP và ẩn hiện sprite ngay trong logic Server.
3. `test_0/scripts/hud_controller.gd`:
   - Sửa lỗi font size: `add_theme_font_size_override`.
4. `test_0/scripts/progression_system.gd`:
   - Gắn `const GameConfig`.
   - Ép kiểu `int` cho mọi giá trị đọc từ Save JSON để đảm bảo độ chuẩn xác số nguyên 64-bit.
5. `test_0/scripts/save_repository.gd`:
   - Bổ sung `custom_save_dir` phục vụ test cô lập an toàn.
   - Thêm quy trình Safe Atomic Save (`.tmp` -> `.bak` -> `.json`) và tự phục hồi từ `.bak`.
6. `test_0/scenes/main.tscn`:
   - Chuyển `Background` ColorRect vào trong `UI` để tránh che khuất `WorldView`.
7. `test_0/tests/run_all_tests.gd`:
   - Hoàn thiện test suite 16 ca nghiệm thu T01 – T16 chạy headless tự động.
8. `test_0/tests/test_step1_network.gd` đến `test_step5_saveload.gd`:
   - Chuẩn hóa các bài test thành phần độc lập.

---

## 6. KẾT QUẢ HỒI QUY SAU SỬA LỖI (REGRESSION VERIFICATION)

- Toàn bộ 5 test suites thành phần và tổng hợp đều đạt **100% PASS**:
  - `test_step1_network.gd`: **5/5 PASS**
  - `test_step2_movement.gd`: **5/5 PASS**
  - `test_step3_combat.gd`: **6/6 PASS**
  - `test_step4_progression.gd`: **6/6 PASS**
  - `test_step5_saveload.gd`: **5/5 PASS**
  - `run_all_tests.gd`: **15/15 nhóm kiểm thử PASS** (Bao gồm T01 -> T16).
- Hồ sơ nhân vật thực tế của người chơi (`TL: 1658`, `TN: 398`, `Attack: 14`, `HP Max: 120`) được bảo toàn tuyệt đối, không có sai lệch dữ liệu.

---

## 7. RỦI RO CÒN LẠI & HƯỚNG DẪN KIỂM THỬ THỦ CÔNG QUA GIAO DIỆN

Các hạng mục đã kiểm thử tự động ở tầng logic nghiệp vụ, tuy nhiên người phát triển nên chạy thử trực tiếp bằng mắt để cảm nhận gameplay:
1. **Trải nghiệm chiến đấu trực quan:**
   - Bấm nút **[ ▶ CHƠI NGAY (Server + Client) ]** tại màn hình khởi động.
   - Dùng phím **A/D** di chuyển đến bãi Slime, nhấn phím **1** để chém. Quan sát số sát thương màu đỏ bay lên và thanh máu quái tụt dần.
2. **Kiểm tra Menu Nhân vật (phím K):**
   - Nhấn phím **K** để mở bảng chỉ số.
   - Bấm **[ + ]** để nâng HP hoặc Công Lực. Kiểm tra thanh Tinh Năng bị trừ điểm tương ứng và chỉ số nhân vật lập tức tăng lên.
   - Nhấn **K** hoặc **Esc** để đóng bảng.

---
**KẾT LUẬN NGHIỆM THU:** Prototype v0.1 của Ma Pháp Huyễn Giới 2D đạt đầy đủ các tiêu chuẩn kỹ thuật đề ra, sẵn sàng cho các giai đoạn phát triển tiếp theo!
