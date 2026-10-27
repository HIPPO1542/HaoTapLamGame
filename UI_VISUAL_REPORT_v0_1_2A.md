# BÁO CÁO NGHIỆM THU: VISUAL PASS UI v0.1.2A
**Ma Pháp Huyễn Giới 2D — Nâng Cấp Giao Diện HUD, Menu K & Bảng Hồi Sinh**

- **Dự án:** Ma Pháp Huyễn Giới 2D
- **Engine:** Godot Engine v4.7.2 (GDScript)
- **Nhánh Git:** `feats/ui-visual-pass-v012a` (phân nhánh từ `fix_bug/m1-animation-alignment`)
- **Ngày thực hiện:** 27/10/2026
- **Mục tiêu:** Hoàn thiện và nâng cấp toàn diện thẩm mỹ giao diện người dùng (HUD, Menu K, Bảng Tử Vong/Hồi Sinh) theo đúng đặc tả `UI_SPEC_v0_1_2A.md`, đảm bảo tính phân cấp thông tin rõ ràng, giao diện fantasy pixel/retro hài hòa, tương thích đa độ phân giải (1280×720 và 1600×900) mà **không làm thay đổi bất kỳ logic tính toán gameplay hay giao thức server authoritative** nào.

---

## 1. Danh sách tệp tin đã chỉnh sửa và bổ sung

### 1.1. Tài nguyên đồ họa UI mới (`assets/`):
- `assets/characters/m1/m1_avatar.png`: Ảnh chân dung cận mặt và ngực M1 độ phân giải $128 \times 128\text{ px}$, cắt chuẩn từ concept art gốc, thay thế cho ảnh toàn thân bị thu nhỏ biến dạng trước đây.
- `assets/ui/icon_punch.png`: Icon nắm đấm võ thuật bọc hào quang ma pháp ($32 \times 32\text{ px}$) dành riêng cho Kỹ năng 1 (Đấm cơ bản).
- `assets/ui/icon_lock.png`: Icon ổ khóa kim loại fantasy ($32 \times 32\text{ px}$) hiển thị đồng nhất cho các ô kỹ năng 2 đến 8, không phụ thuộc vào font emoji của hệ điều hành.

### 1.2. HUD lúc chơi (`scenes/ui/hud.tscn` & `scripts/hud_controller.gd`):
- Đặt trên `CanvasLayer` (layer 1) chống trôi theo camera, không cản trở di chuyển/đánh chuột (`mouse_filter = IGNORE`).
- **Khung Avatar M1**: Viền vàng hoàng gia bo góc kèm bóng đổ, hiển thị gương mặt góc cạnh tóc đen của M1.
- **Thanh sinh lực (HP) & Năng lượng (KI)**:
  - Thanh HP đỏ ruby và thanh KI xanh mana với viền đậm, hiển thị rõ số liệu hiện tại / tối đa (VD: `HP: 95 / 100`, `KI: 78 / 100`).
- **Phân định Tinh Lực (TL) & Tinh Năng (TN)**:
  - Tách bạch 2 dòng riêng biệt: `⚡ Tinh Lực: 1,250` (vàng kim) và `✦ Tinh Năng: 480` (xanh ngọc).
  - Tích hợp hàm định dạng ngăn cách hàng nghìn bằng dấu phẩy (`format_number()`).
- **Thanh 8 ô Kỹ năng (BottomSkillBar)**:
  - Căn giữa đáy màn hình (`Bottom-Center`), responsive linh hoạt.
  - **Slot 1**: Viền sáng vàng kim, phím tắt `1`, icon nắm đấm ma pháp, nhãn "Đấm Cơ Bản", lớp phủ hồi chiêu `CDOverlay` đếm ngược thời gian thực (0.7s) và tự động làm mờ khi thiếu KI (< 1 KI).
  - **Slot 2 – 8**: Viền xám tối, nhãn phím 2–8, hiển thị biểu tượng `icon_lock.png` khóa thống nhất.
- **Nút Menu K**: Nằm góc trên phải (`Top-Right`), nhãn `⚔ Nhân Vật [Phím K]`.

### 1.3. Bảng Nhân vật — Phím K (`scenes/ui/character_stats_panel.tscn` & `scripts/character_stats_panel.gd`):
- Chuyển thành `CanvasLayer` (layer 5) căn giữa màn hình, có lớp phủ nền mờ nhẹ (`Backdrop`) tôn vinh giao diện.
- Viền vàng fantasy cổ điển, nút đóng `✕` góc phải.
- **Khối tài nguyên (Resource Cards)**:
  - Card Tinh Lực (TL): Hiển thị số điểm tích lũy kèm chú thích "(Không bị tiêu hao khi nâng)".
  - Card Tinh Năng (TN): Hiển thị số điểm tiêu hao khả dụng.
