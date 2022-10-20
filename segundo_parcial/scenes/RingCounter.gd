extends Label

func _process(delta):
	if text == "Rings: 0":
		add_color_override("font_color", Color(200,0,0))
	else:
		add_color_override("font_color", Color(200,200,0))
