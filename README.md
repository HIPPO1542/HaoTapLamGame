# MA PHÁP HUYỄN GIỚI 2D — PROTOTYPE v0.1

Bản thử nghiệm nguyên mẫu hoàn chỉnh (Prototype v0.1) cho game **Ma Pháp Huyễn Giới 2D** xây dựng trên nền tảng **Godot 4.x + GDScript** theo kiến trúc **Server Authoritative**.

---

## 1. YÊU CẦU MÔI TRƯỜNG & PHIÊN BẢN

- **Engine:** Godot Engine 4.x (tương thích hoàn hảo với các bản **Godot 4.2 / 4.3 / 4.4 stable** dành cho Windows).
- **Hệ điều hành:** Windows 10/11 64-bit.
- **Giao thức mạng:** ENet UDP Localhost (`127.0.0.1:24567`), không yêu cầu Internet hay database bên ngoài.
- **Vị trí lưu trữ dữ liệu (Server Save):** Thư mục chuẩn `user://saves/player_save.json` (do Server quản lý độc quyền).

---

## 2. CẤU TRÚC THƯ MỤC DỰ ÁN (`test_0/`)

```text
test_0/
├── project.godot                     # Cấu hình dự án (Autoloads, InputMap, Display 1280x720, Nearest Texture)
├── README.md                         # Hướng dẫn chi tiết cách chạy và phím bấm
├── assets/
│   ├── characters/m1/                # Sprite M1 tóc đen (các frame idle, run, jump, attack, hurt và m1_frames.tres)
│   ├── monsters/slime/               # Sprite Slime ma pháp (idle, move, attack, hurt và slime_frames.tres)
│   └── environment/                  # Nền đồng cỏ grassland_bg.png và ground_tile.png
├── scenes/
│   ├── main.tscn                     # Màn hình chính phân phối Server/Client, điều khiển ngắt kết nối
│   ├── test_grassland.tscn           # Bản đồ đồng cỏ 2.560 × 720 px với hệ thống collider tĩnh
│   ├── player.tscn                   # Thực thể nhân vật M1 với Camera2D bám theo
│   ├── slime.tscn                    # Thực thể Slime ma pháp với thanh máu HPBar
│   └── ui/
│       ├── hud.tscn                  # HUD phong cách NRO (Avatar, HP/KI, Tinh Lực/Tinh Năng, 8 ô kỹ năng)
│       └── character_stats_panel.tscn # Bảng Menu Nhân vật (phím K) nâng 4 chỉ số trực tiếp
├── scripts/
│   ├── main.gd                       # Điều phối khởi động CLI --server / --client và giao diện chính
│   ├── network_bridge.gd             # Autoload mạng ENet + định nghĩa đầy đủ RPC đồng bộ
│   ├── game_config.gd                # Cấu hình tập trung toàn bộ thông số [TEST]
│   ├── server_world.gd               # Quản lý thế giới authoritative, 8 Slime, combat và autosave
│   ├── player_controller.gd          # Điều khiển vật lý M1, combat Phím 1, hồi phục KI tự nhiên
│   ├── slime_ai.gd                   # AI quái: đứng yên, đuổi theo (128px), đánh cận chiến (32px), hồi sinh (3-5s)
│   ├── progression_system.gd         # Tính điểm 1 HP = 1 Tinh Lực, nâng 4 chỉ số và bộ đệm Idempotency
│   ├── save_repository.gd            # Xử lý lưu/nạp JSON an toàn (Atomic Save qua .tmp và .bak)
│   └── hud_controller.gd             # Điều khiển hiển thị HUD và popup điểm thưởng
├── tests/
│   ├── test_step1_network.gd         # Kiểm tra cấu hình và mạng (T01, T02)
│   ├── test_step2_movement.gd        # Kiểm tra vật lý di chuyển và map (T03)
│   ├── test_step3_combat.gd          # Kiểm tra 8 Slime, tầm đánh Phím 1, CD và hồi sinh (T04, T05, T06, T07, T15)
│   ├── test_step4_progression.gd     # Kiểm tra Tinh Lực, Tinh Năng, nâng chỉ số (T08, T09, T10, T11, T12)
│   ├── test_step5_saveload.gd        # Kiểm tra lưu/nạp JSON server (T13, T14, T16)
│   └── run_all_tests.gd              # Script kiểm thử trọn bộ 16 bài kiểm thử T01 -> T16
└── docs/
    └── IMPLEMENTATION_NOTES.md       # Báo cáo kỹ thuật chi tiết và ma trận nghiệm thu T01–T16
```

---

## 3. CÁCH KHỞI CHẠY TRÊN WINDOWS

Bạn có thể chạy độc lập **2 tiến trình (1 Server Headless + 1 Client)** từ hai cửa sổ PowerShell hoặc mở trực tiếp từ **Godot Editor**.

### Cách 1: Chạy bằng 2 Terminal PowerShell (Khuyến nghị theo đặc tả)

