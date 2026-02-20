extends GUIButton

@export var npc: NodePath
@export var punjabi_word: String = "doodh"
@export var line: String = "doodh kyu rakhaa hai zameen pe???"
@export var outline: String = "say something about how the weather is hot today. emphasis on hot"


func _ready() -> void: 
	super._ready()
	squish_amount = 1
	

func _on_button_activated(data: Variant) -> void:
	var n = get_node(npc)
	n.look_at_object(self, line)
	Network.request_dialogue(outline)
