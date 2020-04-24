extends Node2D


func _ready():
	print('Creating Server...')
	if Network.create_room('server'): return
		
	print('Server exists already...')
	print('Creating Client...')
	Network.enter_lobby('luca')

var stop := false
func _input(_event) -> void:
	if stop: return
	if not Input.is_action_just_pressed('ui_accept'): return
	stop = true

	var players := Network.get_players()
	var game := preload("res://src/game/game.tscn").instance()
	game.init(players)

	call_deferred('add_child', game)


