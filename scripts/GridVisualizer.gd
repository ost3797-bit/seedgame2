@tool
extends ColorRect

@export var grid_size: int = 5 :
	set(val):
		grid_size = val
		queue_redraw()

func _ready() -> void:
	# 마우스 클릭을 차단하지 않도록 설정 (매우 중요)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if not Engine.is_editor_hint(): return
	var c_size = size.x / float(grid_size)
	var line_color = Color(1.0, 1.0, 1.0, 0.6)
	
	for i in range(1, grid_size):
		# 수직선
		draw_line(Vector2(i * c_size, 0), Vector2(i * c_size, size.y), line_color, 2.0)
		# 수평선
		draw_line(Vector2(0, i * c_size), Vector2(size.x, i * c_size), line_color, 2.0)
