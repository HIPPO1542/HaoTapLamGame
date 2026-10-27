# IMPLEMENTATION NOTES — PROTOTYPE v0.1

**Dự án:** Ma Pháp Huyễn Giới 2D  
**Thư mục triển khai:** `test_0/`  
**Trạng thái:** HOÀN TẤT TRỌN VẸN 5 BƯỚC THEO ĐẶC TẢ CODEX (v0.1)  
**Ngày cập nhật:** 27/10/2026  

---

## 1. TỔNG QUAN KIẾN TRÚC & QUYẾT ĐỊNH KỸ THUẬT

1. **Kiến trúc mạng (High-level Multiplayer):**
   - Sử dụng `ENetMultiplayerPeer` (UDP) có sẵn trong Godot 4.x.
   - Node mạng trung tâm `NetworkBridge` được cấu hình dưới dạng **Autoload (`/root/NetworkBridge`)**. Điều này bảo đảm NodePath tuyệt đối trên cả Server và Client hoàn toàn giống nhau 100%, ngăn ngừa lỗi RPC NodePath mismatch khi thay đổi scene.
   - Server bind vào đúng `127.0.0.1:24567`, `max_clients = 1`, không mở LAN/Internet.

2. **Hệ thống điều khiển 4 hướng (ADWS & 4 phím Mũi tên):**
   - Hỗ trợ toàn diện cả phím **A/D/W/S** và **4 phím Mũi tên** (`←`, `→`, `↑`, `↓`):
     - Trái / Phải: `A` / `D` hoặc `←` / `→`
     - Nhảy / Hướng lên: `W` hoặc `↑` hoặc `Space`
     - Cúi / Hướng xuống: `S` hoặc `↓`

3. **Server Authoritative Physics & AI (Bước 2 & Bước 3):**
   - Client chỉ gửi input phím bấm (`submit_input`).
   - Server thực thi toàn bộ mô phỏng vật lý: gia tốc trọng lực (`GRAVITY = 800.0`), vận tốc chạy (`M1_MOVE_SPEED = 160.0`), nhảy (`M1_JUMP_VELOCITY = -320.0`), va chạm collider và clamp ranh giới bản đồ `[20.0, 2540.0]`.
   - Timeout input 300 ms (`INPUT_TIMEOUT_SEC = 0.3`): Nếu mất kết nối hoặc không nhận gói input sau 300ms, Server tự động reset hướng di chuyển về 0, không chạy vô tận.
   - **8 Slime ma pháp:**
     - Sinh chính xác 8 con tại 8 điểm sinh cố định kề nhau cách 96 px (3 đơn vị logic): x = 500, 596, 692, 788, 884, 980, 1076, 1172 trên mặt đất y = 580.
     - Slime AI: Khi M1 trong tầm 128 px (4 đơn vị), Slime đuổi theo; khi áp sát trong tầm 32 px (1 đơn vị), Slime tấn công sau mỗi 1.5s, gây sát thương lên M1 theo công thức giáp.
     - Khi Slime chết (`HP <= 0`): Biến mất, server đếm giờ ngẫu nhiên từ `3.0` đến `5.0` giây rồi hồi sinh đúng 1 con tại điểm sinh ban đầu của chính nó (không bao giờ sinh thêm con thứ 9).
   - **Kỹ năng Phím 1 (Đánh thường):**
     - Tiêu hao 1 KI, hồi chiêu 0.7 giây, tầm đánh 48 px (1.5 đơn vị) **chỉ phía trước mặt**.
     - Server kiểm tra quyền lực: M1 còn sống, đủ KI, hết hồi chiêu. Nếu bấm ngoài tầm, vẫn tốn KI và chạy hồi chiêu nhưng quái không bị mất HP.
     - Hồi KI tự nhiên: 1 KI / giây khi còn sống.
   - **M1 tử nạn (T15):** Khi bị quái đánh về 0 HP, server hồi sinh tạm tại spawn point `[160, 580]` với đầy đủ 100/100 HP và KI, không trừ điểm.

4. **Tiến trình Tinh Lực, Tinh Năng và Nâng điểm (Bước 4):**
   - **Quy tắc 1 HP thực mất = 1 Tinh Lực:** Server tính toán sát thương thực tế `actual_hp_lost = min(max(0, computed_damage), mob_hp_remaining)`. Không bao giờ cộng điểm dựa trên damage ảo vượt quá máu còn lại của quái (T08, T09).
   - **Bảo toàn Tinh Lực:** `tinh_luc` không bao giờ bị trừ khi nâng chỉ số.
   - **Tinh Năng và Công thức nâng 4 chỉ số (GDD v2.3 mục 12):**
     - HP tối đa (+20): `100 + 8 * n` (nâng HP tăng cả máu hiện tại lẫn tối đa).
     - KI tối đa (+20): `100 + 8 * n` (nâng KI tăng cả năng lượng hiện tại lẫn tối đa).
     - Công Lực (+1): `200 + 60 * n`.
     - Giáp (+1): `500 + 120 * n`.
   - **Chống gian lận & Idempotency (T11):** Sử dụng `processed_requests` để lưu kết quả theo `request_id`. Nếu client spam nút nâng hoặc mạng bị lặp gói cùng `request_id`, server chỉ thực thi 1 lần duy nhất, không bao giờ trừ điểm 2 lần.
   - **Bảng Menu Nhân vật (Phím K):** Hoạt động trực tiếp từ HUD hoặc phím K trên bàn phím. Người chơi có thể nâng chỉ số ở bất cứ đâu trên bản đồ (T12), **hoàn toàn không cần NPC Đạo Sư** theo đúng tinh thần tài liệu.

