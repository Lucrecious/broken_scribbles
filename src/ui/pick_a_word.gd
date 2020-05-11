extends Control

signal word_picked(index)

onready var _wordlist := $WordList

func init(words : Array) -> void:
	for word in words:
		_wordlist.add_item(word)

func clear() -> void:
	_wordlist.clear()

func _on_WordList_item_selected(index: int) -> void:
	emit_signal('word_picked', index)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wordlist.mouse_filter = Control.MOUSE_FILTER_IGNORE