- **4 Hàng chỉ số nâng cấp**:
  - Hàng Máu tối đa (HP): `Máu tối đa (HP): 100 (+20)` — `Giá: 100 Tinh Năng (Lần 1)`
  - Hàng Năng lượng (KI): `Năng lượng (KI): 100 (+20)` — `Giá: 100 Tinh Năng (Lần 1)`
  - Hàng Công Lực: `Công Lực: 10 (+1)` — `Giá: 200 Tinh Năng (Lần 1)`
  - Hàng Giáp: `Giáp: 0 (+1)` — `Giá: 500 Tinh Năng (Lần 1)`
- **Feedback trạng thái thông minh**: Khi thiếu Tinh Năng, nút `+` tự động chuyển sang màu xám mờ (`disabled = true`, nhãn `Thiếu TN`) và dòng giá tiền chuyển sang màu đỏ cảnh báo.
- Giữ nguyên cơ chế nâng điểm mọi nơi, mở/đóng bằng `K` hoặc `Esc`.

### 1.4. Màn hình Tử Vong & Hồi Sinh (`scenes/ui/death_respawn_panel.tscn` & `scripts/death_respawn_panel.gd`):
- Chuyển thành `CanvasLayer` (layer 10) nổi trên mọi thành phần giao diện, có lớp phủ nền đen mờ $70\%$ tạo không khí u buồn trang nghiêm khi tử trận.
- Tiêu đề đỏ rực: `Bạn đã tử vong`.
- **Nút 1 — Về nhà — Miễn phí**: Nút màu ngọc bích nổi bật, hồi sinh về spawn đầu map, đầy đủ $100\%$ HP/KI, giữ nguyên toàn bộ TL/TN.
- **Nút 2 — Hồi sinh tại chỗ — Chưa mở**: Bị khóa vĩnh viễn (`disabled = true`), đi kèm ghi chú bắt buộc: `Cần hệ thống Vàng (phát triển sau)`.
- Khóa toàn bộ phím tắt gameplay, `K` và `Esc` khi bảng đang mở.

### 1.5. Scene & Controller chính (`scenes/main.tscn` & `scripts/main.gd`):
- Cập nhật định kiểu `CanvasLayer` an toàn cho `char_stats_panel` và `death_panel`, loại bỏ nguy cơ crash và ngăn chặn hiện tượng trôi lệch UI khi Camera2D cuộn map.

---

## 2. Kết quả kiểm thử tiêu chuẩn U01 -> U16 (v0.1.2A)

