class_name PauseMenu
extends PanelContainer

signal cancel_requested

@onready var ResumeButton: Button = %ResumeButton
@onready var SettingsButton: Button = %SettingsButton
@onready var QuitButton: Button = %QuitButton

func SetCompactMode(_enabled: bool) -> void:
	custom_minimum_size = Vector2(300, 240)

func _unhandled_input(event: InputEvent) -> void:
	if not get_tree().paused:
		return
	if event.is_action_pressed("ui_cancel"):
		cancel_requested.emit()
		get_viewport().set_input_as_handled()
