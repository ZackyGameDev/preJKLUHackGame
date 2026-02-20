extends Node

signal response_ready

var http: HTTPRequest
var response_queue: Array = []
var busy := false


func _ready():
	http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_done)


# =========================================================
# GENERIC JSON POST
# =========================================================
func post_json(endpoint: String, payload: Dictionary):

	if busy:
		print("HTTP busy — request ignored")
		return

	var json = JSON.stringify(payload)

	var headers = [
		"Content-Type: application/json"
	]

	var err = http.request(
		endpoint,
		headers,
		HTTPClient.METHOD_POST,
		json
	)

	if err != OK:
		print("Failed to start HTTP request")
	else:
		busy = true



# =========================================================
# SPECIFIC API — DIALOGUE REQUEST
# =========================================================
func request_dialogue(outline: String, language: String = "Punjabi"):

	var body = {
		"outline": outline,
		"language": language
	}

	post_json("http://localhost:3000/api/generate", body)



# =========================================================
# RESPONSE HANDLER
# =========================================================
func _on_request_done(result, response_code, headers, body):

	busy = false

	if response_code != 200:
		print("Server error:", response_code)
		return

	var text = body.get_string_from_utf8()

	var json = JSON.parse_string(text)

	if typeof(json) != TYPE_DICTIONARY:
		print("Invalid JSON")
		return

	response_queue.push_back(json)

	emit_signal("response_ready")



# =========================================================
# QUEUE ACCESS
# =========================================================
func has_message() -> bool:
	return response_queue.size() > 0


func pop_message() -> String:

	if response_queue.is_empty():
		return ""

	var full = response_queue.pop_front()

	if full.has("sentence"):
		return full["sentence"]
		response_queue.clear()

	return ""
