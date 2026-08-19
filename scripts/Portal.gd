extends Area2D

## ─────────────────────────────────────────────────────────────
## Portal.gd
## 맵의 진출입로에 배치되는 Area2D 포털 스크립트.
## 플레이어(CharacterBody2D, "player" 그룹)가 충돌 영역에 진입하면
## GameManager에 스폰 마커 이름을 저장한 후 씬을 전환합니다.
##
## [에디터에서 설정할 속성]
##   target_scene        : 이동할 씬의 리소스 경로 (예: "res://scenes/Forest.tscn")
##   target_spawn_marker : 도착 씬에서 플레이어가 등장할 Marker2D 이름 (예: "FromPlaza")
## ─────────────────────────────────────────────────────────────

## 이동할 씬의 경로 (res://scenes/씬이름.tscn 형식)
@export var target_scene: String = ""

## 도착 씬의 스폰 Marker2D 노드 이름
@export var target_spawn_marker: String = ""

## 씬 전환 중복 실행 방지 플래그
var _is_transitioning: bool = false

func _ready() -> void:
	# body_entered 시그널 연결
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# 플레이어 그룹 확인 및 중복 전환 방지
	if _is_transitioning:
		return
	if not body.is_in_group("player"):
		return
	if target_scene.is_empty():
		push_warning("Portal [%s]: target_scene이 설정되지 않았습니다." % name)
		return

	_is_transitioning = true

	# 다음 씬의 스폰 마커 이름을 GameManager에 저장
	GameManager.spawn_point_name = target_spawn_marker

	# 씬 전환 실행
	get_tree().change_scene_to_file(target_scene)
