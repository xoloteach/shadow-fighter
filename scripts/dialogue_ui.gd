class_name DialogueUI
extends Control

signal dialogue_finished()

@onready var label_speaker: Label = $Panel/VBox/SpeakerLabel
@onready var label_text: Label = $Panel/VBox/TextLabel
@onready var btn_next: Button = $Panel/VBox/BtnNext

var current_lines: Array = []
var line_idx: int = 0

func _ready() -> void:
	btn_next.pressed.connect(_advance_dialogue)
	visible = false

func play_sequence(lines: Array) -> void:
	if lines.is_empty():
		dialogue_finished.emit()
		return
	current_lines = lines
	line_idx = 0
	visible = true
	_show_current_line()

func _show_current_line() -> void:
	if line_idx >= current_lines.size():
		visible = false
		dialogue_finished.emit()
		return
	
	var line_data: Dictionary = current_lines[line_idx]
	label_speaker.text = line_data.get("speaker", "WARRIOR").to_upper()
	label_text.text = line_data.get("text", "")

func _advance_dialogue() -> void:
	line_idx += 1
	_show_current_line()
