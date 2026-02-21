extends Panel

var tasks = [ 
	{
		"task_id": "make_friend",
		"user_info": "Make a friend",
		"expected_intent": "Tell someone that you want to be their friend",
		"keywords": ["friendship", "want to be friends", "make friends"],
	},
]

var done = [
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
	Network.request_task_processing(text, tasks, "scene_2")

func _tasks_processed() -> void:
	var res = null
	for data in Network.response_queue:
		if data.has("npc_response"): # that means its the relevant one
			res = data
			Network.response_queue.clear()
			break
	if res == null:
		return
	else:
		dia_prep(res)

func dia_prep(res):
	if res["evaluation"]["tasks"][0]["completed"]:
		done[0] = true
		get_parent().start_fade_sequence()

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
