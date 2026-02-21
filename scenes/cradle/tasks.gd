extends Panel

var tasks = [ 
	{
		"task_id": "ask_for_milk",
		"user_info": "Ask your mother for milk",
		"expected_intent": "Asking for your milk bottle to drink milk",
		"keywords": ["milk", "feeder bottle", "milk bottle"],
	},
	{
		"task_id" : "heat_complain",
		"user_info": "Tell your mother its too hot",
		"expected_intent": "Telling your parent that the environment feels too hot",
		"keywords": ["hot", "heat", "too hot"],
	},
	{
		"task_id" : "teddy_request",
		"user_info": "Ask for your teddy bear",
		"expected_intent": "Ask your parent to give you your teddy bear.",
		"keywords": ["teddy", "toy", "bear", "teddy bear"],
	},
	{
		"task_id" : "call_mummy",
		"user_info": "Call for your mother",
		"expected_intent": "Call out to your mother",
		"keywords": ["mummy", "momma", "mom", "mother", "mama"],
	},
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
	Network.response_ready.connect(_tasks_processed)

func _physics_process(delta: float) -> void:
	$list.text = ""
	for i in range(len(tasks)):
		if done[i]:
			$list.text = $list.text + "[s][*] " + tasks[i]["user_info"] + "[/s]\n"
		else:
			$list.text = $list.text + "[ ] " + tasks[i]["user_info"] + "\n"
	
	if $list.text[-1] == '\n':
		$list.text = $list.text.substr(0, len($list.text)-1)


func _on_voice_speech_received(text: Variant) -> void:
	Network.request_task_processing(text, tasks, "scene_1")

func _tasks_processed() -> void:
	pass


func _on_mother_done_speaking(res: Variant) -> void:
	var grades = res["evaluation"]["tasks"]
	for g in grades:

		if typeof(g) != TYPE_DICTIONARY:
			continue

		var id = g.get("task_id", "")
		var completed = g.get("completed", false)

		for i in range(tasks.size()):
			if tasks[i]["task_id"] == id:
				if completed:
					done[i] = true
				break
	
	var t = true
	for i in done:
		if i == false: 
			t = false
	if t == true:
		get_parent().do_it()
