extends CanvasLayer

const FONT_PATH := "res://fonts/Cafe24Ssurround-v2.0.ttf"

@onready var close_btn = $Control/CloseButton
@onready var slot1 = $Control/Slots/Slot1
@onready var slot2 = $Control/Slots/Slot2
@onready var slot3 = $Control/Slots/Slot3
@onready var slot4 = $Control/Slots/Slot4
@onready var slot5 = $Control/Slots/Slot5
@onready var slot6 = $Control/Slots/Slot6
@onready var slot7 = $Control/Slots/Slot7
@onready var slot8 = $Control/Slots/Slot8
@onready var slot9 = $Control/Slots/Slot9
@onready var slot10 = $Control/Slots/Slot10

var submit_btn: Button
var cert_layer: CanvasLayer

func _ready() -> void:
	hide()
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
		
	# Create Submit Button
	submit_btn = Button.new()
	submit_btn.text = "제출"
	var font = load(FONT_PATH) as FontFile
	if font:
		submit_btn.add_theme_font_override("font", font)
	submit_btn.add_theme_font_size_override("font_size", 32)
	submit_btn.custom_minimum_size = Vector2(200, 60)
	submit_btn.position = Vector2(1720, 950) # Bottom right corner of the SeedHouseUI Control
	submit_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	submit_btn.offset_left = -220
	submit_btn.offset_top = -80
	submit_btn.offset_right = -20
	submit_btn.offset_bottom = -20
	submit_btn.hide()
	submit_btn.pressed.connect(_on_submit_pressed)
	$Control.add_child(submit_btn)
	
	_build_cert_ui()

func _build_cert_ui() -> void:
	cert_layer = CanvasLayer.new()
	cert_layer.layer = 150 # Make sure it's above everything
	cert_layer.hide()
	add_child(cert_layer)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cert_layer.add_child(bg)
	
	var cert_tex = load("res://assets/Certificate.png")
	var cert_rect = TextureRect.new()
	cert_rect.texture = cert_tex
	cert_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cert_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cert_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Add some margins
	cert_rect.offset_left = 100
	cert_rect.offset_right = -100
	cert_rect.offset_top = 50
	cert_rect.offset_bottom = -50
	cert_layer.add_child(cert_rect)
	
	var name_input = LineEdit.new()
	var font = load(FONT_PATH) as FontFile
	if font:
		name_input.add_theme_font_override("font", font)
	name_input.add_theme_font_size_override("font_size", 48)
	name_input.placeholder_text = "이름을 입력하세요"
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_input.add_theme_color_override("font_color", Color(0, 0, 0))
	name_input.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	name_input.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# Positioning the signature line (approximate, user might need to adjust)
	name_input.custom_minimum_size = Vector2(400, 60)
	name_input.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	name_input.position = Vector2(300, 750) # Bottom right area
	cert_layer.add_child(name_input)
	
	var close_cert = Button.new()
	close_cert.text = "닫기"
	if font:
		close_cert.add_theme_font_override("font", font)
	close_cert.add_theme_font_size_override("font_size", 32)
	close_cert.custom_minimum_size = Vector2(150, 60)
	close_cert.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close_cert.offset_left = -170
	close_cert.offset_top = 20
	close_cert.offset_right = -20
	close_cert.offset_bottom = 80
	close_cert.pressed.connect(_on_cert_close_pressed)
	cert_layer.add_child(close_cert)

func update_cards() -> void:
	if not GameManager: return
	
	_update_slot(slot1, GameManager.flowerbed_sorrel_cleared, "res://assets/game/bab/bobcard.png")
	_update_slot(slot2, GameManager.flowerbed_balsam_cleared, "res://assets/game/bong/bong_card.png")
	_update_slot(slot3, GameManager.flowerbed_dandelion_cleared, "res://assets/game/min/card_min.png")
	_update_slot(slot4, GameManager.forest_maple_cleared, "res://assets/game/maple/maplecard.png")
	_update_slot(slot5, GameManager.forest_camellia_cleared, "res://assets/game/Camellia/camelliacard.png")
	_update_slot(slot6, GameManager.pond_hyacinth_cleared, "res://assets/game/water/water hyacinthcard.png")
	_update_slot(slot7, GameManager.pond_cattail_cleared, "res://assets/game/flag/flagcard.png")
	_update_slot(slot8, GameManager.farm_bean_cleared, "res://assets/game/bean/beancard.png")
	_update_slot(slot9, GameManager.farm_corn_cleared, "res://assets/game/corn/corncard.png")
	_update_slot(slot10, GameManager.farm_tomato_cleared, "res://assets/game/tomato/tomatocard.png")
	
	if GameManager.collected_seeds >= 10:
		submit_btn.show()
	else:
		submit_btn.hide()

func _update_slot(slot: TextureRect, cleared: bool, path: String) -> void:
	if slot:
		slot.texture = load(path)
		if cleared:
			slot.modulate = Color(1, 1, 1, 1)
		else:
			slot.modulate = Color(1, 1, 1, 0)

func _on_submit_pressed() -> void:
	cert_layer.show()

func _on_cert_close_pressed() -> void:
	cert_layer.hide()

func _on_close_pressed() -> void:
	hide()
