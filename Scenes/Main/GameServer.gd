extends Node

var network = NetworkedMultiplayerENet.new()
var port = 1909
var max_players = 100

var expected_tokens = {}
var player_state_collection = {}

onready var player_verification_process = get_node("PlayerVerification")


func _ready():
	StartServer()
	
	
func StartServer():
	network.create_server(port, max_players)
	get_tree().set_network_peer(network)
	print("Server started on port: " + str(port))
	
	network.connect("peer_connected", self, "_Peer_Connected")
	network.connect("peer_disconnected", self, "_Peer_Disconnected")


func _Peer_Connected(player_id):
	print("User " + str(player_id) + " Connected")
	player_verification_process.start(player_id)


func _Peer_Disconnected(player_id):
	print("User " + str(player_id) + " Disconnected")
	if has_node(str(player_id)):
		get_node(str(player_id)).queue_free()
		player_verification_process.player_usernames.erase(player_id)
		player_state_collection.erase(player_id)
		rpc_id(0, "DespawnPlayer", player_id)


func _on_TokenExpiration_timeout():
	var current_time = OS.get_unix_time()
	var token_time
	if expected_tokens == {}:
		pass
	else:
		for key in expected_tokens.keys():
			token_time = int(expected_tokens[key].right(64))
			if current_time - token_time >= 30:
				expected_tokens.erase(key)
	print("Expected Tokens:")
	print(expected_tokens)
	print(player_verification_process.player_usernames)


remote func FetchServerTime(client_time):
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id, "ReturnServerTime", OS.get_system_time_msecs(), client_time)
	
remote func DetermineLatency(client_time):
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id, "ReturnLatency", client_time)

func FetchToken(player_id):
	rpc_id(player_id, "FetchToken")
	
remote func ReturnToken(token):
	var player_id = get_tree().get_rpc_sender_id()
	player_verification_process.Verify(player_id, token)
	
func ReturnTokenVerificationResults(player_id, result):
	rpc_id(player_id, "ReturnTokenVerificationResults", result)
	if result == true:
		rpc_id(0, "SpawnNewPlayer", player_id, Vector2(200, 100), player_verification_process.player_usernames[player_id])


remote func ReceivePlayerState(player_state):
	var player_id = get_tree().get_rpc_sender_id()
	if player_state_collection.has(player_id):
		if player_state_collection[player_id]["T"] < player_state["T"]:
			player_state_collection[player_id] = player_state
	else:
		player_state_collection[player_id] = player_state
		
func SendWorldState(world_state):
	rpc_unreliable_id(0, "ReceiveWorldState", world_state)

remote func ReceiveChat(chat):
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(0, "ReceiveChatOthers", player_id, chat)
