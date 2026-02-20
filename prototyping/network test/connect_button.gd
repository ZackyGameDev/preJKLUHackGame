extends GUIButton


func _on_button_activated(data: Variant) -> void:
	Network.connect_to_server($URL.text)
