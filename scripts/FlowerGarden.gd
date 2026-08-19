extends "res://scripts/MapController.gd"

const FONT_PATH := "res://fonts/Cafe24Ssurround-v2.0.ttf"

var seed_ui: CanvasLayer
@onready var cat_npc: Area2D = $CatNPC
@onready var hint_label: Label = $CatNPC/HintLabel

@onready var sorrel_plant: Area2D = $SorrelPlant
@onready var sorrel_hint: Label = $SorrelPlant/HintLabel
@onready var balsam_plant: Area2D = $BalsamPlant
@onready var balsam_hint: Label = $BalsamPlant/HintLabel
@onready var dandelion_plant: Area2D = $DandelionPlant
@onready var dandelion_hint: Label = $DandelionPlant/HintLabel

@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var reward_card: TextureRect = $RewardPopup/RewardCard
@onready var btn_close: TextureButton = $RewardPopup/BtnClose

@onready var cat_marker: Label = $CatNPC/QuestMarker
@onready var sorrel_marker: Label = $SorrelPlant/QuestMarker
@onready var balsam_marker: Label = $BalsamPlant/QuestMarker
@onready var dandelion_marker: Label = $DandelionPlant/QuestMarker

var dialogue_panel: ColorRect
var dialogue_text: Label
var dialogue_npc_name: Label
var dialogue_accept_btn: Button
var is_near_cat := false
var is_near_sorrel := false
var is_near_balsam := false
var is_near_dandelion := false

var is_typing := false
var type_timer := 0.0
var full_dialogue_text := ""
var chars_per_sec := 45.0
var dialogue_queue: Array[String] = []
var current_speaker := ""
var _pending_accept := Callable()
var pending_final_dialogue := false

func _ready() -> void:
	super._ready() # 부모 클래스의 스폰 로직 실행
	_build_ui()
	_build_dialogue_panel()
	
	if cat_npc:
		cat_npc.body_entered.connect(_on_cat_body_entered)
		cat_npc.body_exited.connect(_on_cat_body_exited)
		
	if sorrel_plant:
		sorrel_plant.body_entered.connect(_on_sorrel_body_entered)
		sorrel_plant.body_exited.connect(_on_sorrel_body_exited)
		
	if balsam_plant:
		balsam_plant.body_entered.connect(_on_balsam_body_entered)
		balsam_plant.body_exited.connect(_on_balsam_body_exited)
		
	if dandelion_plant:
		dandelion_plant.body_entered.connect(_on_dandelion_body_entered)
		dandelion_plant.body_exited.connect(_on_dandelion_body_exited)
			
	if btn_close:
		btn_close.pressed.connect(_on_reward_close_pressed)

	_update_quest_markers()

func _update_quest_markers() -> void:
	if not is_instance_valid(cat_marker): return
	
	cat_marker.hide()
	sorrel_marker.hide()
	balsam_marker.hide()
	dandelion_marker.hide()
	
	# 고양이 마커
	if GameManager.sorrel_quest_state == 0 or (GameManager.sorrel_quest_state == 3 and GameManager.balsam_quest_state == 0) or (GameManager.balsam_quest_state == 3 and GameManager.dandelion_quest_state == 0):
		cat_marker.text = "!"
		cat_marker.add_theme_color_override("font_color", Color(1.0, 0.9, 0.0))
		cat_marker.show()
	elif GameManager.sorrel_quest_state == 2 or GameManager.balsam_quest_state == 2 or GameManager.dandelion_quest_state == 2:
		cat_marker.text = "?"
		cat_marker.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		cat_marker.show()
		
	# 식물 마커
	if GameManager.sorrel_quest_state == 1:
		sorrel_marker.text = "!"
		sorrel_marker.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		sorrel_marker.show()
		
	if GameManager.balsam_quest_state == 1:
		balsam_marker.text = "!"
		balsam_marker.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		balsam_marker.show()
		
	if GameManager.dandelion_quest_state == 1:
		dandelion_marker.text = "!"
		dandelion_marker.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		dandelion_marker.show()

func _build_ui() -> void:
	var seed_ui_script = load("res://scripts/SeedCounterUI.gd")
	if seed_ui_script:
		seed_ui = seed_ui_script.new()
		add_child(seed_ui)