Đã chạy toàn bộ bộ kiểm thử tự động hóa [test_u01_u16_ui.gd](file:///h:/Hao_Tap_Lam_game/test_0/tests/test_u01_u16_ui.gd) trên Godot Console Engine. Kết quả nghiệm thu: **16/16 ĐẠT CHUẨN (100% PASS)**:

| Mã test | Tiêu chí nghiệm thu | Kết quả thực tế | Trạng thái |
| :---: | :--- | :--- | :---: |
| **U01** | Cấu hình mạng Server/Client | Đúng IP 127.0.0.1, Port 24567, Max clients 1 | **PASS** |
| **U02** | HUD không che WorldView | CanvasLayer cố định, không trôi camera, không ColorRect che map | **PASS** |
| **U03** | Avatar chân dung M1 | Ảnh 128×128 cận mặt/ngực M1, không bị co nhét toàn thân | **PASS** |
| **U04** | Thanh sinh lực HP / Năng lượng KI | Hiển thị chính xác tiến độ và nhãn text theo snapshot server | **PASS** |
| **U05** | Tinh Lực / Tinh Năng | Định dạng ngăn cách hàng nghìn (12,500 TL \| 4,800 TN) rõ ràng | **PASS** |
| **U06** | Thanh kỹ năng 8 slot | Đủ 8 ô, slot 1 mở (icon punch), slot 2–8 khóa (icon lock vẽ riêng) | **PASS** |
| **U07** | Đóng/mở Menu K | Toggle mượt mà bằng phím K và Esc, không mất input | **PASS** |
| **U08** | Công thức giá nâng cấp | HP/KI = 100+8n, Công = 200+60n, Giáp = 500+120n chuẩn xác | **PASS** |
| **U09** | Cập nhật nâng điểm | Phản ánh đúng số lần nâng và giá trị chỉ số mới từ server | **PASS** |
| **U10** | Trạng thái thiếu Tinh Năng | Nút nâng tự động khóa (disabled=true, nhãn "Thiếu TN") | **PASS** |
| **U11** | Bảng tử vong khi HP=0 | Mở đúng CanvasLayer (layer 10), khóa phím Esc/K | **PASS** |
| **U12** | Quy tắc 2 nút Hồi sinh | Về Nhà hoạt động miễn phí; Tại Chỗ khóa vĩnh viễn (Cần hệ Vàng) | **PASS** |
| **U13** | Kiểm thử Responsive đa độ phân giải | Đạt chuẩn bố cục ở 1280×720 và 1600×900, đã lưu 6 ảnh screenshot | **PASS** |
| **U14** | Lưu / Nạp hồ sơ JSON | Bảo toàn dữ liệu tiến trình trọn vẹn, không lỗi format | **PASS** |
| **U15** | Hồi quy toàn bộ test cũ | 38/38 bài test cũ (T01–T16, D01–D16, A01–A07) tiếp tục PASS 100% | **PASS** |
| **U16** | Chuẩn mực Code & Git | Chỉ sửa UI, không chạm logic combat/mạng, branch chuẩn quy định | **PASS** |

---

## 3. Ảnh chụp thực tế kiểm thử giao diện & Responsive

Các ảnh chụp màn hình được sinh tự động bằng GPU rendering thông qua script [capture_ui_screenshots.gd](file:///h:/Hao_Tap_Lam_game/test_0/scripts/capture_ui_screenshots.gd) tại thư mục `test_0/screenshots/` và `noidungduara/screenshots/`:

1. **Giao diện HUD lúc chơi:**
   - [ui_hud_1280x720.png](file:///h:/Hao_Tap_Lam_game/test_0/screenshots/ui_hud_1280x720.png) (Độ phân giải chuẩn 1280×720)
   - [ui_hud_1600x900.png](file:///h:/Hao_Tap_Lam_game/test_0/screenshots/ui_hud_1600x900.png) (Kiểm thử mở rộng 1600×900)
2. **Bảng Nhân vật (Menu K):**
   - [ui_menu_k_1280x720.png](file:///h:/Hao_Tap_Lam_game/test_0/screenshots/ui_menu_k_1280x720.png) (Độ phân giải chuẩn 1280×720)
   - [ui_menu_k_1600x900.png](file:///h:/Hao_Tap_Lam_game/test_0/screenshots/ui_menu_k_1600x900.png) (Kiểm thử mở rộng 1600×900)
3. **Màn hình Tử Vong & Lựa chọn Hồi sinh:**
   - [ui_respawn_1280x720.png](file:///h:/Hao_Tap_Lam_game/test_0/screenshots/ui_respawn_1280x720.png) (Độ phân giải chuẩn 1280×720)
   - [ui_respawn_1600x900.png](file:///h:/Hao_Tap_Lam_game/test_0/screenshots/ui_respawn_1600x900.png) (Kiểm thử mở rộng 1600×900)

---

## 4. Ghi chú các vấn đề giữ nguyên cho giai đoạn tiếp theo (`KNOWN_GAPS.md`)

- **Kỹ năng 1**: Hiện tại animation đòn đánh M1 vẫn giữ nguyên placeholder (vung kiếm). Tuyệt đối không coi đây là chiêu thức kiếm thuật, chiêu chính thức theo GDD là **Đấm / Đá bọc nguyên tố ma pháp** sẽ được tích hợp khi đội ngũ 2D Artist bàn giao bộ sprite `punch_combo` và `kick_elemental`.
- **Hệ thống Vàng & Hồi sinh tại chỗ**: Tiếp tục khóa vĩnh viễn nút "Hồi sinh tại chỗ — Chưa mở" cho tới khi có module tiền tệ Vàng.
- **Môi trường & Slime**: Bản đồ vẫn là 1 map cỏ Khu 1, chưa bổ sung parallax background nhiều lớp hay sprite slime mới (để dành cho đợt v0.1.2B).

---

## 5. Trạng thái Git & Pull Request

- Nhánh làm việc: `feats/ui-visual-pass-v012a`
- Cam kết tuân thủ quy ước: `[update]: polish HUD character menu and respawn visuals`
- Không commit file save cá nhân, không push vào `master`.
- Sẵn sàng tạo Pull Request vào nhánh `dev` ngay khi được yêu cầu.
