extends RichTextLabel

func _physics_process(delta: float) -> void:
	text = ""
	for log in Network.log:
		text += "\n" + log
	
	var bar = get_v_scroll_bar()
	bar.value = bar.max_value # jump to bottom
