extends Control

# UI 노드 참조
@onready var btn_char1 = $BtnChar1
@onready var btn_char2 = $BtnChar2
@onready var sprite_char1 = $SpriteChar1
@onready var sprite_char2 = $SpriteChar2
@onready var btn_select = $BtnSelectComplete

func _ready() -> void:
	if has_node("/root/MobileUI"): MobileUI.hide()
	
	if has_node("/root/AudioManager"):
		AudioManager.play_main_bgm()
		
	# 초기에는 선택된 캐릭터 1로 설정 (원하시는 대로 변경 가능)
	GameManager.selected_character = 1
	_update_selection_visuals()
	
	btn_char1.pressed.connect(_on_char1_pressed)
	btn_char2.pressed.connect(_on_char2_pressed)
	btn_select.pressed.connect(_on_select_complete_pressed)

func _on_char1_pressed() -> void:
	GameManager.selected_character = 1
	_update_selection_visuals()

func _on_char2_pressed() -> void:
	GameManager.selected_character = 2
	_update_selection_visuals()

# 선택된 캐릭터를 시각적으로 강조
func _update_selection_visuals() -> void:
	if GameManager.selected_character == 1:
		sprite_char1.modulate = Color(1.0, 1.0, 1.0, 1.0) # 완전 불투명 (선택됨)
		sprite_char2.modulate = Color(0.5, 0.5, 0.5, 0.7) # 어둡고 반투명 (선택 안됨)
	else:
		sprite_char1.modulate = Color(0.5, 0.5, 0.5, 0.7)
		sprite_char2.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_select_complete_pressed() -> void:
	# 캐릭터 선택 완료 버튼 클릭 시 메인 게임으로 진입
	get_tree().change_scene_to_file("res://scenes/MainPlaza.tscn")

# 애니메이션을 위한 변수
var anim_timer: float = 0.0
const ANIM_SPEED: float = 0.15

func _process(delta: float) -> void:
	anim_timer += delta
	if anim_timer >= ANIM_SPEED:
		anim_timer -= ANIM_SPEED
		
		if GameManager.selected_character == 1:
			# 1번 캐릭터 걷기 애니메이션 (0~3 프레임 순환)
			sprite_char1.frame_coords.x = (sprite_char1.frame_coords.x + 1) % 4
			# 2번 캐릭터는 차렷 자세 고정
			sprite_char2.frame_coords.x = 0
		else:
			# 2번 캐릭터 걷기 애니메이션 (0~3 프레임 순환)
			sprite_char2.frame_coords.x = (sprite_char2.frame_coords.x + 1) % 4
			# 1번 캐릭터는 차렷 자세 고정
			sprite_char1.frame_coords.x = 0

