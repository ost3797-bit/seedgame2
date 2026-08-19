extends SceneTree

func _init():
	var paths = [
		"res://assets/game/bean/tile1-1.png",
		"res://assets/game/bean/tile2-4.png",
		"res://assets/game/bean/tile3-2.png"
	]
	
	for path in paths:
		var img = Image.load_from_file(ProjectSettings.globalize_path(path))
		if img == null:
			print("Failed to load: ", path)
			continue
			
		var w = img.get_width()
		var h = img.get_height()
		
		var edges = {"Up": false, "Down": false, "Left": false, "Right": false}
		
		# We check the middle 1/3rd of each edge to see if there are opaque pixels
		var mid_x_start = w / 3
		var mid_x_end = w * 2 / 3
		var mid_y_start = h / 3
		var mid_y_end = h * 2 / 3
		
		# Up
		for x in range(mid_x_start, mid_x_end):
			if img.get_pixel(x, 0).a > 0.5: edges["Up"] = true
		
		# Down
		for x in range(mid_x_start, mid_x_end):
			if img.get_pixel(x, h - 1).a > 0.5: edges["Down"] = true
			
		# Left
		for y in range(mid_y_start, mid_y_end):
			if img.get_pixel(0, y).a > 0.5: edges["Left"] = true
			
		# Right
		for y in range(mid_y_start, mid_y_end):
			if img.get_pixel(w - 1, y).a > 0.5: edges["Right"] = true
			
		print("Tile: ", path.get_file(), " -> ", edges)
		
	quit()
