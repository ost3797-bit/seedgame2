extends Node

## ─────────────────────────────────────────────────────────────
## GameManager (AutoLoad 싱글톤)
## 씬 전환 시, 다음 맵에서 플레이어가 등장할 스폰 마커의 이름을 임시로 저장합니다.
## 포털이 이 값을 설정하고, 맵 컨트롤러가 읽은 뒤 초기화합니다.
## ─────────────────────────────────────────────────────────────

## 다음 씬에서 플레이어를 스폰할 Marker2D 노드의 이름
## 빈 문자열이면 해당 씬의 "Default" 마커를 사용함
var spawn_point_name: String = ""
var return_position: Vector2 = Vector2.ZERO
var use_return_position: bool = false

## 선택된 캐릭터 (1: character1, 2: character2)
var selected_character: int = 1

## 씨앗 수집 상태
var collected_seeds: int = 0
var total_seeds: int = 9

## 꽃밭 맵 퀘스트 상태
var sorrel_quest_state: int = 0
var balsam_quest_state: int = 0
var dandelion_quest_state: int = 0
var maple_quest_state: int = 0
var camellia_quest_state: int = 0
var hyacinth_quest_state: int = 0
var cattail_quest_state: int = 0
var bean_quest_state: int = 0
var corn_quest_state: int = 0
var tomato_quest_state: int = 0

var flowerbed_sorrel_cleared: bool = false
var flowerbed_balsam_cleared: bool = false
var flowerbed_dandelion_cleared: bool = false
var forest_maple_cleared: bool = false
var forest_camellia_cleared: bool = false
var pond_hyacinth_cleared: bool = false
var pond_cattail_cleared: bool = false
var farm_bean_cleared: bool = false
var farm_corn_cleared: bool = false
var farm_tomato_cleared: bool = false
