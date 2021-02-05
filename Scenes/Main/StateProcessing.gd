extends Node

var world_state
var player_username_dupe


func _physics_process(delta):
	if not get_parent().player_state_collection.empty():
		world_state = get_parent().player_state_collection.duplicate(true)
		player_username_dupe = get_node("/root/GameServer/PlayerVerification").player_usernames
		for player in world_state.keys():
#			print(player_username_dupe.get(player))
			world_state[player]["U"] = player_username_dupe[player]
			world_state[player].erase("T")
			print(world_state)
		world_state["T"] = OS.get_system_time_msecs()
		#Verification
		#Anti-Cheat
		#Cuts (chunking / maps)
		#Physics Checks
		#Anything else
		get_parent().SendWorldState(world_state)
