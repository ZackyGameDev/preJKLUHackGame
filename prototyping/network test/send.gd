extends GUIButton


func _on_button_activated(data: Variant) -> void:
	Network.send("chat", { "text": $message.text })
	
	$message.text = ""
