extends CanvasLayer

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

func _ready() -> void:
	hide()
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)

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

func _update_slot(slot: TextureRect, cleared: bool, path: String) -> void:
	if slot:
		slot.texture = load(path)
		if cleared:
			slot.modulate = Color(1, 1, 1, 1)
		else:
			slot.modulate = Color(1, 1, 1, 0)

func _on_close_pressed() -> void:
	hide()
