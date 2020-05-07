extends Node2D

func _ready() -> void:
	var as_server := true
	Network.init_local_peer(as_server)
