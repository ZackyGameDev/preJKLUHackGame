extends GUIButton


func _on_button_activated(data: Variant) -> void:
	Network.disconnect_from_server()
