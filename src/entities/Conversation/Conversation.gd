class_name Conversation
extends Control

@export_multiline var word: Array[String] = []
@export var _name: Array[String] = []
@export var _icon: Array[Texture2D] = []

var _wordLabel: Label
var _nameLabel: Label
var _iconRect: TextureRect

var CurrentStep: int = 0

func _ready() -> void:
	_wordLabel = get_node_or_null("board/word")
	_nameLabel = get_node_or_null("board/name")
	_iconRect = get_node_or_null("board/frame/TextureRect")
	hide()

func _process(_delta: float) -> void:
	UpdateConversationQueue()

	if Input.is_action_just_pressed("click"):
		CurrentStep += 1

func UpdateConversationQueue() -> void:
	if word == null or _name == null or _icon == null:
		return

	# Text
	if CurrentStep < word.size():
		if _wordLabel != null:
			_wordLabel.text = word[CurrentStep]
	else:
		CurrentStep = 0
		hide()
		return

	# Icons
	if CurrentStep < _icon.size():
		if _iconRect != null:
			_iconRect.texture = _icon[CurrentStep]
	else:
		CurrentStep = 0
		hide()
		return

	# Names
	if CurrentStep < _name.size():
		if _nameLabel != null:
			_nameLabel.text = _name[CurrentStep]
	else:
		CurrentStep = 0
		hide()