func _build_dialogue_panel() -> void:
	var font = load(FONT_PATH) as FontFile
	
	var dl = CanvasLayer.new()
	dl.layer = 110 # 모바일 조이스틱(90)보다 위에 오도록 설정
	add_child(dl)
	
	dialogue_panel = ColorRect.new()
	dialogue_panel.color = Color(0.1, 0.1, 0.1, 0.9)
	dialogue_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_panel.offset_top = -260 # 창 높이 증가
	dialogue_panel.offset_left = 40
	dialogue_panel.offset_right = -40
	dialogue_panel.offset_bottom = -20
	dialogue_panel.hide()
	dl.add_child(dialogue_panel)
	
	dialogue_npc_name = Label.new()
	dialogue_npc_name.position = Vector2(24, 16)
	if font:
		dialogue_npc_name.add_theme_font_override("font", font)
	dialogue_npc_name.add_theme_font_size_override("font_size", 36)
	dialogue_npc_name.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	dialogue_panel.add_child(dialogue_npc_name)
	
	dialogue_text = Label.new()
	# 텍스트가 패널 안에서 꽉 차도록 마진 적용
	dialogue_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogue_text.offset_left = 24
	dialogue_text.offset_top = 64
	dialogue_text.offset_right = -180 # 버튼 공간 확보
	dialogue_text.offset_bottom = -24
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font:
		dialogue_text.add_theme_font_override("font", font)
	dialogue_text.add_theme_font_size_override("font_size", 32)
	dialogue_panel.add_child(dialogue_text)
	
	dialogue_accept_btn = Button.new()
	dialogue_accept_btn.text = "계속"
	# 우측 하단에 딱 맞게 고정 (앵커 사용)
	dialogue_accept_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	dialogue_accept_btn.offset_left = -260
	dialogue_accept_btn.offset_top = -70
	dialogue_accept_btn.offset_right = -20
	dialogue_accept_btn.offset_bottom = -20
	
	if font:
		dialogue_accept_btn.add_theme_font_override("font", font)
	dialogue_accept_btn.add_theme_font_size_override("font_size", 26)
	dialogue_accept_btn.pressed.connect(_accept_dialogue)
	
	var sc := Shortcut.new()
	var ev_space := InputEventKey.new()
	ev_space.physical_keycode = KEY_SPACE
	ev_space.pressed = true
	sc.events.append(ev_space)
	dialogue_accept_btn.shortcut = sc
	
	dialogue_panel.add_child(dialogue_accept_btn)

func _on_cat_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_cat = true
		hint_label.show()

func _on_cat_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_cat = false
		hint_label.hide()

func _on_sorrel_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_sorrel = true
		sorrel_hint.show()

func _on_sorrel_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_sorrel = false
		sorrel_hint.hide()

func _on_balsam_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_balsam = true
		balsam_hint.show()

func _on_balsam_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_balsam = false
		balsam_hint.hide()

func _on_dandelion_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_dandelion = true
		dandelion_hint.show()

func _on_dandelion_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_dandelion = false
		dandelion_hint.hide()

func _process(delta: float) -> void:
	if sorrel_plant: sorrel_plant.visible = (GameManager.sorrel_quest_state >= 1)
	if balsam_plant: balsam_plant.visible = (GameManager.balsam_quest_state >= 1)
	if dandelion_plant: dandelion_plant.visible = (GameManager.dandelion_quest_state >= 1)
	
	if cat_marker and cat_marker.visible:
		cat_marker.position.y = -120 + sin(Time.get_ticks_msec() / 150.0) * 8.0
	if sorrel_marker and sorrel_marker.visible:
		sorrel_marker.position.y = -110 + sin(Time.get_ticks_msec() / 150.0) * 8.0
	if balsam_marker and balsam_marker.visible:
		balsam_marker.position.y = -110 + sin(Time.get_ticks_msec() / 150.0) * 8.0
	if dandelion_marker and dandelion_marker.visible:
		dandelion_marker.position.y = -110 + sin(Time.get_ticks_msec() / 150.0) * 8.0
		
	if is_typing:
		type_timer += delta
		var chars_to_show = int(type_timer * chars_per_sec)
		if chars_to_show >= full_dialogue_text.length():
			dialogue_text.text = full_dialogue_text
			is_typing = false
			dialogue_accept_btn.show()
		else:
			dialogue_text.text = full_dialogue_text.substr(0, chars_to_show)

