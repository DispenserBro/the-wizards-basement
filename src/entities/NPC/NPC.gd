class_name NPC
extends Area2D

@export var player: CharacterBody2D

var _enter: Node2D
var _conversation: Control
var _note: Control

func _ready() -> void:
	_enter = get_node_or_null("enter")
	_conversation = get_node_or_null("CanvasLayer/conversation")
	_note = get_node_or_null("CanvasLayer/note")

func _process(_delta: float) -> void:
	if _note != null:
		_note.hide()
	if _enter != null:
		_enter.hide()

	if player == null or not is_instance_valid(player):
		return

	for body in get_overlapping_bodies():
		if body == player:
			UpdateState()

			var isTalking = player.get("is_talking")
			if not isTalking:
				if _note != null:
					_note.show()
				if _enter != null:
					_enter.show()

			if Input.is_action_just_pressed("enteract"):
				if _conversation != null:
					_conversation.show()

func UpdateState() -> void:
	if player != null and is_instance_valid(player) and _conversation != null:
		if _conversation.visible:
			player.set("is_talking", true)
		else:
			player.set("is_talking", false)