Mở PowerShell tại thư mục `H:\Hao_Tap_Lam_game\test_0` (thay `<đường_dẫn_godot>` bằng file chạy Godot trên máy bạn):

**Terminal 1 — Khởi động Server Headless:**
```powershell
& "<đường_dẫn_godot_console.exe>" --headless --path . -- --server
```
*Kết quả:* Server bind cổng `127.0.0.1:24567`, nạp hồ sơ lưu từ trước (nếu có) và sinh sẵn 8 Slime:  
`[ServerWorld] Server sẵn sàng (Hồ sơ đã nạp: TL=..., TN=...).`

**Terminal 2 — Khởi động Client PC:**
```powershell
& "<đường_dẫn_godot.exe>" --path . -- --client
```
*Kết quả:* Client kết nối thành công, nạp thế giới đồng cỏ, hiển thị nhân vật M1 tóc đen, thanh HUD và 8 Slime.

---

### Cách 2: Chạy trực tiếp từ Godot Editor

1. Mở thư mục `test_0` bằng **Godot Engine 4.x**.
2. Nhấn **F5** (hoặc nút Run Project) để khởi chạy `scenes/main.tscn`.
3. Giao diện trực quan cho phép bạn:
   - Bấm **"Chạy Server Local"** để khởi động Server.
   - Bấm **"Chạy Client Kết Nối"** để tham gia thế giới dưới vai trò người chơi.
   - Bấm **"Reset Save Test"** để xóa file lưu và đưa dữ liệu về trạng thái ban đầu sạch.
   - Bấm **"Dừng Mạng"** để ngắt kết nối an toàn.

---

## 4. HỆ THỐNG PHÍM ĐIỀU KHIỂN

| Phím bấm | Hành động | Mô tả chi tiết |
|---|---|---|
| **A / D** hoặc **← / →** | Di chuyển trái / phải | Di chuyển M1 (160 px/s), tự lật hình nhân vật |
| **W** hoặc **↑** hoặc **Space** | Nhảy / Hướng lên | Nhảy đơn vị (-320 px/s) khi đang chạm đất |
| **S** hoặc **↓** | Hướng xuống / Cúi | Điều khiển hướng xuống |
| **1** | Đánh thường cận chiến | Tốn 1 KI, hồi chiêu 0.7s, tầm 48px chỉ phía trước mặt |
| **K** | Mở/đóng Menu → Nhân vật | **Nâng HP, KI, Công Lực, Giáp trực tiếp tại đây** |
| **Esc** | Đóng cửa sổ | Đóng bảng Menu Nhân vật đang mở |

> **LƯU Ý BẮT BUỘC:** Prototype v0.1 **KHÔNG CÓ NPC ĐẠO SƯ**. Việc nâng cấp chỉ số diễn ra trực tiếp trong bảng Menu Nhân vật (phím K) ở bất cứ đâu trên bản đồ, không cần gặp NPC.

---

## 5. CÔNG THỨC NÂNG ĐIỂM (MENU NHÂN VẬT — PHÍM K)

Nâng điểm sử dụng **Tinh Năng** (nhận từ sát thương thực tế quái bị mất, tỉ lệ 1:1 [TEST]). **Tinh Lực không bao giờ bị trừ.**

| Chỉ số | Mức tăng mỗi lần | Chi phí Tinh Năng lần thứ `n` (`n` = số lần đã nâng, bắt đầu từ 0) |
|---|:---:|---|
| **Máu tối đa (HP)** | **+20** | `100 + 8 * n` (hồi ngay 20 HP hiện tại) |
| **Năng lượng tối đa (KI)** | **+20** | `100 + 8 * n` (hồi ngay 20 KI hiện tại) |
| **Công Lực** | **+1** | `200 + 60 * n` (tăng trực tiếp sát thương đòn đánh) |
| **Giáp** | **+1** | `500 + 120 * n` (giảm sát thương nhận vào từ Slime) |

---

## 6. HƯỚNG DẪN CHẠY KIỂM THỬ TỰ ĐỘNG

Dự án cung cấp đầy đủ các file kiểm thử tự động hóa có thể chạy ở chế độ Headless:

```powershell
# 1. Chạy toàn bộ 16 bài kiểm thử nghiệm thu (T01 -> T16):
& "<đường_dẫn_godot.exe>" --headless -s tests/run_all_tests.gd

# 2. Hoặc chạy kiểm thử riêng từng bước:
& "<đường_dẫn_godot.exe>" --headless -s tests/test_step1_network.gd       # Bước 1
& "<đường_dẫn_godot.exe>" --headless -s tests/test_step2_movement.gd      # Bước 2
& "<đường_dẫn_godot.exe>" --headless -s tests/test_step3_combat.gd        # Bước 3
& "<đường_dẫn_godot.exe>" --headless -s tests/test_step4_progression.gd   # Bước 4
& "<đường_dẫn_godot.exe>" --headless -s tests/test_step5_saveload.gd      # Bước 5
```
