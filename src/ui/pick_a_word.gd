extends Control

signal word_picked(index)

var _words := []
var _selected_index := -1

onready var _wordlist := $VBoxContainer/WordList
onready var _pick_button := $VBoxContainer/PickButton

func init(words : Array) -> void:
	_words = words

func _item_selected(index : int) -> void:
	_selected_index = index
	_pick_button.disabled = false

func _ready() -> void:
	_wordlist.connect('item_selected', self, '_item_selected')
	_pick_button.disabled = true 
	
	init(_words)
	
	for word in _words:
		_wordlist.add_item(word)

func _on_PickButton_pressed() -> void:
	if _selected_index < 0: return
	emit_signal('word_picked', _selected_index)
