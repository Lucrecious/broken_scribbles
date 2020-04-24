extends Node2D


func _ready():
	Network.create_room('room_name', '<server>')