5. **Lưu trữ hồ sơ bền vững trên SERVER (Bước 5):**
   - Định dạng lưu JSON tại đường dẫn chuẩn `user://saves/player_save.json` theo đúng Schema Mục 7.2.
   - **Safe Atomic Save:** Ghi ra file tạm `.tmp`, sao lưu file cũ thành `.bak`, sau đó mới thay thế an toàn vào file chính để chống hỏng file khi mất điện đột ngột.
   - **Thời điểm lưu:** Lưu ngay sau khi nâng điểm, lưu tự động mỗi 5 giây, lưu khi client ngắt kết nối và khi server tắt bình thường.
   - **Độc quyền Server:** Chỉ Server ghi file save; Client không được can thiệp vào file save.

6. **Giao diện HUD gợi nhớ NRO (Bước 5):**
   - Góc trên trái: Avatar M1, thanh máu đỏ `HP: current/max`, thanh năng lượng xanh `KI: current/max`, số Tinh Lực (vàng) và Tinh Năng (xanh ngọc).
   - Dưới cùng: Thanh 8 ô kỹ năng, trong đó Phím 1 sáng và có hiệu ứng hồi chiêu mờ (0.7s), các phím 2–8 bị khóa xám.
   - Góc trên phải: Nút bấm nhanh mở bảng Nhân Vật (phím K).
   - Combat feedback: Số sát thương nổi đỏ trên đầu Slime, popup `+TL / +TN` trên đầu M1.
   - Màn hình mất kết nối: Khóa điều khiển và hiển thị hộp thoại thông báo rõ ràng, không bị crash.

---

## 2. MA TRẬN KIỂM THỬ NGHIỆM THU (T01 — T16)

Toàn bộ 16 bài kiểm thử đã được hiện thực hóa và kiểm chứng thông qua bộ script tự động hóa:

| ID | Thao tác kiểm thử | Trạng thái | Chi tiết nghiệm thu |
|---|---|---|---|
| **T01** | Chạy server trước client | **PASS** | Server bind `127.0.0.1:24567`, lắng nghe peer kết nối và cập nhật UI/console `Client da ket noi`. |
| **T02** | Chạy client khi server chưa có | **PASS** | Client bắt sự kiện `connection_failed`, hiển thị thông báo lỗi rõ, dừng an toàn, không crash. |
| **T03** | Di chuyển hết rìa map / nhảy | **PASS** | Collider mặt đất (y: 580) + tường 2 bên (x: 0, x: 2560) và clamp server ngăn xuyên đất/vượt map. Camera giới hạn 0..2560. Hỗ trợ ADWS & 4 phím mũi tên. |
| **T04** | Đếm Slime | **PASS** | Khởi tạo chính xác 8 Slime ma pháp tại 8 điểm sinh cố định (cách nhau 96px = 3 tile logic). |
| **T05** | Giết 1 Slime & hồi sinh | **PASS** | Slime chết biến mất, server đếm 3–5 giây và hồi sinh đúng 1 con tại đúng điểm sinh ban đầu; không sinh con thứ 9. |
| **T06** | Phím 1 trong/ngoài tầm | **PASS** | Server kiểm tra tầm 48px phía trước mặt; trúng thì trừ HP, ngoài tầm hoặc quay lưng thì chém gió, không trừ HP quái. |
| **T07** | Spam Phím 1 (CD & KI) | **PASS** | Server khóa lệnh đánh khi chưa hết hồi chiêu 0.7s hoặc khi cạn KI. Tự hồi 1 KI/giây khi còn sống. |
| **T08** | Mob 1 HP nhận 10 dmg (+1/+1) | **PASS** | Chỉ tính sát thương thực mất (1 HP) -> Nhận đúng 1 Tinh Lực và 1 Tinh Năng [TEST]. |
| **T09** | Hạ 100 HP Slime nhận đủ 100 TL/TN | **PASS** | Đánh Slime từ 100 HP về 0 HP nhận chính xác 100 Tinh Lực và 100 Tinh Năng. |
| **T10** | Mở Menu K, nâng HP/KI/Công/Giáp | **PASS** | Chỉ số tăng đúng (+20 HP/KI, +1 Công/Giáp), giá tăng theo n, trừ đúng Tinh Năng, không âm điểm. |
| **T11** | Idempotency request_id nâng điểm | **PASS** | Bấm 2 lần cùng `request_id` chỉ được server xử lý 1 lần, không bị trừ điểm 2 lần. |
| **T12** | Nâng điểm mọi vị trí map (không NPC) | **PASS** | Bấm phím K nâng điểm tại bất kỳ vị trí nào, không kiểm tra khoảng cách NPC. Tinh Lực không bị trừ khi nâng điểm. |
| **T13** | Tắt client khi đánh quái | **PASS** | Server giữ nguyên tiến trình đã xác nhận và lưu vào JSON; client kết nối lại không tự nhận thêm điểm ảo. |
| **T14** | Tắt mở lại server nạp dữ liệu | **PASS** | Toàn bộ dữ liệu hồ sơ (Tinh Lực, Tinh Năng, số lần nâng cấp, chỉ số) được tải lại chính xác từ JSON. |
| **T15** | Slime đánh M1 về 0 HP hồi sinh | **PASS** | Khi HP về 0, hồi sinh ngay tại spawn point map, đầy HP/KI, không trừ điểm. |
| **T16** | Reconnect nhận lại state | **PASS** | Client kết nối lại nhận ngay snapshot và tiến trình từ Server, không cộng điểm trùng lặp. |
