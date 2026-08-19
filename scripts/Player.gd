extends CharacterBody2D

## ─────────────────────────────────────────────────────────────
## Player.gd
## 4방향 이동 및 걷기 애니메이션 스크립트.
## GameManager의 selected_character 값에 따라 스프라이트를 교체합니다.
## ─────────────────────────────────────────────────────────────

const SPEED: float = 300.0

@onready var sprite = $Sprite2D

# 애니메이션 타이머 (프레임 갱신용)
var anim_timer: float = 0.0
const ANIM_SPEED: float = 0.10 # 프레임당 시간 (초)

# 방향 정의 (row 인덱스)
enum Dir { DOWN = 0, LEFT = 1, RIGHT = 2, UP = 3 }
var current_dir: Dir = Dir.DOWN

func _ready() -> void:
	add_to_group("player")
	
	# 캐릭터 선택값에 따라 텍스처 로드
	if GameManager.selected_character == 1:
		sprite.texture = load("res://assets/character/character1.png")
	else:
		sprite.texture = load("res://assets/character/character2.png")
	
	# 초기 프레임 설정
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.frame_coords = Vector2i(0, current_dir)

func _physics_process(delta: float) -> void:
	var direction := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up",   "ui_down")
	)

	if direction != Vector2.ZERO:
		velocity = direction.normalized() * SPEED
		_update_animation(direction, delta, true)
	else:
		velocity = Vector2.ZERO
		_update_animation(Vector2.ZERO, delta, false)

	move_and_slide()

func _update_animation(dir: Vector2, delta: float, is_moving: bool) -> void:
	# 방향 판단
	if dir.x < 0:
		current_dir = Dir.LEFT
	elif dir.x > 0:
		current_dir = Dir.RIGHT
	elif dir.y < 0:
		current_dir = Dir.UP
	elif dir.y > 0:
		current_dir = Dir.DOWN

	if is_moving:
		anim_timer += delta
		if anim_timer >= ANIM_SPEED:
			anim_timer -= ANIM_SPEED
			# 걷기 프레임은 0, 1, 2, 3 순환
			var next_frame_x = (sprite.frame_coords.x + 1) % 4
			sprite.frame_coords = Vector2i(next_frame_x, current_dir)
		else:
			# 방향이 바뀌었을 때 즉시 반영
			sprite.frame_coords.y = current_dir
	else:
		# 정지 시에는 0번 프레임(차렷 자세)으로 초기화
		anim_timer = 0.0
		sprite.frame_coords = Vector2i(0, current_dir)
