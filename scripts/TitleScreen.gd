extends Control

@onready var btn_start = $BtnStart
@onready var btn_continue = $BtnContinue

func _ready() -> void:
	if has_node("/root/MobileUI"): MobileUI.hide()
	
	if has_node("/root/AudioManager"):
		AudioManager.play_main_bgm()
		
	btn_start.pressed.connect(_on_start_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)

func _on_start_pressed() -> void:
	# 시작하기: 나중에 세이브/로드 구현 전까지 바로 광장으로 가는 임시 기능이었으나, 이제 반대로 설정
	get_tree().change_scene_to_file("res://scenes/MainPlaza.tscn")

func _on_continue_pressed() -> void:
	# 이어하기: 캐릭터 선택 화면으로 이동
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")
