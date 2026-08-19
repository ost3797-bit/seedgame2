extends Node2D

## ─────────────────────────────────────────────────────────────
## MapController.gd
## 각 맵 씬의 최상위 Node2D에 부착되는 스크립트.
## _ready()에서 GameManager.spawn_point_name을 확인하고,
## 해당 이름의 Marker2D 위치로 플레이어를 이동시킵니다.
##
## [씬 구조 요구사항]
##   - "player" 그룹에 등록된 CharacterBody2D가 씬 내에 존재해야 함
##   - 스폰 마커(Marker2D)가 씬 내 어딘가에 존재해야 함
##   - spawn_point_name이 비어있으면 "Default" 마커를 기본으로 사용
## ─────────────────────────────────────────────────────────────

func _ready() -> void:
	if has_node("/root/MobileUI"): MobileUI.show()
	
	if has_node("/root/AudioManager"):
		AudioManager.play_main_bgm()
		
	# 자식 노드들이 모두 _ready()를 마친 직후 실행되도록 deferred 호출
	call_deferred("_place_player_on_spawn_point")

## GameManager에 저장된 스폰 마커 이름을 읽어 플레이어를 해당 위치로 이동
func _place_player_on_spawn_point() -> void:
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		push_warning("MapController: 'player' 그룹에 등록된 노드가 없습니다.")
		GameManager.spawn_point_name = ""
		return

	if GameManager.use_return_position:
		players[0].global_position = GameManager.return_position
		GameManager.use_return_position = false
		return
		
	var marker_name: String = GameManager.spawn_point_name

	# 이름이 비어있으면 기본 스폰 지점("Default") 사용
	if marker_name.is_empty():
		marker_name = "Default"

	# 씬 트리 전체에서 해당 이름의 Marker2D 탐색
	var marker: Node = find_child(marker_name, true, false)
	if marker == null:
		push_warning(
			"MapController [%s]: '%s' 스폰 마커를 찾을 수 없습니다. 'Default' 마커를 확인하세요." \
			% [scene_file_path, marker_name]
		)
		GameManager.spawn_point_name = ""
		return

	players[0].global_position = marker.global_position

	# 사용한 스폰 마커 이름 초기화 (재진입 시 Default 사용)
	GameManager.spawn_point_name = ""