func _unhandled_input(event: InputEvent) -> void:
	if reward_popup.visible:
		get_viewport().set_input_as_handled()
		return
		
	if dialogue_panel.visible:
		if (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE) or \
		   (event is InputEventScreenTouch and event.pressed):
			if is_typing:
				dialogue_text.text = full_dialogue_text
				is_typing = false
				dialogue_accept_btn.show()
			else:
				if dialogue_accept_btn.visible:
					dialogue_accept_btn.emit_signal("pressed")
			if get_viewport(): get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE):
		if is_near_cat:
			_interact_cat()
			if get_viewport(): get_viewport().set_input_as_handled()
		elif is_near_sorrel:
			_interact_sorrel()
			if get_viewport(): get_viewport().set_input_as_handled()
		elif is_near_balsam:
			_interact_balsam()
			if get_viewport(): get_viewport().set_input_as_handled()
		elif is_near_dandelion:
			_interact_dandelion()
			if get_viewport(): get_viewport().set_input_as_handled()

func _interact_sorrel() -> void:
	if GameManager.sorrel_quest_state == 0:
		_show_dialogue("시스템", ["지금은 이 풀을 건드릴 필요가 없을 것 같다.\n먼저 고양이와 대화하자."], func(): pass)
	elif GameManager.sorrel_quest_state == 1:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			GameManager.return_position = players[0].global_position
			GameManager.use_return_position = true
		get_tree().change_scene_to_file("res://scenes/MinigameSorrel.tscn")
	elif GameManager.sorrel_quest_state >= 2:
		_show_dialogue("시스템", ["이미 씨앗을 모두 모았다!"], func(): pass)

func _interact_balsam() -> void:
	if GameManager.balsam_quest_state == 0:
		_show_dialogue("시스템", ["지금은 이 식물을 건드릴 필요가 없을 것 같다.\n먼저 고양이와 대화하자."], func(): pass)
	elif GameManager.balsam_quest_state == 1:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			GameManager.return_position = players[0].global_position
			GameManager.use_return_position = true
		get_tree().change_scene_to_file("res://scenes/MinigameBalsam.tscn")
	elif GameManager.balsam_quest_state >= 2:
		_show_dialogue("시스템", ["이미 봉선화 씨앗을 모두 모았다!"], func(): pass)

func _interact_dandelion() -> void:
	if GameManager.dandelion_quest_state == 0:
		_show_dialogue("시스템", ["지금은 이 식물을 건드릴 필요가 없을 것 같다.\n먼저 고양이와 대화하자."], func(): pass)
	elif GameManager.dandelion_quest_state == 1:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			GameManager.return_position = players[0].global_position
			GameManager.use_return_position = true
		get_tree().change_scene_to_file("res://scenes/MinigameDandelion.tscn")
	elif GameManager.dandelion_quest_state >= 2:
		_show_dialogue("시스템", ["이미 민들레 씨앗을 모두 모았다!"], func(): pass)

