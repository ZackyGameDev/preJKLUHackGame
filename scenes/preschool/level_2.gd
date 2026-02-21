extends Node

@onready var white = $White
@onready var end_node = $end

func _ready():
	# Ensure both start fully transparent
	white.modulate.a = 0.0
	white.visible = true
	end_node.modulate.a = 0.0
	end_node.visible = true

func start_fade_sequence():
	var tween = create_tween()
	
	# Fade in "White" over 4 seconds
	tween.tween_property(white, "modulate:a", 1.0, 3.0)
	await tween.finished
	# After that finishes, fade in "end" over 5 seconds
	var tween2 = create_tween()
	tween2.tween_property(end_node, "modulate:a", 1.0, 5.0)
