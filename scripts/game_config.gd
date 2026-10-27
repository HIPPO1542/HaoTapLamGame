extends Node

# [TEST] Cấu hình thông số Prototype v0.1 - Ma Pháp Huyễn Giới 2D
# Nguồn: Prototype_v0_1_Implementation_Spec_Codex.md & GDD v2.3

# Mạng
const SERVER_IP: String = "127.0.0.1"
const SERVER_PORT: int = 24567
const MAX_CLIENTS: int = 1
const NETWORK_SNAPSHOT_RATE: float = 15.0 # snapshots / giây (10-20 Hz)
const INPUT_TIMEOUT_SEC: float = 0.3 # 300 ms mất input thì dừng chạy

# Chuẩn thế giới
const TILE_SIZE: float = 32.0 # 1 đơn vị thế giới logic = 32 px

# Nhân vật M1 mặc định
const M1_INIT_HP: int = 100
const M1_INIT_KI: int = 100
const M1_INIT_ATTACK: int = 10
const M1_INIT_ARMOR: int = 0
const M1_MOVE_SPEED: float = 160.0 # px/s
const M1_JUMP_VELOCITY: float = -320.0 # px/s
const GRAVITY: float = 800.0 # px/s^2

# Kỹ năng Phím 1 (Đánh thường)
const SKILL_1_RANGE: float = 1.5 * TILE_SIZE # 48 px, chỉ phía trước
const SKILL_1_KI_COST: int = 1
const SKILL_1_COOLDOWN: float = 0.7 # giây
const KI_REGEN_PER_SEC: float = 1.0 # 1 KI/s hồi tự nhiên

# Quái Slime
const SLIME_COUNT: int = 8
const SLIME_INIT_HP: int = 100
const SLIME_ATTACK_DAMAGE: int = 5
const SLIME_CHASE_RANGE: float = 4.0 * TILE_SIZE # 128 px
const SLIME_ATTACK_RANGE: float = 1.0 * TILE_SIZE # 32 px
const SLIME_ATTACK_COOLDOWN: float = 1.5 # giây
const SLIME_RESPAWN_MIN_TIME: float = 3.0 # giây
const SLIME_RESPAWN_MAX_TIME: float = 5.0 # giây
const SLIME_SPAWN_SPACING: float = 3.0 * TILE_SIZE # 96 px

# Tính giá nâng chỉ số trong Menu -> Nhân vật (lần nâng thứ n, n bắt đầu từ 0)
static func get_upgrade_cost(stat_id: String, count: int) -> int:
	match stat_id:
		"hp":
			return 100 + 8 * count
		"ki":
			return 100 + 8 * count
		"attack":
			return 200 + 60 * count
		"armor":
			return 500 + 120 * count
		_:
			return 999999999

static func get_upgrade_increase(stat_id: String) -> int:
	match stat_id:
		"hp":
			return 20
		"ki":
			return 20
		"attack":
			return 1
		"armor":
			return 1
		_:
			return 0

# Tính sát thương quái đánh người
static func compute_monster_damage_to_player(monster_attack: int, player_armor: int) -> int:
	var raw: float = float(monster_attack) * 1000.0 / (1000.0 + float(player_armor))
	return int(max(1, floor(raw)))
