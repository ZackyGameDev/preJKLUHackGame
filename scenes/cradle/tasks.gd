extends Panel

var tasks = [
	"Ask for milk.", 
	"Tell your mom that it feels hot.",
	"Ask for a teddy bear",
	"Call for your mummy",
]

var done = [
	false,
	false,
	false,
	false,
]

func _ready() -> void:
	$list.bbcode_enabled = true
	$list.text = "\n".join(tasks)

func _physics_process(delta: float) -> void:
	$list.text = ""
	for i in range(len(tasks)):
		if done[i]:
			$list.text = $list.text + "[s][*] " + tasks[i] + "[/s]\n"
		else:
			$list.text = $list.text + "[ ] " + tasks[i] + "\n"
	
	if $list.text[-1] == '\n':
		$list.text = $list.text.substr(0, len($list.text)-1)