func _interact_cat() -> void:
	if GameManager.sorrel_quest_state == 0:
		_show_dialogue("고양이", [
			"냐앙~ 넌 누구냥? 꽃밭에 놀러왔구나.\n여긴 신기한 씨앗들이 아주 많아.",
			"내가 씨앗 모으는 걸 도와주겠다 냥!",
			"저기 좌측 화단에 하트 모양 잎을 가진 풀이 보이냥? '괭이밥'이야!\n다 익은 꼬투리는 살짝만 건드려도 폭죽처럼 터져버리니까 조심해서 따야 해 냥!",
			"빨리 가서 괭이밥 꼬투리를 터뜨려봐라냥!"
		], func():
			GameManager.sorrel_quest_state = 1
			_update_quest_markers()
		)
	elif GameManager.sorrel_quest_state == 1:
		_show_dialogue("고양이", ["왼쪽 화단에 있는 괭이밥을 빨리 찾아봐 냥!"], func(): pass)
	elif GameManager.sorrel_quest_state == 2:
		_show_dialogue("고양이", [
			"오오! 괭이밥 씨앗을 훌륭하게 모아왔구나 냥!",
			"정말 수고했다냥! 이건 내 선물이다 냥!"
		], func():
			GameManager.sorrel_quest_state = 3
			GameManager.flowerbed_sorrel_cleared = true
			GameManager.collected_seeds += 1
			reward_card.texture = load("res://assets/game/bab/bobcard.png")
			if has_node("/root/AudioManager"):
				AudioManager.play_reward_sfx()
			reward_popup.show()
			_update_quest_markers()
			
			if seed_ui and seed_ui.has_method("update_counter"):
				seed_ui.update_counter()
		)
	elif GameManager.sorrel_quest_state == 3 and GameManager.balsam_quest_state == 0:
		_show_dialogue("고양이", [
			"이제 봉선화 씨앗을 찾으러 가볼까 냥?",
			"오른쪽 화단에 있는 봉선화를 찾아봐 냥!\n봉선화 꼬투리는 톡 터뜨리면 씨앗이 멀리 날아간다냥!",
			"새총을 쏘듯 당겨서 바구니에 골인시켜봐라냥!"
		], func():
			GameManager.balsam_quest_state = 1
			_update_quest_markers()
		)
	elif GameManager.balsam_quest_state == 1:
		_show_dialogue("고양이", ["오른쪽 화단의 봉선화를 얼른 찾아봐 냥!"], func(): pass)
	elif GameManager.balsam_quest_state == 2:
		_show_dialogue("고양이", [
			"멋지게 바구니에 골인시켰구나 냥!",
			"대단하다냥! 이건 내 선물이다 냥!"
		], func():
			GameManager.balsam_quest_state = 3
			GameManager.flowerbed_balsam_cleared = true
			GameManager.collected_seeds += 1
			reward_card.texture = load("res://assets/game/bong/bong_card.png")
			if has_node("/root/AudioManager"):
				AudioManager.play_reward_sfx()
			reward_popup.show()
			_update_quest_markers()
			
			if seed_ui and seed_ui.has_method("update_counter"):
				seed_ui.update_counter()
		)
	elif GameManager.balsam_quest_state == 3 and GameManager.dandelion_quest_state == 0:
		_show_dialogue("고양이", [
			"마지막으로 남은 건 민들레 씨앗이다 냥!",
			"아래쪽에 있는 민들레를 찾아봐 냥!\n바람을 타고 날아가는 씨앗을 잘 조종해서 장애물을 피해야 한다냥!"
		], func():
			GameManager.dandelion_quest_state = 1
			_update_quest_markers()
		)
	elif GameManager.dandelion_quest_state == 1:
		_show_dialogue("고양이", ["아래쪽 화단의 민들레를 얼른 찾아봐 냥!"], func(): pass)
	elif GameManager.dandelion_quest_state == 2:
		_show_dialogue("고양이", [
			"장애물을 멋지게 피해서 안전하게 착지했구나 냥!",
			"모든 씨앗을 다 모았다냥! 정말 고맙다 냥! 이건 내 마지막 선물이다 냥!"
		], func():
			GameManager.dandelion_quest_state = 3
			GameManager.flowerbed_dandelion_cleared = true
			GameManager.collected_seeds += 1
			reward_card.texture = load("res://assets/game/min/card_min.png")
			if has_node("/root/AudioManager"):
				AudioManager.play_reward_sfx()
			reward_popup.show()
			pending_final_dialogue = true
			_update_quest_markers()
			
			if seed_ui and seed_ui.has_method("update_counter"):
				seed_ui.update_counter()
		)
	elif GameManager.dandelion_quest_state == 3:
		_show_dialogue("고양이", [
			"모든 씨앗을 다 모았다냥! 너는 최고의 씨앗 수집가다 냥!",
			"수집한 씨앗들은 메인 광장의 '씨앗 보관함'에서 확인할 수 있다냥!",
			"씨앗 보관함으로 돌아가서 도감을 꽉 채워봐라냥!"
		], func(): pass)

func _show_dialogue(speaker: String, texts: Array, on_accept: Callable) -> void:
	if texts.is_empty(): return
	
	dialogue_queue.assign(texts)
	current_speaker = speaker
	_pending_accept = on_accept
	
	_show_next_dialogue()

func _show_next_dialogue() -> void:
	if dialogue_queue.is_empty():
		dialogue_panel.hide()
		is_typing = false
		if _pending_accept.is_valid():
			_pending_accept.call()
		_pending_accept = Callable()
		return
		
	var next_text = dialogue_queue.pop_front()
	dialogue_panel.show()
	dialogue_npc_name.text = current_speaker
	full_dialogue_text = next_text
	dialogue_text.text = ""
	is_typing = true
	type_timer = 0.0
	dialogue_accept_btn.hide()

func _accept_dialogue() -> void:
	_show_next_dialogue()

func _on_reward_close_pressed() -> void:
	reward_popup.hide()
	
	if pending_final_dialogue:
		pending_final_dialogue = false
		_show_dialogue("고양이", [
			"모든 씨앗을 다 모았다냥! 너는 최고의 씨앗 수집가다 냥!",
			"수집한 씨앗들은 메인 광장의 '씨앗 보관함'에서 확인할 수 있다냥!",
			"씨앗 보관함으로 돌아가서 도감을 꽉 채워봐라냥!"
		], func(): pass)
